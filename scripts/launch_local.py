#!/usr/bin/env python3

import mimetypes
import os
import platform
import socket
import subprocess
import sys
import webbrowser
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOST = "127.0.0.1"
PREFERRED_PORTS = [4173, 4174, 4175, 8080, 8000]
ROOT = Path(__file__).resolve().parent.parent

mimetypes.add_type("application/manifest+json", ".webmanifest")


def find_free_port() -> int:
    for port in PREFERRED_PORTS:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                sock.bind((HOST, port))
            except OSError:
                continue
            return port
    raise RuntimeError("空いているローカルポートが見つかりませんでした。")


def open_browser(url: str) -> None:
    if os.environ.get("NO_OPEN_BROWSER", "").lower() in {"1", "true", "yes"}:
        return

    system = platform.system()

    if system == "Darwin":
        browser_apps = [
            "Google Chrome",
            "Microsoft Edge",
            "Chromium",
        ]

        for app in browser_apps:
            result = subprocess.run(
                ["open", "-a", app, url],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            if result.returncode == 0:
                return

        subprocess.run(
            ["open", url],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        return

    if system == "Windows":
        commands = [
            ["cmd", "/c", "start", "", f"microsoft-edge:{url}"],
            ["cmd", "/c", "start", "", url],
        ]

        for command in commands:
            result = subprocess.run(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            if result.returncode == 0:
                return

    elif system == "Linux":
        result = subprocess.run(
            ["xdg-open", url],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode == 0:
            return

    webbrowser.open(url, new=2)


class LocalHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    def log_message(self, format: str, *args) -> None:
        sys.stdout.write("[local] " + format % args + "\n")


def main() -> int:
    os.chdir(ROOT)
    port = find_free_port()
    url = f"http://{HOST}:{port}/"
    server = ThreadingHTTPServer((HOST, port), LocalHandler)

    print("")
    print("だにえるキャリブー")
    print(f"配信フォルダ: {ROOT}")
    print(f"起動URL: {url}")
    print("Chrome または Edge で開いてください。")
    print("")
    print("このウィンドウは作業中は閉じないでください。")
    print("終了するときは Ctrl + C を押してください。")
    print("")

    open_browser(url)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nローカルサーバーを停止します。")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
