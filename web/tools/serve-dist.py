#!/usr/bin/env python3
"""Serve dist/ as the bucket would, with media/ alongside it.

Two things a plain `http.server` gets wrong for this site: it has never heard
of `media/`, which is deployed separately, and it does not know that `/de` is
`/de/index.html` — the CloudFront function does that in production, and without
it every localised page is a 404 locally and looks like a routing bug.
"""

from __future__ import annotations

import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist/brass-pawn/browser"
MEDIA = ROOT / "media"


class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path: str) -> str:
        clean = path.split("?", 1)[0].split("#", 1)[0]
        if clean.startswith("/media/"):
            return str(MEDIA / clean[len("/media/") :])

        target = DIST / clean.lstrip("/")
        # What the CloudFront function does: a path with no extension is a page.
        if not target.exists() and not Path(clean).suffix:
            return str(target / "index.html")
        return str(super().translate_path(path))

    def log_message(self, fmt: str, *args) -> None:
        if "404" in (fmt % args):
            sys.stderr.write("%s\n" % (fmt % args))


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 4401
    if not DIST.is_dir():
        sys.exit(f"no build at {DIST} — run npm run build:prod")
    handler = partial(Handler, directory=str(DIST))
    print(f"serving {DIST} (media from {MEDIA}) on http://127.0.0.1:{port}")
    ThreadingHTTPServer(("127.0.0.1", port), handler).serve_forever()
