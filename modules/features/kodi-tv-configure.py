import argparse
import os
from pathlib import Path
import tempfile
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--settings", required=True, type=Path)
    parser.add_argument("--connector", required=True)
    parser.add_argument("--audio-device", required=True)
    parser.add_argument("--http-port", required=True, type=int)
    parser.add_argument("--password-file", required=True, type=Path)
    args = parser.parse_args()

    password = args.password_file.read_text().rstrip("\r\n")
    if not password:
        raise ValueError("Kodi remote password must not be empty")

    settings = {
        "videoscreen.monitor": args.connector,
        "audiooutput.audiodevice": args.audio_device,
        "audiooutput.passthroughdevice": args.audio_device,
        "videoplayer.usevaapi": "true",
        "services.devicename": "Lapi TV",
        "services.webserver": "true",
        "services.webserverport": str(args.http_port),
        "services.webserverauthentication": "true",
        "services.webserverusername": "kodi",
        "services.webserverpassword": password,
        "services.esenabled": "true",
        "services.esallinterfaces": "true",
        "services.zeroconf": "false",
    }

    tree = ET.parse(args.settings) if args.settings.exists() else ET.ElementTree(
        ET.Element("settings", version="2")
    )
    root = tree.getroot()
    for section in ("resolutions", "viewstates"):
        if root.find(section) is None:
            ET.SubElement(root, section)
    for name, value in settings.items():
        matches = root.findall(f"setting[@id='{name}']")
        element = matches[0] if matches else ET.SubElement(root, "setting", id=name)
        for duplicate in matches[1:]:
            root.remove(duplicate)
        element.attrib.pop("default", None)
        element.text = value

    args.settings.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    descriptor, temporary_path = tempfile.mkstemp(dir=args.settings.parent)
    try:
        with os.fdopen(descriptor, "wb") as output:
            tree.write(output, encoding="utf-8", xml_declaration=True)
        os.replace(temporary_path, args.settings)
    finally:
        Path(temporary_path).unlink(missing_ok=True)


if __name__ == "__main__":
    main()
