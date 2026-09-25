"""Authenticated Jellyfin input for the shared FFmpeg relay."""

import re
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
    if (
        url.scheme != "https"
        or not url.hostname
        or url.username is not None
        or url.password is not None
        or url.fragment
        or not re.search(r"/Videos/[a-fA-F0-9-]{32,36}/stream$", url.path)
    ):
        raise ValueError("Jellyfin requires an HTTPS video stream URL")
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
