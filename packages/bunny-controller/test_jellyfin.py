import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from email.message import Message
from unittest.mock import MagicMock, patch
from urllib.error import HTTPError, URLError

from jellyfin import NoRedirect, prepare_jellyfin_input


SOURCE = "https://jellyfin.test/jellyfin/Videos/" + "a" * 32 + "/stream?Static=true&MediaSourceId=version"
TOKEN = "b" * 32


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
            self.assertEqual(self.controller.relay_status(), {"running": True, "sourceType": "jellyfin", "title": "Movie"})
            self.controller.stop_relay()
            process.terminate.assert_called_once()
            self.assertFalse(self.controller.relay_status()["running"])

    def test_http_is_available_only_to_validated_jellyfin_playback(self):
        source = SOURCE.replace("https://jellyfin.test", "http://192.168.1.240:8096")
        process = MagicMock()
        process.poll.return_value = None
        with patch.object(self.controller, "prepare_jellyfin_input", return_value=f"X-Emby-Token: {TOKEN}\r\n"), patch.object(self.controller.subprocess, "Popen", return_value=process), patch.object(self.controller.time, "sleep"):
            self.controller.start_jellyfin(source, TOKEN, "Movie", None, None)
            self.controller.stop_relay()
            with self.assertRaises(ValueError):
                self.controller.start_relay(source, "Movie", None, None, None)


if __name__ == "__main__":
    unittest.main()
