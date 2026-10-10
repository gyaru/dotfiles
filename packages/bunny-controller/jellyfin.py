"""Authenticated Jellyfin input for the shared FFmpeg relay."""

import os
import re
import tempfile
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, quote, urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


def validate_jellyfin_input(source, api_key):
    if not isinstance(source, str) or len(source) > 4096:
        raise ValueError("A Jellyfin video URL is required")
    url = urlparse(source)
    allowed_http = (
        url.scheme == "http"
        and f"{url.scheme}://{url.netloc}" == os.environ.get("BUNNY_JELLYFIN_HTTP_ORIGIN")
    )
    if (
        (url.scheme != "https" and not allowed_http)
        or not url.hostname
        or url.username is not None
        or url.password is not None
        or url.fragment
        or not re.search(r"/Videos/[a-fA-F0-9-]{32,36}/stream$", url.path)
    ):
        raise ValueError("Jellyfin requires HTTPS or the configured HTTP origin")
    query = parse_qs(url.query)
    if (
        set(query) != {"Static", "MediaSourceId"}
        or query["Static"] != ["true"]
        or len(query["MediaSourceId"]) != 1
        or not query["MediaSourceId"][0]
    ):
        raise ValueError("Jellyfin requires a static video and media source")
    if not isinstance(api_key, str) or not re.fullmatch(r"[a-zA-Z0-9_-]{16,512}", api_key):
        raise ValueError("A valid Jellyfin API key is required")
    return url


def prepare_jellyfin_input(source, api_key):
    validate_jellyfin_input(source, api_key)

    # Check access before replacing the current relay. Never forward the token to a redirect.
    request = Request(source, headers={"X-Emby-Token": api_key}, method="HEAD")
    try:
        with build_opener(NoRedirect()).open(request, timeout=10) as response:
            if response.headers.get_content_type() == "text/html":
                raise RuntimeError("Jellyfin returned a web page instead of a video")
    except HTTPError as error:
        error.close()
        raise RuntimeError(f"Jellyfin video request failed ({error.code})") from None
    except (URLError, OSError):
        raise RuntimeError("Could not reach the Jellyfin video from the controller") from None

    return f"X-Emby-Token: {api_key}\r\n"


def validate_subtitle_fonts(indices):
    if indices is None:
        return []
    if (
        not isinstance(indices, list)
        or len(indices) > 16
        or any(isinstance(index, bool) or not isinstance(index, int) or index < 0 for index in indices)
        or len(set(indices)) != len(indices)
    ):
        raise ValueError("subtitleFonts must contain at most 16 unique attachment indexes")
    return indices


class JellyfinSubtitleFiles:
    """Private local assets kept until the encoder using them has stopped."""

    def __init__(self):
        # Controlled paths need no filtergraph escaping and never contain a token.
        # The controller runs with PrivateTmp, so each relay owns its assets.
        self.directory = tempfile.TemporaryDirectory(prefix="bunny-subtitles-", dir="/tmp")
        self.track = Path(self.directory.name, "track.ass")
        self.fonts = Path(self.directory.name, "fonts")
        self.fonts.mkdir()

    def video_filter(self):
        return f"ass=filename={self.track}:fontsdir={self.fonts}"

    def stop(self):
        self.directory.cleanup()


def subtitle_bytes(url, api_key, kind, limit, timeout):
    request = Request(url, headers={"X-Emby-Token": api_key})
    try:
        with build_opener(NoRedirect()).open(request, timeout=timeout) as response:
            length = response.headers.get("Content-Length")
            if length is not None and int(length) > limit:
                raise ValueError("size limit")
            data = response.read(limit + 1)
            if not data or len(data) > limit:
                raise ValueError("size limit")
            return data
    except HTTPError as error:
        error.close()
        raise RuntimeError(f"Could not load the Jellyfin subtitle {kind}") from None
    except (URLError, OSError, ValueError):
        raise RuntimeError(f"Could not load the Jellyfin subtitle {kind}") from None


def prepare_jellyfin_subtitles(source, api_key, subtitle_index, font_indices=None):
    fonts = validate_subtitle_fonts(font_indices)
    if subtitle_index is None:
        return None
    if isinstance(subtitle_index, bool) or not isinstance(subtitle_index, int) or subtitle_index < 0:
        raise ValueError("subtitleIndex must be a non-negative integer or null")
    url = validate_jellyfin_input(source, api_key)
    item_id = url.path.split("/")[-2]
    media_source = quote(parse_qs(url.query)["MediaSourceId"][0], safe="")
    base_path = url.path.rsplit("/Videos/", 1)[0]
    base = url._replace(path=f"{base_path}/Videos/{item_id}/{media_source}", query="").geturl()
    files = JellyfinSubtitleFiles()
    try:
        track = subtitle_bytes(
            f"{base}/Subtitles/{subtitle_index}/Stream.ass?copyTimestamps=true",
            api_key, "track", 8_000_000, 30,
        )
        if b"[Script Info]" not in track or b"[Events]" not in track:
            raise RuntimeError("Jellyfin returned an invalid subtitle track")
        files.track.write_bytes(track)

        def font(index):
            return index, subtitle_bytes(f"{base}/Attachments/{index}", api_key, "font", 5_000_000, 10)

        # Fetch attached fonts before replacing playback. Four bounded downloads
        # at a time also keep startup within the controller request's budget.
        with ThreadPoolExecutor(max_workers=4) as pool:
            total = 0
            for index, data in pool.map(font, fonts):
                total += len(data)
                if total > 32_000_000:
                    raise RuntimeError("Jellyfin subtitle fonts exceed the size limit")
                files.fonts.joinpath(f"font-{index}.ttf").write_bytes(data)
        return files
    except Exception:
        files.stop()
        raise


class JellyfinClock:
    """A per-process clock: stale progress readers cannot change a new relay.

    The first encoded output timestamp estimates the program date of source
    time zero. Unlike process launch time, it excludes probing/startup delay.
    Retain this timing in relay metadata for compatibility with older clients.
    Burned subtitles use video timestamps directly and do not use this clock.
    """

    def __init__(self, source, subtitle_index=None, subtitles_burned_in=False):
        url = urlparse(source)
        self.session_id = uuid.uuid4().hex
        self.item_id = url.path.split('/')[-2]
        self.media_source_id = parse_qs(url.query)['MediaSourceId'][0]
        self.started_at = None
        self.subtitle_index = subtitle_index
        self.subtitles_burned_in = subtitles_burned_in

    def read_progress(self, output):
        values = {}
        try:
            for line in output:
                key, separator, value = line.strip().partition('=')
                if not separator:
                    continue
                values[key] = value
                if key != 'progress':
                    continue
                try:
                    seconds = int(values.get('out_time_us', '-1')) / 1_000_000
                    if self.started_at is None and int(values.get('frame', '0')) > 0 and seconds > 0:
                        self.started_at = round((time.time() - seconds) * 1000)
                except ValueError:
                    pass
                values.clear()
        finally:
            output.close()

    def follow(self, process):
        threading.Thread(target=self.read_progress, args=(process.stdout,), daemon=True).start()

    def status(self):
        return {'sessionId': self.session_id, 'itemId': self.item_id,
                'mediaSourceId': self.media_source_id, 'startedAt': self.started_at,
                'subtitleIndex': self.subtitle_index,
                'subtitlesBurnedIn': self.subtitles_burned_in}
