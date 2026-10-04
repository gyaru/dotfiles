"""Authenticated Jellyfin input for the shared FFmpeg relay."""

import os
import re
import threading
import time
import uuid
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlparse
from urllib.request import HTTPRedirectHandler, Request, build_opener


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


def prepare_jellyfin_input(source, api_key):
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

    # Check access before replacing the current relay. Never forward the token to a redirect.
    request = Request(source, headers={"X-Emby-Token": api_key}, method="HEAD")
    try:
        with build_opener(NoRedirect()).open(request, timeout=10) as response:
            if response.headers.get_content_type() == "text/html":
                raise RuntimeError("Jellyfin returned a web page instead of a video")
    except HTTPError as error:
        raise RuntimeError(f"Jellyfin video request failed ({error.code})") from None
    except (URLError, OSError):
        raise RuntimeError("Could not reach the Jellyfin video from the controller") from None

    return f"X-Emby-Token: {api_key}\r\n"


class JellyfinClock:
    """A per-process clock: stale progress readers cannot change a new relay.

    The first encoded output timestamp estimates the program date of source
    time zero. Unlike process launch time, it excludes probing/startup delay.
    HLS program dates then let late/buffering viewers follow the watched frame.
    Encoder/network latency can leave a small offset; viewers can adjust it.
    """

    def __init__(self, source, subtitle_index=None):
        url = urlparse(source)
        self.session_id = uuid.uuid4().hex
        self.item_id = url.path.split('/')[-2]
        self.media_source_id = parse_qs(url.query)['MediaSourceId'][0]
        self.started_at = None
        self.subtitle_index = subtitle_index

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
                'subtitleIndex': self.subtitle_index}
