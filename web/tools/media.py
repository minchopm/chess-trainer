#!/usr/bin/env python3
"""Turn the capture folder into something a website can serve.

The source material is a 5.7 GB pile of simulator captures: three 24-second
screen recordings per language per device, twice over — once clean and once
with the narrator composited into the corner — plus ten unedited PNGs per
language. None of it can go on a website as it stands.

What comes out is about a twentieth of the size, and is laid out by URL rather
than by how it was produced, so a page can build a path from a locale slug and
a clip id without a lookup table:

    media/video/<device>/<slug>/<clip>.mp4          with the narrator
    media/video/<device>/<slug>/<clip>-silent.mp4   without, and no audio track
    media/video/<device>/<slug>/<clip>.jpg          the poster
    media/shot/<device>/<slug>/<view>-<width>.avif
    media/shot/<device>/<slug>/<view>-<width>.webp

`media/` deliberately sits outside `public/`. Angular copies `public/**` into
every build, and putting a third of a gigabyte through that would slow down a
build that has nothing to do with it; deploy.sh syncs `media/` to the bucket
separately, with its own cache headers.

Everything is idempotent: an output newer than its input is left alone, so
adding one language re-encodes one language.

    python3 tools/media.py                      # everything that is stale
    python3 tools/media.py --locales de-DE,ja   # just these
    python3 tools/media.py --only shots         # or: video
    python3 tools/media.py --force
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
SOURCE = Path(os.environ.get("BRASSPAWN_CAPTURES", Path.home() / "Desktop/BrassPawn"))
OUT = ROOT / "media"

# Source suffix -> the id the site uses. The site names things after what they
# show; the capture rig named them after the order they were shot in.
CLIPS = {"demo": "play", "demoTactics": "tactics", "demoWatch": "watch"}

# Source filename -> the id the storefront copy is keyed by, so a caption and
# the picture it captions are found by the same word.
VIEWS = {
    "iphone": {
        "01-menu": "title",
        "02-playSetup": "free",
        "03-playCoached": "coached",
        "04-playMistake": "mistake",
        "05-playValues": "values",
        "06-boardEngines": "engines",
        "07-watchList": "library",
    },
    "ipad": {
        "01-menu": "title",
        "02-playMistake": "mistake",
        "03-playValues": "values",
    },
}

# The tall edge of the encoded video, and the widths each screenshot is offered
# at. Both devices are shown inside a drawn bezel roughly 380 CSS px (iPhone)
# and 700 CSS px (iPad) wide, so these carry a comfortable 2x and no more.
VIDEO_HEIGHT = {"iphone": 1440, "ipad": 1280}
SHOT_WIDTHS = {"iphone": (420, 840), "ipad": (640, 1280)}

# 28 rather than the 32 that still looked clean on a test frame. This is the
# one part of the site whose whole job is to be looked at closely, and the
# difference between the two is 200 kB.
CRF = 28


def locales() -> list[dict]:
    return json.loads((HERE / "locales.json").read_text())["locales"]


def stale(dest: Path, src: Path, force: bool) -> bool:
    return force or not dest.exists() or dest.stat().st_mtime < src.stat().st_mtime


def run(cmd: list[str]) -> None:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"{cmd[0]} failed\n{' '.join(cmd)}\n{proc.stderr[-2000:]}")


def encode_video(src: Path, dest: Path, height: int, narrated: bool) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(".part.mp4")
    audio = ["-c:a", "aac", "-b:a", "64k", "-ac", "1"] if narrated else ["-an"]
    run(
        # fmt: off
        [
            "ffmpeg", "-v", "error", "-y", "-i", str(src),
            "-vf", f"scale=-2:{height}",
            "-c:v", "libx264", "-profile:v", "high", "-level", "4.0",
            "-crf", str(CRF), "-preset", "medium", "-pix_fmt", "yuv420p",
            # A keyframe every two seconds: enough that scrubbing lands where
            # it was asked to, not so many that the file grows for nothing.
            "-g", "48",
            *audio,
            "-movflags", "+faststart",
            str(tmp),
        ]
        # fmt: on
    )
    tmp.replace(dest)


def poster(src: Path, dest: Path, height: int) -> None:
    """A still for the video to sit under until it is asked to play.

    Taken at 1.2 s rather than at 0. The clips open on a fade from black, and a
    poster of black tells a visitor nothing about whether the thing is broken.

    Taken from the silent cut, because that is the one that plays first. A
    poster lifted from the narrated cut shows a face in the corner that
    disappears the moment the loop starts, which reads as a glitch.
    """
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(".part.jpg")
    run(
        # fmt: off
        [
            "ffmpeg", "-v", "error", "-y", "-ss", "1.2", "-i", str(src),
            "-frames:v", "1", "-vf", f"scale=-2:{height}",
            "-q:v", "5", str(tmp),
        ]
        # fmt: on
    )
    tmp.replace(dest)


def encode_shot(src: Path, stem: Path, widths: tuple[int, ...]) -> None:
    from PIL import Image

    stem.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(src) as im:
        im = im.convert("RGB")
        for width in widths:
            height = round(im.height * width / im.width)
            small = im.resize((width, height), Image.LANCZOS)
            small.save(f"{stem}-{width}.avif", quality=62)
            small.save(f"{stem}-{width}.webp", quality=80, method=6)


def jobs(only: str, wanted: set[str] | None, force: bool) -> list[tuple]:
    todo: list[tuple] = []
    for loc in locales():
        tag, slug = loc["tag"], loc["slug"]
        if wanted and tag not in wanted:
            continue

        for device in ("iphone", "ipad"):
            if only in ("all", "video"):
                for suffix, clip in CLIPS.items():
                    narrated = SOURCE / device / "with-narrator" / f"{tag}-{suffix}.mp4"
                    silent = SOURCE / device / "videos" / f"{tag}-{suffix}.mp4"
                    out = OUT / "video" / device / slug
                    height = VIDEO_HEIGHT[device]

                    if narrated.exists() and stale(out / f"{clip}.mp4", narrated, force):
                        todo.append((encode_video, narrated, out / f"{clip}.mp4", height, True))

                    if silent.exists():
                        if stale(out / f"{clip}-silent.mp4", silent, force):
                            todo.append(
                                (encode_video, silent, out / f"{clip}-silent.mp4", height, False)
                            )
                        if stale(out / f"{clip}.jpg", silent, force):
                            todo.append((poster, silent, out / f"{clip}.jpg", height))

            if only in ("all", "shots"):
                for name, view in VIEWS[device].items():
                    src = SOURCE / device / "screenshots" / tag / f"{name}.png"
                    if not src.exists():
                        continue
                    stem = OUT / "shot" / device / slug / view
                    widths = SHOT_WIDTHS[device]
                    if stale(Path(f"{stem}-{widths[-1]}.avif"), src, force):
                        todo.append((encode_shot, src, stem, widths))
    return todo


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--locales", help="comma-separated BCP-47 tags; default all")
    ap.add_argument("--only", choices=("all", "video", "shots"), default="all")
    ap.add_argument("--jobs", type=int, default=max(2, (os.cpu_count() or 4) // 2))
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    if not SOURCE.is_dir():
        print(f"captures not found: {SOURCE}", file=sys.stderr)
        print("set BRASSPAWN_CAPTURES to where they live", file=sys.stderr)
        return 1
    if not shutil.which("ffmpeg"):
        print("ffmpeg is not on PATH", file=sys.stderr)
        return 1

    wanted = set(args.locales.split(",")) if args.locales else None
    todo = jobs(args.only, wanted, args.force)
    if not todo:
        print("nothing to do — every output is newer than its input")
        return 0

    print(f"{len(todo)} files to write, {args.jobs} at a time")
    done = failed = 0
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futures = {pool.submit(job[0], *job[1:]): job for job in todo}
        for future in futures:
            pass
        for future, job in futures.items():
            try:
                future.result()
            except Exception as exc:  # noqa: BLE001 — one bad file must not stop the run
                failed += 1
                print(f"  FAILED {job[2]}: {exc}", file=sys.stderr)
            else:
                done += 1
                if done % 25 == 0:
                    print(f"  {done}/{len(todo)}")

    size = sum(f.stat().st_size for f in OUT.rglob("*") if f.is_file())
    print(f"{done} written, {failed} failed — media/ is now {size / 1e6:.0f} MB")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
