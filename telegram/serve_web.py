#!/usr/bin/env python3
"""Serve Flutter web with MIME types + cache/gzip Telegram Mini App needs."""

from __future__ import annotations

import gzip
import http.server
import mimetypes
import os
import posixpath
import urllib.parse
from functools import lru_cache
from pathlib import Path

mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("application/javascript", ".mjs")
mimetypes.add_type("text/javascript", ".js")
mimetypes.add_type("model/gltf-binary", ".glb")

ROOT = Path(__file__).resolve().parents[1] / "build" / "web"
PORT = int(os.environ.get("APEX_WEB_PORT", "8088"))

_GZIP_EXT = {".js", ".mjs", ".css", ".wasm", ".json", ".svg", ".html", ".txt"}
_LONG_EXT = {".wasm", ".woff2", ".woff", ".ttf", ".png", ".jpg", ".jpeg", ".webp", ".svg", ".glb", ".frag"}
_NO_CACHE = {"/index.html", "/flutter_service_worker.js", "/manifest.json", "/version.json"}


class _RangedFile:
    def __init__(self, fh, remaining: int):
        self._fh = fh
        self._remaining = remaining

    def read(self, size: int = -1) -> bytes:
        if self._remaining <= 0:
            return b""
        if size < 0 or size > self._remaining:
            size = self._remaining
        data = self._fh.read(size)
        self._remaining -= len(data)
        return data

    def close(self) -> None:
        self._fh.close()


def _cache_control(url_path: str) -> str:
    if url_path in _NO_CACHE or url_path.endswith(".html") or url_path in ("/", ""):
        return "no-cache"
    name = posixpath.basename(url_path)
    ext = posixpath.splitext(name)[1].lower()
    if name in ("main.dart.js", "flutter.js", "flutter_bootstrap.js"):
        return "public, max-age=60"
    if ext == ".glb":
        return "public, max-age=86400"
    if ext in _LONG_EXT or "canvaskit" in url_path:
        return "public, max-age=2592000, immutable"
    if ext in {".js", ".mjs", ".css"}:
        return "public, max-age=86400"
    return "public, max-age=3600"


def _ensure_glb_symlink() -> None:
    src = Path(__file__).resolve().parents[1] / "assets" / "models"
    dst = ROOT / "assets" / "assets" / "models"
    if not src.is_dir():
        print(f"missing GLB source {src}", flush=True)
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink() or dst.is_dir():
        return
    dst.symlink_to(src)
    print(f"linked {dst} -> {src}")


@lru_cache(maxsize=64)
def _gzip_bytes(path: str, mtime: float) -> bytes:
    with open(path, "rb") as fh:
        return gzip.compress(fh.read(), compresslevel=5)


class Handler(http.server.SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        url_path = urllib.parse.urlparse(self.path).path
        self.send_header("Cache-Control", _cache_control(url_path))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Expose-Headers", "Accept-Ranges, Content-Range, Content-Length")
        self.send_header("Timing-Allow-Origin", "*")
        if url_path.endswith(".glb"):
            self.send_header("Accept-Ranges", "bytes")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()

    def send_head(self):
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            return super().send_head()
        if not os.path.isfile(path):
            return super().send_head()

        ext = posixpath.splitext(path)[1].lower()
        ctype = self.guess_type(path)
        try:
            fs = os.stat(path)
        except OSError:
            self.send_error(404, "File not found")
            return None

        range_header = self.headers.get("Range")
        if range_header and range_header.startswith("bytes="):
            spec = range_header.split("=", 1)[1].split(",")[0].strip()
            start_s, _, end_s = spec.partition("-")
            size = fs.st_size
            try:
                start = int(start_s) if start_s else 0
                end = int(end_s) if end_s else size - 1
            except ValueError:
                start, end = 0, size - 1
            start = max(0, start)
            end = min(size - 1, end)
            if start > end:
                self.send_error(416, "Requested range not satisfiable")
                return None
            length = end - start + 1
            self.send_response(206)
            self.send_header("Content-Type", ctype)
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Content-Range", f"bytes {start}-{end}/{size}")
            self.send_header("Content-Length", str(length))
            self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
            self.end_headers()
            if self.command == "HEAD":
                return None
            fh = open(path, "rb")
            fh.seek(start)
            return _RangedFile(fh, length)

        wants_gzip = (
            ext in _GZIP_EXT
            and "gzip" in (self.headers.get("Accept-Encoding") or "").lower()
        )
        if wants_gzip and fs.st_size < 25_000_000:
            payload = _gzip_bytes(path, fs.st_mtime)
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Encoding", "gzip")
            self.send_header("Content-Length", str(len(payload)))
            self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
            self.send_header("Vary", "Accept-Encoding")
            if ext == ".glb":
                self.send_header("Accept-Ranges", "bytes")
            self.end_headers()
            if self.command == "HEAD":
                return None
            from io import BytesIO

            return BytesIO(payload)

        if ext == ".glb":
            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Accept-Ranges", "bytes")
            self.send_header("Content-Length", str(fs.st_size))
            self.send_header("Last-Modified", self.date_time_string(fs.st_mtime))
            self.end_headers()
            if self.command == "HEAD":
                return None
            return open(path, "rb")

        return super().send_head()

    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.log_date_time_string(), fmt % args))


class Server(http.server.ThreadingHTTPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    if not ROOT.is_dir():
        raise SystemExit(f"missing {ROOT} — run flutter build web")
    _ensure_glb_symlink()
    os.chdir(ROOT)
    glb_count = len(list((ROOT / "assets" / "assets" / "models").glob("*.glb")))
    print(f"Apex web {ROOT} → http://127.0.0.1:{PORT} · {glb_count} GLB")
    Server(("127.0.0.1", PORT), Handler).serve_forever()
