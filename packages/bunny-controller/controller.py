#!/usr/bin/env python3
import hmac
import json
import os
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import quote, urlparse


def read_credential(name):
    with open(
        os.path.join(os.environ["CREDENTIALS_DIRECTORY"], name),
        encoding="utf-8",
    ) as credential_file:
        return credential_file.read().strip()


CONTROL_SECRET = read_credential("control-secret")
if CONTROL_SECRET.startswith("BUNNY_CONTROL_SECRET="):
    CONTROL_SECRET = CONTROL_SECRET.split("=", 1)[1]
FFMPEG = os.environ["BUNNY_FFMPEG"]
FFPROBE = os.environ["BUNNY_FFPROBE"]
LISTEN_HOST = os.environ.get("BUNNY_CONTROLLER_HOST", "127.0.0.1")
LISTEN_PORT = int(os.environ.get("BUNNY_CONTROLLER_PORT", "10000"))
OUTPUT_URL = os.environ.get(
    "BUNNY_OUTPUT_URL",
    "rtmp://127.0.0.1:1935/bunny-plus?user=controller",
)
if os.environ.get("BUNNY_OUTPUT_PASSWORD_CREDENTIAL") == "1":
    separator = "&" if "?" in OUTPUT_URL else "?"
    OUTPUT_URL += f"{separator}pass={quote(read_credential('publisher-password'), safe='')}"
VIDEO_ENCODER = os.environ.get("BUNNY_VIDEO_ENCODER", "libx264")
PROBE_TIMEOUT_SECONDS = int(os.environ.get("BUNNY_PROBE_TIMEOUT_SECONDS", "20"))
RESOLUTION_HEIGHTS = [144, 240, 360, 480, 720, 1080, 1440, 2160]

lock = threading.Lock()
relay = None
relay_title = None


def validate_source(source):
    if not isinstance(source, str):
        raise ValueError("The relay source must be an HTTPS URL")
    parsed = urlparse(source)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username is not None:
        raise ValueError("The relay source must be an HTTPS URL")
    return source


def optional_index(value, name):
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{name} must be a non-negative integer or null")
    return value


def probe_source(source):
    source = validate_source(source)
    command = [
        FFPROBE,
        "-v",
        "error",
        "-rw_timeout",
        str(PROBE_TIMEOUT_SECONDS * 1_000_000),
        "-analyzeduration",
        "10000000",
        "-probesize",
        "20000000",
        "-show_streams",
        "-of",
        "json",
        source,
    ]
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            check=True,
            text=True,
            timeout=PROBE_TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError("Media probe timed out") from error
    except subprocess.CalledProcessError as error:
        detail = error.stderr.strip().splitlines()
        raise RuntimeError(detail[-1] if detail else "Could not inspect media") from error

    streams = json.loads(result.stdout).get("streams", [])

    def clean_track(stream):
        tags = stream.get("tags") or {}
        disposition = stream.get("disposition") or {}
        return {
            "channels": stream.get("channels"),
            "codec": stream.get("codec_name"),
            "default": disposition.get("default") == 1,
            "index": stream["index"],
            "language": tags.get("language"),
            "title": tags.get("title"),
        }

    audio = [clean_track(stream) for stream in streams if stream.get("codec_type") == "audio"]
    video_heights = [
        stream.get("height")
        for stream in streams
        if stream.get("codec_type") == "video"
        and (stream.get("disposition") or {}).get("attached_pic") != 1
        and isinstance(stream.get("height"), int)
    ]
    # Remote embedded subtitle extraction/burning is intentionally unsupported.
    return {
        "audio": audio,
        "subtitles": [],
        "sourceResolution": max(video_heights) if video_heights else None,
    }


def stop_relay():
    global relay, relay_title
    if relay is not None and relay.poll() is None:
        relay.terminate()
        try:
            relay.wait(timeout=5)
        except subprocess.TimeoutExpired:
            relay.kill()
            relay.wait(timeout=2)
    relay = None
    relay_title = None


def start_relay(source, title, audio_index, subtitle_index, resolution_index):
    global relay, relay_title
    source = validate_source(source)
    audio_index = optional_index(audio_index, "audioIndex")
    subtitle_index = optional_index(subtitle_index, "subtitleIndex")
    resolution_index = optional_index(resolution_index, "resolutionIndex")
    if subtitle_index is not None:
        raise ValueError("Remote embedded subtitles are not supported")
    if resolution_index is not None and resolution_index >= len(RESOLUTION_HEIGHTS):
        raise ValueError("resolutionIndex is out of range")

    stop_relay()
    command = [
        FFMPEG,
        "-hide_banner",
        "-loglevel",
        "warning",
        "-fflags",
        "+genpts+discardcorrupt",
        "-reconnect",
        "1",
        "-reconnect_streamed",
        "1",
        "-reconnect_delay_max",
        "5",
        "-reconnect_delay_total_max",
        "60",
        "-reconnect_on_network_error",
        "1",
        "-reconnect_on_http_error",
        "4xx,5xx",
        "-http_persistent",
        "1",
        "-multiple_requests",
        "1",
        "-seekable",
        "1",
        "-rw_timeout",
        "45000000",
        "-re",
        "-i",
        source,
        "-map",
        "0:v:0",
        "-map",
        f"0:{audio_index}" if audio_index is not None else "0:a:0?",
        "-c:v",
        VIDEO_ENCODER,
    ]
    if VIDEO_ENCODER == "h264_nvenc":
        command.extend(["-preset", "p4", "-tune", "hq", "-profile:v", "high"])
    elif VIDEO_ENCODER == "libx264":
        command.extend(["-preset", "veryfast", "-profile:v", "high"])

    target_height = RESOLUTION_HEIGHTS[resolution_index] if resolution_index is not None else None
    height = f"min(ih\\,{target_height})" if target_height is not None else "ih"
    command.extend(
        [
            "-vf",
            f"scale=-2:trunc({height}/2)*2:flags=lanczos",
            "-pix_fmt",
            "yuv420p",
            "-c:a",
            "aac",
            "-b:a",
            "192k",
            "-ac",
            "2",
            "-ar",
            "48000",
            "-avoid_negative_ts",
            "make_zero",
            "-muxdelay",
            "0",
            "-f",
            "flv",
            OUTPUT_URL,
        ]
    )
    last_code = None
    for attempt in range(2):
        relay = subprocess.Popen(command)
        relay_title = title
        for _ in range(20):
            time.sleep(0.1)
            if relay.poll() is not None:
                break
        if relay.poll() is None:
            return
        last_code = relay.returncode
        relay = None
        relay_title = None
        if attempt == 0:
            time.sleep(1)
    raise RuntimeError(f"FFmpeg exited while starting (code {last_code})")


def relay_status():
    global relay, relay_title
    if relay is not None and relay.poll() is not None:
        relay = None
        relay_title = None
    return {"running": relay is not None, "title": relay_title}


class Handler(BaseHTTPRequestHandler):
    server_version = "bunny-stream-controller/2"

    def authorized(self):
        authorization = self.headers.get("Authorization", "")
        expected = f"Bearer {CONTROL_SECRET}"
        return hmac.compare_digest(authorization, expected)

    def respond(self, status, body):
        encoded = json.dumps(body, separators=(",", ":")).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(encoded)

    def do_GET(self):
        if self.path != "/__bunny/control":
            return self.respond(404, {"error": "Not found"})
        if not self.authorized():
            return self.respond(401, {"error": "Unauthorized"})
        with lock:
            self.respond(200, relay_status())

    def do_POST(self):
        if self.path != "/__bunny/control":
            return self.respond(404, {"error": "Not found"})
        if not self.authorized():
            return self.respond(401, {"error": "Unauthorized"})
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 65536:
                return self.respond(400, {"error": "Invalid request size"})
            body = json.loads(self.rfile.read(length))
            action = body.get("action")
            if action == "probe":
                return self.respond(200, probe_source(body.get("source", "")))
            with lock:
                if action == "start":
                    title = str(body.get("title", "TorBox stream"))[:200]
                    start_relay(
                        body.get("source", ""),
                        title,
                        body.get("audioIndex"),
                        body.get("subtitleIndex"),
                        body.get("resolutionIndex"),
                    )
                    return self.respond(200, {"detail": "Relay started", **relay_status()})
                if action == "stop":
                    stop_relay()
                    return self.respond(200, {"detail": "Relay stopped", **relay_status()})
            return self.respond(400, {"error": "Unknown action"})
        except (ValueError, json.JSONDecodeError) as error:
            self.respond(400, {"error": str(error)})
        except Exception as error:
            self.respond(502, {"error": str(error)})

    def log_message(self, message, *args):
        print(f"{self.address_string()} - {message % args}", flush=True)


if __name__ == "__main__":
    ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), Handler).serve_forever()
