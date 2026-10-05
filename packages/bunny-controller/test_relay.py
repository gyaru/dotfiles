"""Exercise the real relay command against disposable loopback RTMP receivers.

Set BUNNY_TEST_FFMPEG to enable these integration tests (also run by Nix).
No production service, source, credentials, or stream path is used.
"""

import importlib.util
import json
import os
from pathlib import Path
import queue
import socket
import subprocess
import tempfile
import threading
import time
import unittest
from unittest.mock import patch


@unittest.skipUnless(os.environ.get("BUNNY_TEST_FFMPEG"), "BUNNY_TEST_FFMPEG is not set")
class RelayRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        directory = Path(self.directory.name)
        (directory / "control-secret").write_text("integration-test")
        self.ffmpeg = os.environ["BUNNY_TEST_FFMPEG"]
        with patch.dict(os.environ, {
            "CREDENTIALS_DIRECTORY": str(directory),
            "BUNNY_FFMPEG": self.ffmpeg,
            "BUNNY_FFPROBE": self.ffmpeg,
            "BUNNY_STREAMLINK": "unused",
            "BUNNY_OUTPUT_PASSWORD_CREDENTIAL": "0",
            "BUNNY_VIDEO_ENCODER": "libx264",
        }):
            spec = importlib.util.find_spec("controller")
            self.controller = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(self.controller)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        self.controller.OUTPUT_URL = f"rtmp://127.0.0.1:{port}/recovery-test/stream"
        self.source = str(directory / "source.mkv")
        subprocess.run([
            self.ffmpeg, "-hide_banner", "-loglevel", "error",
            "-f", "lavfi", "-i", "testsrc2=size=160x90:rate=10",
            "-f", "lavfi", "-i", "sine=frequency=440:sample_rate=48000",
            "-t", "18", "-c:v", "libx264", "-preset", "ultrafast",
            "-c:a", "aac", self.source,
        ], check=True, capture_output=True, timeout=20)

    def start(self, command):
        log = tempfile.TemporaryFile(mode="w+t")
        self.addCleanup(log.close)
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=log, text=True)

        def stop():
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=3)
            process.stdout.close()

        self.addCleanup(stop)
        return process, log

    def receiver(self):
        process, log = self.start([
            self.ffmpeg, "-hide_banner", "-loglevel", "error",
            "-progress", "pipe:1", "-stats_period", "0.1",
            "-analyzeduration", "100000", "-probesize", "100000",
            "-listen", "1", "-i", self.controller.OUTPUT_URL,
            "-copyts", "-f", "null", "-",
        ])
        progress = queue.Queue()

        def read():
            for line in process.stdout:
                if line.startswith("frame="):
                    progress.put(int(line.partition("=")[2]))

        threading.Thread(target=read, daemon=True).start()
        return process, log, progress

    def wait_for_frames(self, receiver):
        process, log, progress = receiver
        deadline = time.monotonic() + 12
        while time.monotonic() < deadline and process.poll() is None:
            try:
                if progress.get(timeout=0.2) >= 3:
                    return
            except queue.Empty:
                pass
        log.seek(0)
        self.fail("RTMP receiver did not decode video: " + log.read())

    def test_broken_output_reconnects_without_restarting_and_eof_still_finishes(self):
        first = self.receiver()
        command = self.controller.relay_command(self.source, None, None, 1, False)
        publisher, publisher_log = self.start(command)
        self.wait_for_frames(first)
        # A receiver disappearing mid-stream reproduces the broken RTMP socket.
        first[0].kill()
        first[0].wait(timeout=3)
        time.sleep(0.5)
        second = self.receiver()
        self.wait_for_frames(second)
        self.assertIsNone(publisher.poll(), "The original encoder must survive reconnecting")
        try:
            self.assertEqual(publisher.wait(timeout=25), 0)
        except subprocess.TimeoutExpired:
            self.fail("Relay kept retrying after normal input EOF")
        publisher_log.seek(0)
        self.assertNotIn("Unknown option", publisher_log.read())

    def test_hdr_sources_produce_sdr_video_with_correct_colour_tags(self):
        probe = str(Path(self.ffmpeg).with_name("ffprobe"))
        for transfer in ("smpte2084", "arib-std-b67"):
            with self.subTest(transfer=transfer):
                source = str(Path(self.directory.name, transfer + ".mkv"))
                subprocess.run([
                    self.ffmpeg, "-hide_banner", "-loglevel", "error",
                    "-f", "lavfi", "-i", "testsrc2=size=160x90:rate=10",
                    "-t", "0.5", "-pix_fmt", "yuv420p10le", "-c:v", "ffv1",
                    "-color_trc", transfer, "-color_primaries", "bt2020",
                    "-colorspace", "bt2020nc", source,
                ], check=True, capture_output=True, timeout=10)
                self.controller.OUTPUT_URL = str(Path(self.directory.name, transfer + ".flv"))
                command = self.controller.relay_command(source, None, None, None, False, hdr_transfer=transfer)
                command.remove("-re")
                result = subprocess.run(command, capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr)
                result = subprocess.run([
                    probe, "-v", "error", "-select_streams", "v:0",
                    "-show_entries", "stream=pix_fmt,color_space,color_transfer,color_primaries",
                    "-of", "json", self.controller.OUTPUT_URL,
                ], check=True, capture_output=True, text=True, timeout=10)
                stream = json.loads(result.stdout)["streams"][0]
                self.assertEqual(stream["pix_fmt"], "yuv420p")
                for tag in ("color_space", "color_transfer", "color_primaries"):
                    self.assertEqual(stream[tag], "bt709")

    def test_noisy_video_stays_within_the_bitrate_budget(self):
        self.controller.OUTPUT_URL = str(Path(self.directory.name, "bounded.flv"))
        # Noise makes an unconstrained quality encode much larger than the budget.
        command = self.controller.relay_command(
            "testsrc2=size=854x480:rate=24,noise=alls=60:allf=t", None, None, 3, False,
        )
        command.remove("-re")
        index = command.index("-i")
        command[index:index] = ["-f", "lavfi"]
        command[-1:-1] = ["-t", "6"]
        result = subprocess.run(command, capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        probe = str(Path(self.ffmpeg).with_name("ffprobe"))
        result = subprocess.run([
            probe, "-v", "error", "-select_streams", "v:0", "-show_packets",
            "-show_entries", "packet=size", "-of", "json", self.controller.OUTPUT_URL,
        ], check=True, capture_output=True, text=True, timeout=10)
        packets = json.loads(result.stdout)["packets"]
        self.assertEqual(len(packets), 6 * 24)
        encoded_bits = sum(int(packet["size"]) for packet in packets) * 8
        # The allowed bits include the initial two-second VBV buffer.
        self.assertLessEqual(encoded_bits, 1_800_000 * (6 + 2))
        self.assertGreater(encoded_bits, 1_800_000 * 3)

    def test_permanent_output_failure_eventually_exits(self):
        command = self.controller.relay_command(self.source, None, None, 1, False)
        # Use a short retry budget for this test; the production budget is 30.
        command[command.index("-max_recovery_attempts") + 1] = "2"
        command[command.index("-recovery_wait_time") + 1] = "0.1"
        process, _ = self.start(command)
        self.assertNotEqual(process.wait(timeout=12), 0)


if __name__ == "__main__":
    unittest.main()
