import importlib.util
import io
import os
from pathlib import Path
import tempfile
import unittest
from email.message import Message
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError, URLError

from jellyfin import NoRedirect, prepare_jellyfin_input, prepare_jellyfin_subtitles, JellyfinSubtitleFiles, JellyfinClock


SOURCE = "https://jellyfin.test/jellyfin/Videos/" + "a" * 32 + "/stream?Static=true&MediaSourceId=version"
TOKEN = "b" * 32
ASS = b"[Script Info]\nScriptType: v4.00+\n[Events]\n"


class JellyfinInputTests(unittest.TestCase):
    @patch("jellyfin.build_opener")
    def test_http_requires_the_exact_configured_origin(self, opener):
        headers = Message()
        headers["Content-Type"] = "video/x-matroska"
        opener.return_value.open.return_value.__enter__.return_value.headers = headers
        source = SOURCE.replace("https://jellyfin.test", "http://192.168.1.240:8096")
        with patch.dict(os.environ, {"BUNNY_JELLYFIN_HTTP_ORIGIN": "http://192.168.1.240:8096"}):
            prepare_jellyfin_input(source, TOKEN)
            for rejected in [source.replace(":8096", ":8080"), source.replace("192.168.1.240", "192.168.1.241")]:
                with self.assertRaises(ValueError):
                    prepare_jellyfin_input(rejected, TOKEN)
        self.assertEqual(opener.return_value.open.call_count, 1)

    @patch("jellyfin.build_opener")
    def test_checks_media_without_putting_token_in_url(self, opener):
        headers = Message()
        headers["Content-Type"] = "video/x-matroska"
        opener.return_value.open.return_value.__enter__.return_value.headers = headers
        result = prepare_jellyfin_input(SOURCE, TOKEN)
        request = opener.return_value.open.call_args.args[0]
        self.assertEqual(request.full_url, SOURCE)
        self.assertEqual(request.get_method(), "HEAD")
        self.assertEqual(request.get_header("X-emby-token"), TOKEN)
        self.assertEqual(result, f"X-Emby-Token: {TOKEN}\r\n")
        self.assertIsInstance(opener.call_args.args[0], NoRedirect)

    @patch("jellyfin.build_opener")
    def test_rejects_invalid_sources_and_header_injection_before_network(self, opener):
        for source, token in [
            (SOURCE.replace("https:", "http:"), TOKEN),
            (SOURCE.replace("jellyfin.test", "user:pass@jellyfin.test"), TOKEN),
            (SOURCE + "&api_key=secret", TOKEN),
            (SOURCE.replace("Static=true", "Static=false"), TOKEN),
            (SOURCE, TOKEN + "\r\nHeader: injected"),
            ("https://example.test/video", TOKEN),
        ]:
            with self.subTest(source=source):
                with self.assertRaises(ValueError):
                    prepare_jellyfin_input(source, token)
        opener.assert_not_called()

    @patch("jellyfin.build_opener")
    def test_upstream_errors_do_not_expose_credentials(self, opener):
        for error in [HTTPError(SOURCE, 401, TOKEN, {}, None), URLError(TOKEN)]:
            opener.return_value.open.side_effect = error
            with self.assertRaises(RuntimeError) as caught:
                prepare_jellyfin_input(SOURCE, TOKEN)
            self.assertNotIn(TOKEN, str(caught.exception))

    @patch("jellyfin.build_opener")
    def test_rejects_login_pages(self, opener):
        headers = Message()
        headers["Content-Type"] = "text/html"
        opener.return_value.open.return_value.__enter__.return_value.headers = headers
        with self.assertRaisesRegex(RuntimeError, "web page"):
            prepare_jellyfin_input(SOURCE, TOKEN)


class SubtitleFilesTests(unittest.TestCase):
    @patch("jellyfin.build_opener")
    def test_selected_track_and_fonts_are_authenticated_local_assets(self, opener):
        def response(request, **kwargs):
            result = MagicMock()
            result.__enter__.return_value = result
            result.headers = {}
            result.read.return_value = ASS if "/Subtitles/" in request.full_url else b"font bytes"
            return result

        opener.return_value.open.side_effect = response
        files = prepare_jellyfin_subtitles(SOURCE, TOKEN, 3, [9, 10])
        self.addCleanup(files.stop)
        requests = [call.args[0] for call in opener.return_value.open.call_args_list]
        base = "https://jellyfin.test/jellyfin/Videos/" + "a" * 32 + "/version"
        self.assertEqual(requests[0].full_url, base + "/Subtitles/3/Stream.ass?copyTimestamps=true")
        self.assertEqual({request.full_url for request in requests[1:]}, {base + "/Attachments/9", base + "/Attachments/10"})
        for request in requests:
            self.assertEqual(request.get_header("X-emby-token"), TOKEN)
            self.assertNotIn(TOKEN, request.full_url)
        self.assertIsInstance(opener.call_args.args[0], NoRedirect)
        self.assertEqual(files.track.read_bytes(), ASS)
        self.assertEqual(files.fonts.joinpath("font-9.ttf").read_bytes(), b"font bytes")
        self.assertNotIn(TOKEN, files.video_filter())
        files.stop()
        self.assertFalse(files.track.parent.exists())

    @patch("jellyfin.build_opener")
    def test_no_selection_does_not_download_subtitles(self, opener):
        self.assertIsNone(prepare_jellyfin_subtitles(SOURCE, TOKEN, None))
        opener.assert_not_called()

    @patch("jellyfin.build_opener")
    def test_failed_or_invalid_extraction_removes_temporary_assets(self, opener):
        for data, length, error in [
            (b"<html>Login</html>", None, None),
            (ASS, "9000000", None),
            (ASS, None, HTTPError(SOURCE, 401, TOKEN, {}, None)),
        ]:
            created = []

            def assets():
                files = JellyfinSubtitleFiles()
                created.append(files)
                return files

            response = MagicMock()
            response.__enter__.return_value = response
            response.headers = {} if length is None else {"Content-Length": length}
            response.read.return_value = data
            opener.return_value.open.side_effect = error
            opener.return_value.open.return_value = response
            with patch("jellyfin.JellyfinSubtitleFiles", side_effect=assets):
                with self.assertRaises(RuntimeError) as caught:
                    prepare_jellyfin_subtitles(SOURCE, TOKEN, 3)
            self.assertNotIn(TOKEN, str(caught.exception))
            self.assertFalse(created[0].track.parent.exists())


class ControllerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with tempfile.TemporaryDirectory() as credentials:
            Path(credentials, "control-secret").write_text("test-secret", encoding="utf-8")
            with patch.dict(os.environ, {
                "CREDENTIALS_DIRECTORY": credentials, "BUNNY_FFMPEG": "ffmpeg", "BUNNY_FFPROBE": "ffprobe", "BUNNY_STREAMLINK": "streamlink", "BUNNY_OUTPUT_PASSWORD_CREDENTIAL": "0",
            }):
                spec = importlib.util.find_spec("controller")
                cls.controller = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(cls.controller)

    def test_input_authentication_precedes_input_and_track_mapping_is_preserved(self):
        command = self.controller.relay_command(SOURCE, 3, None, 5, True, f"X-Emby-Token: {TOKEN}\r\n")
        self.assertLess(command.index("-headers"), command.index("-i"))
        self.assertEqual(command[command.index("-i") + 1], SOURCE)
        self.assertIn("0:3", command)
        self.assertIn("scale=-2:trunc(min(ih\\,1080)/2)*2:flags=lanczos", command)
        direct = self.controller.relay_command("https://torbox.test/file", None, None, None, True)
        self.assertNotIn("-headers", direct)

    def test_both_encoders_bound_bitrate_at_every_resolution(self):
        for encoder, quality_option in (("libx264", "-crf"), ("h264_nvenc", "-cq")):
            with patch.object(self.controller, "VIDEO_ENCODER", encoder):
                for resolution, limit in enumerate((250, 500, 1000, 1800, 3500, 6000, 12000, 20000)):
                    with self.subTest(encoder=encoder, resolution=resolution):
                        command = self.controller.relay_command(SOURCE, None, None, resolution, True)
                        self.assertEqual(command[command.index("-maxrate:v") + 1], f"{limit}k")
                        self.assertEqual(command[command.index("-bufsize:v") + 1], f"{limit * 2}k")
                        self.assertEqual(command[command.index(quality_option) + 1], "20")
                original = self.controller.relay_command("pipe:0", None, None, None, False)
                self.assertEqual(original[original.index("-maxrate:v") + 1], "20000k")
                self.assertEqual(original[original.index("-bufsize:v") + 1], "40000k")

    def test_invalid_hdr_conversion_does_not_replace_the_stream(self):
        with patch.object(self.controller, "stop_relay") as stop:
            with self.assertRaisesRegex(ValueError, "HDR transfer"):
                self.controller.start_relay(SOURCE, "Movie", None, None, None, hdr_transfer="injected-filter")
            stop.assert_not_called()

    def test_failed_access_does_not_stop_current_stream(self):
        with patch.object(self.controller, "prepare_jellyfin_input", side_effect=RuntimeError("Unauthorized")), patch.object(self.controller, "stop_relay") as stop:
            with self.assertRaises(RuntimeError):
                self.controller.start_jellyfin(SOURCE, TOKEN, "Movie", None, None)
            stop.assert_not_called()

    def test_jellyfin_uses_shared_lifecycle_and_status(self):
        process = MagicMock()
        process.poll.return_value = None
        with patch.object(self.controller, "prepare_jellyfin_input", return_value=f"X-Emby-Token: {TOKEN}\r\n"), patch.object(self.controller.subprocess, "Popen", return_value=process), patch.object(self.controller.time, "sleep"):
            self.controller.start_jellyfin(SOURCE, TOKEN, "Movie", None, None)
            status = self.controller.relay_status()
            self.assertTrue(status['running'])
            self.assertEqual(status['sourceType'], 'jellyfin')
            self.assertEqual(status['title'], 'Movie')
            self.assertEqual(status['jellyfin']['itemId'], 'a' * 32)
            self.assertEqual(status['jellyfin']['mediaSourceId'], 'version')
            self.assertNotIn(TOKEN, str(status))
            command = self.controller.subprocess.Popen.call_args.args[0]
            self.assertIn('-progress', command)
            self.controller.stop_relay()
            process.terminate.assert_called_once()
            self.assertFalse(self.controller.relay_status()["running"])
            self.assertNotIn('jellyfin', self.controller.relay_status())

    def test_admin_subtitle_selection_is_burned_and_resets_for_each_stream(self):
        process = MagicMock()
        process.poll.return_value = None
        files = JellyfinSubtitleFiles()
        files.track.write_bytes(ASS)
        self.addCleanup(files.stop)
        with patch.object(self.controller, "prepare_jellyfin_subtitles", side_effect=[files, None]) as prepare, patch.object(self.controller, "prepare_jellyfin_input", return_value=f"X-Emby-Token: {TOKEN}\r\n"), patch.object(self.controller.subprocess, "Popen", return_value=process), patch.object(self.controller.time, "sleep"):
            self.controller.start_jellyfin(SOURCE, TOKEN, "Movie", None, None, subtitle_index=3, subtitle_fonts=[9])
            prepare.assert_called_once_with(SOURCE, TOKEN, 3, [9])
            selected = self.controller.relay_status()['jellyfin']
            self.assertEqual(selected['subtitleIndex'], 3)
            self.assertTrue(selected['subtitlesBurnedIn'])
            command = self.controller.subprocess.Popen.call_args.args[0]
            self.assertEqual([command[index + 1] for index, value in enumerate(command) if value == '-map'], ['0:v:0', '0:a:0?'])
            self.assertIn(files.video_filter(), command[command.index('-vf') + 1])
            self.assertNotIn('0:3', command)
            self.assertTrue(files.track.exists())
            self.controller.start_jellyfin(SOURCE, TOKEN, "Next movie", None, None)
            next_stream = self.controller.relay_status()['jellyfin']
            self.assertIsNone(next_stream['subtitleIndex'])
            self.assertFalse(next_stream['subtitlesBurnedIn'])
            self.assertFalse(files.track.parent.exists())
            self.assertNotEqual(selected['sessionId'], next_stream['sessionId'])
            self.controller.stop_relay()

    def test_failed_subtitle_download_does_not_stop_current_stream(self):
        with patch.object(self.controller, "prepare_jellyfin_input"), patch.object(self.controller, "prepare_jellyfin_subtitles", side_effect=RuntimeError("Could not load track")), patch.object(self.controller, "stop_relay") as stop:
            with self.assertRaises(RuntimeError):
                self.controller.start_jellyfin(SOURCE, TOKEN, "Movie", None, None, subtitle_index=3)
            stop.assert_not_called()

    def test_invalid_font_indexes_do_not_replace_playback(self):
        with patch.object(self.controller, "prepare_jellyfin_input") as prepare, patch.object(self.controller, "stop_relay") as stop:
            for value in ([True], [-1], [1, 1], ["2"], list(range(17)), "fonts"):
                with self.subTest(value=value), self.assertRaisesRegex(ValueError, "subtitleFonts"):
                    self.controller.start_jellyfin(SOURCE, TOKEN, "Movie", None, None, subtitle_index=3, subtitle_fonts=value)
            prepare.assert_not_called()
            stop.assert_not_called()

    def test_failed_start_cleans_subtitles_and_resets_status(self):
        for failure in ("exit", "spawn"):
            files = JellyfinSubtitleFiles()
            files.track.write_bytes(ASS)
            self.addCleanup(files.stop)
            process = MagicMock()
            process.poll.return_value = 1
            process.returncode = 1
            with patch.object(self.controller, "prepare_jellyfin_input"), patch.object(self.controller, "prepare_jellyfin_subtitles", return_value=files), patch.object(self.controller.subprocess, "Popen", return_value=process, side_effect=OSError("spawn failed") if failure == "spawn" else None), patch.object(self.controller.time, "sleep"):
                with self.assertRaises((RuntimeError, OSError)):
                    self.controller.start_jellyfin(SOURCE, TOKEN, "Movie", None, None, subtitle_index=3)
                self.assertFalse(files.track.parent.exists())
                self.assertFalse(self.controller.relay_status()["running"])
                self.assertNotIn("jellyfin", self.controller.relay_status())

    def test_invalid_subtitle_selection_does_not_replace_playback(self):
        with patch.object(self.controller, "prepare_jellyfin_input") as prepare, patch.object(self.controller, "stop_relay") as stop:
            for value in (-1, True, "3", 1.5):
                with self.subTest(value=value), self.assertRaisesRegex(ValueError, "subtitleIndex"):
                    self.controller.start_jellyfin(SOURCE, TOKEN, "Movie", None, None, subtitle_index=value)
            prepare.assert_not_called()
            stop.assert_not_called()

    def test_http_is_available_only_to_validated_jellyfin_playback(self):
        source = SOURCE.replace("https://jellyfin.test", "http://192.168.1.240:8096")
        process = MagicMock()
        process.poll.return_value = None
        with patch.object(self.controller, "prepare_jellyfin_input", return_value=f"X-Emby-Token: {TOKEN}\r\n"), patch.object(self.controller.subprocess, "Popen", return_value=process), patch.object(self.controller.time, "sleep"):
            self.controller.start_jellyfin(source, TOKEN, "Movie", None, None)
            self.controller.stop_relay()
            with self.assertRaises(ValueError):
                self.controller.start_relay(source, "Movie", None, None, None)


class ClockTests(unittest.TestCase):
    def test_clock_uses_encoded_output_not_process_start_or_viewer_wall_time(self):
        clock = JellyfinClock(SOURCE)
        output = io.StringIO('frame=0\nout_time_us=N/A\nprogress=continue\nframe=1\nout_time_us=0\nprogress=continue\nframe=1\nout_time_us=250000\nprogress=continue\nframe=90\nout_time_us=5000000\nprogress=continue\n')
        self.assertIsNone(clock.status()['startedAt'])
        with patch('jellyfin.time.time', return_value=1800000000.25):
            clock.read_progress(output)
        self.assertEqual(clock.status()['startedAt'], 1800000000000)
        self.assertTrue(output.closed)

    def test_new_process_gets_new_identity_and_old_reader_cannot_change_it(self):
        old = JellyfinClock(SOURCE)
        current = JellyfinClock(SOURCE)
        self.assertNotEqual(old.session_id, current.session_id)
        with patch('jellyfin.time.time', return_value=1800000000):
            old.read_progress(io.StringIO('frame=1\nout_time_us=100000\nprogress=end\n'))
        self.assertIsNone(current.started_at)


if __name__ == "__main__":
    unittest.main()
