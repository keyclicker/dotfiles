#!/usr/bin/env python3
"""Serve a directory of HTML files with a browsable index."""

import argparse
from datetime import UTC, datetime
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO
from pathlib import Path
from urllib.parse import quote, urlsplit

from jinja2 import Environment, FileSystemLoader

TEMPLATES = Environment(
    loader=FileSystemLoader(Path(__file__).parent),
    autoescape=True,
)


class DirectoryHandler(SimpleHTTPRequestHandler):
    def send_head(self):
        root = Path(self.directory)
        path = Path(self.translate_path(self.path))
        if not path.resolve().is_relative_to(root):
            self.send_error(403)
            return None

        # Keep directories browsable even when they contain an index.html.
        if path.is_dir() and urlsplit(self.path).path.endswith("/"):
            return self.list_directory(path)
        return super().send_head()

    def list_directory(self, path):
        root = Path(self.directory)
        directory = Path(path)
        entries = []
        try:
            children = list(directory.iterdir())
        except OSError:
            self.send_error(404)
            return None

        for child in children:
            if not child.resolve().is_relative_to(root):
                continue
            try:
                stat = child.stat()
            except OSError:
                continue
            folder = child.is_dir()
            name = child.name + ("/" if folder else "")
            entries.append(
                {
                    "name": name,
                    "url": quote(name),
                    "folder": folder,
                    "size": "—" if folder else f"{stat.st_size:,} B",
                    "modified": datetime.fromtimestamp(stat.st_mtime, UTC).astimezone(),
                }
            )

        entries.sort(key=lambda entry: (not entry["folder"], entry["name"].casefold()))
        relative = directory.relative_to(root)
        page = (
            TEMPLATES.get_template("index.html")
            .render(
                entries=entries,
                subdirectory="" if relative == Path(".") else relative.as_posix() + "/",
            )
            .encode("utf-8")
        )
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(page)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        return BytesIO(page)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path.home() / "public")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    handler = partial(DirectoryHandler, directory=str(args.directory.resolve()))
    ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
