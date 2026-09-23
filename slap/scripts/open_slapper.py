#!/usr/bin/env python3
"""Open AI Slapper as a local file without starting a server."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import webbrowser


def page_url() -> str:
    page = Path(__file__).resolve().parent.parent / "assets" / "slapper.html"
    if not page.is_file():
        raise FileNotFoundError(f"AI Slapper page not found: {page}")
    return page.as_uri()


def open_browser(url: str) -> bool:
    """Use the native opener first, then fall back to Python's browser registry."""
    try:
        if sys.platform == "darwin":
            result = subprocess.run(
                ["open", url],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return result.returncode == 0
        if os.name == "nt":
            os.startfile(url)  # type: ignore[attr-defined]
            return True
        if opener := shutil.which("xdg-open"):
            result = subprocess.run(
                [opener, url],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            return result.returncode == 0
    except OSError:
        pass
    return webbrowser.open(url, new=2)


def main() -> int:
    parser = argparse.ArgumentParser(description="Open the private, local AI Slapper toy.")
    parser.add_argument(
        "--print-url",
        action="store_true",
        help="print the local URL without opening a browser",
    )
    args = parser.parse_args()

    try:
        url = page_url()
    except FileNotFoundError as error:
        print(error, file=sys.stderr)
        return 1

    print(url)
    if args.print_url:
        return 0

    if not open_browser(url):
        print("Could not launch a browser. Open the URL above manually.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
