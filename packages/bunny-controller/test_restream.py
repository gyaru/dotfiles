import json
import unittest
from unittest.mock import patch

from restream import (
    fallback_restream_title,
    resolve_restream_title,
    streamlink_command,
    validate_restream_url,
)


class RestreamTest(unittest.TestCase):
    def test_accepts_supported_platform_urls(self):
        self.assertEqual(validate_restream_url("https://youtu.be/abc123"), "youtube")
        self.assertEqual(validate_restream_url("https://www.twitch.tv/bunny"), "twitch")

    def test_builds_streamlink_command_without_a_shell(self):
        self.assertEqual(
            streamlink_command(
                "/bin/streamlink",
                "/bin/ffmpeg",
                "https://twitch.tv/bunny",
                "720p",
            ),
            [
                "/bin/streamlink",
                "--loglevel",
                "error",
                "--no-plugin-cache",
                "--ffmpeg-ffmpeg",
                "/bin/ffmpeg",
                "--stream-sorting-excludes",
                ">720p",
                "--stdout",
                "https://twitch.tv/bunny",
                "best",
            ],
        )

    def test_rejects_unsafe_sources_and_unknown_quality(self):
        for source in (
            "http://youtube.com/watch?v=abc",
            "https://youtube.com.evil.test/watch?v=abc",
            "https://user@twitch.tv/bunny",
            "https://127.0.0.1/live",
            "https://youtube.com/",
        ):
            with self.subTest(source=source):
                with self.assertRaises(ValueError):
                    validate_restream_url(source)
        with self.assertRaises(ValueError):
            streamlink_command("streamlink", "ffmpeg", "https://twitch.tv/bunny", "source")

    def test_resolves_channel_name_from_streamlink_metadata(self):
        with patch("restream.subprocess.run") as run:
            run.return_value.stdout = json.dumps({"metadata": {"author": "Bunny Channel"}})
            self.assertEqual(
                resolve_restream_title(
                    "streamlink",
                    "ffmpeg",
                    "https://youtube.com/watch?v=abc123",
                    "best",
                ),
                "Bunny Channel",
            )
        self.assertEqual(fallback_restream_title("https://twitch.tv/bunny"), "bunny")
        self.assertEqual(fallback_restream_title("https://youtube.com/@bunny/live"), "@bunny")


if __name__ == "__main__":
    unittest.main()
