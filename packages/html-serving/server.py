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
    def __init__(self, *args, allowed_roots=(), **kwargs):
        self.allowed_roots = tuple(Path(root).resolve() for root in allowed_roots)
        super().__init__(*args, **kwargs)

    def is_allowed(self, path):
        """Return whether path resolves inside a configured public root."""
        resolved = path.resolve()
        roots = (Path(self.directory), *self.allowed_roots)
        return any(resolved.is_relative_to(root) for root in roots)

    def send_head(self):
        path = Path(self.translate_path(self.path))
        if not self.is_allowed(path):
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
            if not self.is_allowed(child):
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
                # Relative, so the listing works behind a path prefix.
                root_url="../" * len(relative.parts) or "./",
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
    parser.add_argument("--allow-root", action="append", default=[], type=Path)
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    handler = partial(
        DirectoryHandler,
        allowed_roots=args.allow_root,
        directory=str(args.directory.resolve()),
    )
    ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()
