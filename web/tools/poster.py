#!/usr/bin/env python3
"""Re-render the hero's poster from the live scene.

    python3 tools/poster.py

The stage is blank for as long as it takes to fetch three.js and build the
scene, and a blank stage on the front page reads as a broken site rather than
as a loading one. What covers it is a still — and the still has to match frame
zero exactly, or the swap to the canvas shows as a jump.

Exactly is why this shoots the real scene through the `__poster` route rather
than exporting a picture by hand: same camera keyframe, same lights, same
pieces on the same squares. Run it whenever the pieces, the board or the
opening camera move.

It writes eight files, because the camera widens below 0.9 aspect and one
poster cannot serve both shapes:

    hero-{wide,tall}{,@2x}.{avif,webp}
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "public" / "poster"
PORT = int(os.environ.get("PORT", "4407"))
CHROME = os.environ.get(
    "CHROME", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
)

# The 2x sizes are what is rendered; the 1x files are resampled down from them
# rather than shot small, so their edges are averaged rather than aliased.
#
# Two to one and nine to ten, which are not the shapes of any screen — they are
# the shapes that make `object-fit: cover` agree with the camera. The camera
# holds a fixed vertical angle and widens sideways as the window does, so a
# still that is wider than the window scales to its height, keeps the whole
# vertical frame and loses a strip off each side, which is exactly what the
# camera would have done. A still that is narrower crops top and bottom
# instead, and the board sits a tenth larger in it than in the scene that fades
# in over it.#
# Just under nine to ten, not exactly: the camera changes to the wider lens at
# an aspect *below* 0.9, so a portrait file shot at exactly 0.9 is taken with
# the landscape lens and shows a different amount of board than the phone it is
# covering for.
SHAPES = {"wide": (1600, 800), "tall": (712, 800)}


def cyan(message: str) -> None:
    print(f"\033[36m▸\033[0m {message}", flush=True)


def fail(message: str) -> None:
    sys.exit(f"\033[31m✗\033[0m {message}")


def serve(log: Path) -> subprocess.Popen[bytes]:
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
    raise SystemExit(1)  # unreachable, for the type checker


def shoot(name: str, size: tuple[int, int], into: Path) -> Path:
    """Screenshot the poster route at one window size.

    `--virtual-time-budget` is what waits for the scene rather than a sleep:
    the page renders a single frame and then does nothing, so there is no load
    event or network quiet to hang the screenshot on, and a fixed sleep is
    either too short on a cold cache or wasted every other time.
    """
    cyan(f"shooting {name} at {size[0]}×{size[1]}")
    shot = into / f"{name}.png"
    subprocess.run(
        [
            CHROME,
            "--headless=new",
            # Headless has no GPU, and without these three it hands the page a
            # context that fails to create — which is not an error the page can
            # report, so the screenshot comes back as the background colour and
            # nothing else. SwiftShader draws it on the CPU instead: slower
            # than a real GPU and identical in output, which is the trade one
            # wants for a still that has to match the live scene exactly.
            "--use-gl=angle",
            "--use-angle=swiftshader",
            "--enable-unsafe-swiftshader",
            "--hide-scrollbars",
            f"--window-size={size[0]},{size[1]}",
            "--virtual-time-budget=20000",
            f"--screenshot={shot}",
            f"http://localhost:{PORT}/__poster",
        ],
        cwd=into,
        capture_output=True,
        check=False,
    )
    if not shot.exists() or shot.stat().st_size == 0:
        fail(f"{name} came out empty — is Chrome at {CHROME}?")
    return shot


def write(image: Image.Image, stem: Path) -> None:
    image.save(f"{stem}.webp", quality=82, method=6)
    image.save(f"{stem}.avif", quality=58)
    cyan(f"  wrote {stem.name}.{{webp,avif}}")


def main() -> None:
    if not Path(CHROME).exists():
        fail(f"no Chrome at {CHROME} — set CHROME")
    OUT.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp())
    server = serve(work / "serve.log")
    try:
        for name, size in SHAPES.items():
            full = Image.open(shoot(name, size, work)).convert("RGB")
            # A flat frame is what a failed WebGL context looks like: the page's
            # own background and nothing on top of it. Chrome exits 0 and writes
            # a perfectly valid PNG, so nothing else here would notice, and the
            # site would ship a black rectangle where the board should be.
            low, high = full.convert("L").getextrema()
            if high - low < 40:
                fail(f"{name} is flat ({low}..{high}) — the scene did not draw")
            write(full, OUT / f"hero-{name}@2x")
            half = full.resize((size[0] // 2, size[1] // 2), Image.LANCZOS)
            write(half, OUT / f"hero-{name}")
    finally:
        server.terminate()
        server.wait(timeout=20)
        shutil.rmtree(work, ignore_errors=True)
    cyan(f"done — {len(list(OUT.iterdir()))} files in public/poster")


if __name__ == "__main__":
    main()
