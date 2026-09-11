import tempfile
import threading
import unittest
from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import Request, urlopen

from server import DirectoryHandler


class DirectoryServerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / "public"
        self.root.mkdir()
        handler = partial(DirectoryHandler, directory=str(self.root))
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.start()
        self.addCleanup(self.stop_server)
        self.base = f"http://127.0.0.1:{self.server.server_port}/"

    def stop_server(self):
        self.server.shutdown()
        self.thread.join()
        self.server.server_close()

    def get(self, path=""):
        with urlopen(self.base + path, timeout=5) as response:
            return response.read().decode()

    def test_listing_reflects_file_creation_and_removal(self):
        self.assertIn("This directory is empty.", self.get())
        document = self.root / "hello.html"
        document.write_text("<h1>Hello</h1>")
        self.assertIn('href="hello.html"', self.get())
        document.unlink()
        self.assertNotIn('href="hello.html"', self.get())

    def test_filename_is_escaped_and_link_is_usable(self):
        name = 'a & <b> "quote" #é.html'
        (self.root / name).write_text("<h1>Document</h1>")
        listing = self.get()
        self.assertIn("a &amp; &lt;b&gt;", listing)
        self.assertIn(f'href="{quote(name)}"', listing)
        self.assertEqual(self.get(quote(name)), "<h1>Document</h1>")

    def test_document_and_head_requests(self):
        content = "<h1>Hello</h1>"
        (self.root / "hello.html").write_text(content)
        self.assertEqual(self.get("hello.html"), content)
        request = Request(self.base + "hello.html", method="HEAD")
        with urlopen(request, timeout=5) as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers["Content-Length"], str(len(content)))
            self.assertEqual(response.read(), b"")

    def test_directories_stay_browsable_with_index_files(self):
        nested = self.root / "example"
        nested.mkdir()
        (nested / "index.html").write_text("<h1>Example</h1>")
        listing = self.get("example")
        self.assertIn('href="../"', listing)
        self.assertIn('href="index.html"', listing)
        self.assertEqual(self.get("example/index.html"), "<h1>Example</h1>")

    def test_symlinks_cannot_expose_files_outside_public(self):
        outside = self.root.parent / "private.html"
        outside.write_text("Private document")
        (self.root / "outside.html").symlink_to(outside)
        self.assertNotIn("outside.html", self.get())
        with self.assertRaises(HTTPError) as error:
            self.get("outside.html")
        self.assertEqual(error.exception.code, 403)
        error.exception.close()


if __name__ == "__main__":
    unittest.main()
