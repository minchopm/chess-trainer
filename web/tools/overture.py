#!/usr/bin/env python3
"""Shoot the hero's opening film.

    python3 tools/overture.py

The hero shows this while three.js is on its way. It is not a video of
something like the scene — it is the scene, rendered frame by frame through
the `__film` route, so that when three.js finally arrives the live scene can
be wound forward to whatever second the film reached and take over mid-shot.
The reader should not be able to say when it happened.

Which is also why the frames come back one HTTP request at a time rather than
out of a screen recorder. Recording a canvas gives frames spaced by however
long each one took to draw, and a film whose seconds are not seconds cannot be
seeked into. One POST per frame is slow — a couple of minutes — and exact.

It writes two shapes, because the hero's camera widens below 0.9 aspect and
one film cannot serve both, in two codecs, because AV1 is a third of the size
and not everyone can play it:

    overture-{wide,tall}.{webm,mp4}
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "public" / "overture"
PORT = int(os.environ.get("PORT", "4407"))
CATCH = int(os.environ.get("CATCH_PORT", "4408"))
CHROME = os.environ.get(
    "CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
)


def cyan(message: str) -> None:
    print(f"\033[36m▸\033[0m {message}", flush=True)


def fail(message: str) -> None:
    sys.exit(f"\033[31m✗\033[0m {message}")


def constant(name: str) -> float:
    """Read one of the film's numbers out of the scene that defines it.

    The frame rate is shared: it is the rate this encodes at and the step the
    live scene winds itself forward by when it takes over mid-shot. Two copies
    of that number is one copy too many — the day they disagree, the handover
    lands on the wrong frame and nothing here says why.
    """
    source = (ROOT / "src/app/three/title-sequence.ts").read_text()
    found = re.search(rf"export const {name} = ([\d.]+);", source)
    if not found:
        fail(f"could not find {name} in title-sequence.ts")
    return float(found.group(1))


FPS = int(constant("FILM_FPS"))
SECONDS = float(os.environ.get("FILM_SECONDS", "") or constant("FILM_SECONDS"))

# Wider than the screen, and that is the whole of it.
#
# The scene's camera holds a fixed *vertical* angle and widens sideways as the
# window does. `object-fit: cover` only agrees with that when the film is the
# wider of the two: then it scales to the height, keeps the whole vertical
# frame, and loses a strip off each side — which is precisely what the camera
# does. The other way round it scales to the width and crops top and bottom,
# and the board sits a tenth larger in the film than in the scene that takes
# over from it. A tenth is not subtle; it is a zoom.
#
# So: two to one for the landscape film, which is wider than any ordinary
# window, and a shade under nine to ten for the portrait one. A shade under,
# because the camera changes to the wider lens at an aspect *below* 0.9 — a
# portrait film shot at exactly 0.9 is taken with the landscape lens and shows
# a different amount of board than the phone it is covering for.
#
# Multiples of eight, which is what the encoders want, and no larger than they
# have to be — the film is stretched over the hero for a second or two, under a
# vignette and a title, and every kilobyte here is one not spent on the three.js
# it covers for.
SHAPES = {"wide": (880, 440), "tall": (584, 656)}


class Catcher(BaseHTTPRequestHandler):
    """Takes one PNG per request and drops it in `into`, named by the URL."""

    into: Path
    done = threading.Event()
    count = 0

    def log_message(self, *_args: object) -> None:  # noqa: D102 — quiet
        pass

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")

    def do_OPTIONS(self) -> None:  # noqa: N802 — the server's spelling
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_POST(self) -> None:  # noqa: N802 — the server's spelling
        name = self.path.rsplit("/", 1)[-1]
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)
        if name == "done":
            Catcher.done.set()
        else:
            (Catcher.into / f"{name}.png").write_bytes(body)
            Catcher.count += 1
            if Catcher.count % 30 == 0:
                cyan(f"  {Catcher.count} frames")
        self.send_response(204)
        self._cors()
        self.end_headers()


def serve_site(log: Path) -> subprocess.Popen[bytes]:
    cyan(f"starting the site on :{PORT}")
    server = subprocess.Popen(
        ["npx", "ng", "serve", "--port", str(PORT), "--hmr=false"],
        cwd=ROOT,
        stdout=log.open("wb"),
        stderr=subprocess.STDOUT,
    )
    for _ in range(180):
        if server.poll() is not None:
            fail(f"the dev server exited — see {log}")
        try:
            urllib.request.urlopen(f"http://localhost:{PORT}/", timeout=2).read(1)
            return server
        except (urllib.error.URLError, OSError):
            time.sleep(1)
    fail(f"the dev server never came up — see {log}")
    raise SystemExit(1)


def shoot(name: str, size: tuple[int, int], work: Path) -> Path:
    frames = work / name
    frames.mkdir()
    Catcher.into = frames
    Catcher.done = threading.Event()
    Catcher.count = 0

    catcher = ThreadingHTTPServer(("127.0.0.1", CATCH), Catcher)
    thread = threading.Thread(target=catcher.serve_forever, daemon=True)
    thread.start()

    want = round(SECONDS * FPS)
    cyan(f"shooting {name}: {want} frames at {size[0]}×{size[1]}")
    url = (
        f"http://localhost:{PORT}/__film"
        f"?w={size[0]}&h={size[1]}&seconds={SECONDS}"
        f"&post=http://127.0.0.1:{CATCH}"
    )
    chrome = subprocess.Popen(
        [
            CHROME,
            "--headless=new",
            # Software WebGL: headless has no GPU, and without these the page
            # gets a context that fails to create and draws nothing at all.
            "--use-gl=angle",
            "--use-angle=swiftshader",
            "--enable-unsafe-swiftshader",
            "--hide-scrollbars",
            f"--window-size={size[0]},{size[1]}",
            "--user-data-dir=" + str(work / f"chrome-{name}"),
            url,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        # Generous: SwiftShader draws a bloomed 960×600 frame in about a second.
        if not Catcher.done.wait(timeout=20 * 60):
            fail(f"{name} stalled at {Catcher.count} of {want} frames")
    finally:
        chrome.terminate()
        catcher.shutdown()
        catcher.server_close()

    got = len(list(frames.glob("*.png")))
    if got != want:
        fail(f"{name} came back with {got} frames, not {want}")
    return frames


def encode(name: str, frames: Path) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    common = ["ffmpeg", "-y", "-framerate", str(FPS), "-i", str(frames / "%05d.png")]

    # AV1 first, because it is the one most people will actually be served and
    # it is worth about three times the compression of H.264 on a shot this
    # dark. `-crf 40` is high for video and right for this: the film is behind
    # a vignette, under a title, and on screen for a second.
    subprocess.run(
        common
        + [
            "-c:v", "libsvtav1", "-crf", "46", "-preset", "4",
            "-pix_fmt", "yuv420p", "-an",
            str(OUT / f"overture-{name}.webm"),
        ],
        check=True,
        capture_output=True,
    )
    # And H.264 for everything that cannot play it. `faststart` puts the index
    # at the front so playback can begin on the first packets rather than after
    # the whole file.
    subprocess.run(
        common
        + [
            "-c:v", "libx264", "-crf", "32", "-preset", "slow",
            "-profile:v", "main", "-pix_fmt", "yuv420p", "-an",
            "-movflags", "+faststart",
            str(OUT / f"overture-{name}.mp4"),
        ],
        check=True,
        capture_output=True,
    )
    for suffix in ("webm", "mp4"):
        path = OUT / f"overture-{name}.{suffix}"
        cyan(f"  wrote {path.name} — {path.stat().st_size / 1024:.0f} kB")


def main() -> None:
    if not Path(CHROME).exists():
        fail(f"no Chrome at {CHROME} — set CHROME")
    if shutil.which("ffmpeg") is None:
        fail("ffmpeg missing — brew install ffmpeg")

    work = Path(tempfile.mkdtemp())
    site = serve_site(work / "serve.log")
    try:
        for name, size in SHAPES.items():
            encode(name, shoot(name, size, work))
    finally:
        site.terminate()
        site.wait(timeout=20)
        shutil.rmtree(work, ignore_errors=True)
    cyan(f"done — {SECONDS:g}s at {FPS}fps in public/overture")


if __name__ == "__main__":
    main()
