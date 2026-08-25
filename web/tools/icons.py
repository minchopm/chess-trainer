#!/usr/bin/env python3
"""Cut the app icon down to the sizes a browser asks for.

Two crops, not one, and that is the whole point of this file.

At 180 pixels and up the icon is the photograph as shot: a pawn standing on a
lit board, with the board visible enough to say what the app is about. At 16
pixels — which is where a browser tab actually draws it — the board is four
dark smudges and the pawn is eleven pixels tall. Scaling the same image down
that far produces a dark square with a pale fleck in it, which is not an icon,
it is a stain.

So the small sizes get their own crop: the head and the brass collar, filling
the frame. Same object, same photograph, still recognisably this product, and
legible at the size it is drawn.

The source is the square artwork in the .icon bundle rather than the exported
iOS icon. The export has Apple's rounded corners cut out of it and its blue
gradient composited over it, and both are wrong here: iOS applies its own mask
(so a pre-rounded icon gets rounded twice) and the blue fights every warm thing
on the site.

    python3 tools/icons.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "public"
SOURCE = Path(
    os.environ.get(
        "BRASSPAWN_ICON",
        Path.home() / "Desktop/brasspawnAppicon-iOS-Default-1024x1024@1x.png",
    )
)
# The iOS target, in the same repository. One asset, one command, both places:
# the app icon and the favicon drifting apart is exactly the sort of thing
# nobody notices until somebody screenshots them side by side.
IOS_ICON = ROOT.parent / "ios/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

# The social card. 1200x630 is what every platform crops to, so the picture is
# cut to that shape here rather than left square for them to cut badly: handed a
# square, they take a band out of the middle and the piece loses its head and
# its base.
OG = {"width": 1200, "height": 630, "top": 0.16}

# The whole photograph, for anywhere there is room for it.
LARGE = {"icon-180.png": 180, "icon-192.png": 192, "icon-512.png": 512}
# The head, for anywhere there is not.
SMALL = (16, 32, 48)


# Where to cut for the small sizes, as fractions of the master's side.
#
# Measured, not guessed: the ivory of the piece is the only thing in the frame
# that is both bright and unsaturated, so isolating it by hue puts the piece at
# x 396-616 and its top at y 168 in the master. These are those numbers,
# written down.
#
# They are constants rather than a detector because the detector kept finding
# the board. Lit walnut is as bright as ivory and a handful of stray highlights
# at the frame edge are enough to blow the bounding box out to the full width —
# which produces a crop that is wrong in a way nobody can see in a sixteen-pixel
# PNG. A constant that is checked against the source is safer than a
# measurement that can quietly miss.
HEAD = {"x": 0.232, "y": 0.141, "side": 0.524}


def pawn_box(im: Image.Image) -> tuple[int, int, int, int]:
    """The head, the collar and the flare of the body.

    Tried tighter — head and collar alone — and at sixteen pixels it reads as a
    knob on a ring. It is the flare below the collar that makes the silhouette
    a pawn rather than a finial, so the crop has to include it.
    """
    side = round(im.width * HEAD["side"])
    x0 = round(im.width * HEAD["x"])
    y0 = round(im.height * HEAD["y"])
    return (x0, y0, x0 + side, y0 + side)


def square_master(im: Image.Image) -> Image.Image:
    """An opaque square, whatever shape the source arrived in.

    The icon is exported for iOS, which means its corners are already cut to
    Apple's squircle and the alpha outside it is zero. That is wrong twice
    over: iOS applies its own mask, so a pre-rounded icon is rounded twice, and
    App Store validation rejects an icon with an alpha channel at all.

    Fabricating the missing corners — compositing over an enlarged copy of the
    picture — leaves a visible arc where the source's own edge shading stops.
    So instead this takes the largest centred square that is entirely inside
    the opaque region and scales it back up. On this icon that is 868 of 1024,
    an eighteen percent enlargement of a photographic render, which is
    invisible, and it costs the outer eight percent of a frame that is only
    board.
    """
    if im.mode not in ("RGBA", "LA"):
        return im.convert("RGB")

    alpha = im.convert("RGBA").split()[3]
    n = im.width

    def clear(side: int) -> bool:
        x0, x1 = (n - side) // 2, (n - side) // 2 + side - 1
        return all(
            alpha.getpixel(p) > 250
            for t in range(x0, x1 + 1, 4)
            for p in ((t, x0), (t, x1), (x0, t), (x1, t))
        )

    if clear(n):
        return im.convert("RGB")

    low, high = n // 4, n
    while low < high:
        mid = (low + high + 1) // 2
        if clear(mid):
            low = mid
        else:
            high = mid - 1

    if low < n * 0.7:
        raise SystemExit(f"icons: only {low}px of {n} is opaque — that is too much to throw away")

    edge = (n - low) // 2
    print(f"  master           squared by inscribing {low}px of {n} and scaling back up")
    return im.convert("RGB").crop((edge, edge, edge + low, edge + low)).resize(
        (n, n), Image.LANCZOS
    )


def main() -> int:
    if not SOURCE.is_file():
        print(f"icons: no source at {SOURCE}", file=sys.stderr)
        print("set BRASSPAWN_ICON to the square master", file=sys.stderr)
        return 1

    source = Image.open(SOURCE)
    if source.width != source.height:
        print(f"icons: the source is {source.size}, not square", file=sys.stderr)
        return 1
    if source.width < 1024:
        print(f"icons: the source is only {source.width}px", file=sys.stderr)
        return 1
    master = square_master(source)

    for name, size in LARGE.items():
        master.resize((size, size), Image.LANCZOS).save(OUT / name, optimize=True)
        print(f"  {name:16} {size}x{size}  (the whole photograph)")

    head = master.crop(pawn_box(master))
    smalls = []
    for size in SMALL:
        thumb = head.resize((size, size), Image.LANCZOS)
        thumb.save(OUT / f"favicon-{size}.png", optimize=True)
        smalls.append(thumb)
        print(f"  favicon-{size}.png    {size}x{size}  (the head)")

    # The card, cut from the same photograph. No type on it: the platforms draw
    # the title and the description themselves, from the tags in the page, and
    # a picture that repeats them is a picture saying the same thing twice.
    band = round(master.width * OG["height"] / OG["width"])
    top = round(master.height * OG["top"])
    card = master.crop((0, top, master.width, top + band))
    # JPEG, not PNG. This is a photograph: as a PNG it is six hundred kilobytes
    # of losslessly-stored film grain, and every platform that fetches it for a
    # preview pays for that. At quality 86 it is a fifth of the size and nobody
    # can see the difference in a feed.
    card.resize((OG["width"], OG["height"]), Image.LANCZOS).save(
        OUT / "og.jpg", quality=86, optimize=True, progressive=True
    )
    size = (OUT / "og.jpg").stat().st_size
    print(f'  og.jpg           {OG["width"]}x{OG["height"]}  ({size // 1024} kB, the card)')

    stale_card = OUT / "og.png"
    if stale_card.exists():
        stale_card.unlink()
        print("  og.png           removed — it was a prototype, and a PNG of a photograph")

    # One .ico holding all three: it is what a browser reaches for when it
    # guesses /favicon.ico without reading the page, and what several search
    # engines still index.
    smalls[-1].save(OUT / "favicon.ico", sizes=[(s, s) for s in SMALL])
    print(f"  favicon.ico      {', '.join(f'{s}x{s}' for s in SMALL)}")

    # The old vector pawn would win over every PNG in Chrome and Firefox, which
    # both prefer an SVG icon when one is offered, so the new one would never
    # appear. It goes.
    # The app's own icon, from the same master. Flat, square and opaque: the
    # asset catalogue takes a 1024 and App Store validation rejects alpha.
    if IOS_ICON.parent.is_dir():
        master.save(IOS_ICON, optimize=True)
        print(f"  {IOS_ICON.name:16} 1024x1024  -> {IOS_ICON.parent.name}")
    else:
        print(f"  (no iOS asset catalogue at {IOS_ICON.parent})", file=sys.stderr)

    stale = OUT / "favicon.svg"
    if stale.exists():
        stale.unlink()
        print("  favicon.svg      removed — an SVG icon outranks these")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
