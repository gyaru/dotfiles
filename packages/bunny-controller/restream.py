from collections import deque
import subprocess
import threading
from urllib.parse import urlparse


SUPPORTED_HOSTS = {
    "m.twitch.tv": "twitch",
    "m.youtube.com": "youtube",
    "twitch.tv": "twitch",
    "www.twitch.tv": "twitch",
    "www.youtube.com": "youtube",
    "youtu.be": "youtube",
    "youtube.com": "youtube",
}
SUPPORTED_QUALITIES = {"best", "1080p", "720p", "480p"}


def validate_restream_url(source):
    if not isinstance(source, str) or not source or len(source) > 2048:
        raise ValueError("A YouTube or Twitch URL is required")
    parsed = urlparse(source)
    if (
        parsed.scheme != "https"
        or not parsed.hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.port not in (None, 443)
    ):
        raise ValueError("The stream must use a standard HTTPS URL")
    platform = SUPPORTED_HOSTS.get(parsed.hostname.lower())
    if platform is None:
        raise ValueError("Only YouTube and Twitch streams are supported")
    if parsed.path in ("", "/"):
        raise ValueError("Enter a URL for a specific stream or channel")
    return platform


def streamlink_command(executable, ffmpeg, source, quality):
    validate_restream_url(source)
    if quality not in SUPPORTED_QUALITIES:
        raise ValueError("Choose a supported stream quality")
    command = [
        executable,
        "--loglevel",
        "error",
        "--no-plugin-cache",
        "--ffmpeg-ffmpeg",
        ffmpeg,
    ]
    if quality != "best":
        command.extend(["--stream-sorting-excludes", f">{quality}"])
    command.extend(["--stdout", source, "best"])
    return command


class StreamlinkInput:
    def __init__(self, executable, ffmpeg, source, quality):
        self.errors = deque(maxlen=8)
        self.process = subprocess.Popen(
            streamlink_command(executable, ffmpeg, source, quality),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.stderr_thread = threading.Thread(target=self._read_errors, daemon=True)
        self.stderr_thread.start()

    @property
    def output(self):
        if self.process.stdout is None:
            raise RuntimeError("Streamlink did not provide media output")
        return self.process.stdout

    def close_parent_output(self):
        if self.process.stdout is not None:
            self.process.stdout.close()

    def _read_errors(self):
        if self.process.stderr is None:
            return
        for line in iter(self.process.stderr.readline, b""):
            detail = line.decode("utf-8", errors="replace").strip()
            if detail:
                self.errors.append(detail)
                print(f"streamlink: {detail}", flush=True)

    def poll(self):
        return self.process.poll()

    def error_detail(self):
        return self.errors[-1] if self.errors else None

    def stop(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=2)
