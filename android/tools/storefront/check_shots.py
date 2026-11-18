#!/usr/bin/env python3
"""Validates raw storefront captures: every expected locale & scene exists, is non-empty,
has exact pixel dimensions (1280x2856 for phone, 2560x1600 for tablet), and has an unclipped
status-bar clock on tablet.

Works with Pillow when available, or falls back to a pure-stdlib PNG reader (`struct` + `zlib`)
so it runs cleanly on remote Macs without third-party packages.

Usage:
    check_shots.py <shots-dir> [locale ...]
"""
from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    Image = None

SCENES = [
    "01-menu",
    "02-playMistake",
    "03-tactics",
    "04-online",
    "05-positional",
    "06-playCoached",
    "07-playSetup",
]

DEFAULT_LOCALES = [
    "ar-SA", "bg", "bn-BD", "ca", "cs", "da", "de-DE", "el", "en-US", "es-ES",
    "es-MX", "fi", "fr-CA", "fr-FR", "gu-IN", "he", "hi", "hr", "hu", "id",
    "it", "ja", "kk", "kn-IN", "ko", "ml-IN", "mr-IN", "ms", "nb", "nl-NL",
    "or-IN", "pa-IN", "pl", "pt-BR", "pt-PT", "ro", "ru", "sk", "sl-SI", "sv",
    "ta-IN", "te-IN", "th", "tr", "uk", "ur-PK", "vi", "zh-Hans", "zh-Hant",
]

SPEC = {
    "phone": ((1280, 2856), (150, 40, 400, 140), 0),
    "tablet": ((2560, 1600), (20, 0, 260, 75), 14),
}


def inspect_png_stdlib(path: Path, box: tuple[int, int, int, int], need_clock: bool) -> tuple[tuple[int, int], int]:
    data = path.read_bytes()
    if len(data) < 33 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    pos = 8
    width = height = bit_depth = color_type = 0
    idat_parts: list[bytes] = []
    saw_iend = False
    while pos + 8 <= len(data):
        length, ctype = struct.unpack(">I4s", data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + length]
        if len(chunk) != length:
            raise ValueError("truncated PNG chunk")
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _, _, _ = struct.unpack(">IIBBBBB", chunk)
        elif ctype == b"IDAT":
            if need_clock:
                idat_parts.append(chunk)
        elif ctype == b"IEND":
            saw_iend = True
            break
    if not saw_iend:
        raise ValueError("missing IEND")
    if not need_clock:
        return (width, height), 0

    bpp = {0: 1, 2: 3, 4: 2, 6: 4}.get(color_type, 4)
    stride = 1 + width * bpp
    x0, y0, x1, y1 = box
    decomp = zlib.decompressobj()
    buf = bytearray()
    for part in idat_parts:
        buf.extend(decomp.decompress(part))
        if len(buf) >= y1 * stride:
            break
    prev = bytearray(width * bpp)
    bright_rows: list[int] = []
    for y in range(min(y1, height)):
        row_start = y * stride
        ftype = buf[row_start]
        raw = bytearray(buf[row_start + 1:row_start + stride])
        if ftype == 1:
            for i in range(bpp, len(raw)):
                raw[i] = (raw[i] + raw[i - bpp]) & 0xFF
        elif ftype == 2:
            for i in range(len(raw)):
                raw[i] = (raw[i] + prev[i]) & 0xFF
        elif ftype == 3:
            for i in range(len(raw)):
                left = raw[i - bpp] if i >= bpp else 0
                raw[i] = (raw[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:
            for i in range(len(raw)):
                a = raw[i - bpp] if i >= bpp else 0
                b = prev[i]
                c = prev[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                raw[i] = (raw[i] + pr) & 0xFF
        prev = raw
        if y >= y0:
            for x in range(x0, min(x1, width)):
                off = x * bpp
                lum = raw[off] if bpp < 3 else (raw[off] * 77 + raw[off + 1] * 150 + raw[off + 2] * 29) >> 8
                if lum > 180:
                    bright_rows.append(y)
                    break
    ch = (bright_rows[-1] - bright_rows[0] + 1) if bright_rows else 0
    return (width, height), ch


def inspect_png(path: Path, box: tuple[int, int, int, int], need_clock: bool) -> tuple[tuple[int, int], int]:
    if Image is not None:
        with Image.open(path) as im:
            size = im.size
            im.verify()
        if not need_clock:
            return size, 0
        with Image.open(path) as im:
            crop = im.convert("L").crop(box)
            w, h = crop.size
            px = crop.load()
            rows = [y for y in range(h) if any(px[x, y] > 180 for x in range(w))]
            return size, (rows[-1] - rows[0] + 1 if rows else 0)
    return inspect_png_stdlib(path, box, need_clock)


def main() -> None:
    shots = Path(sys.argv[1])
    locales = sys.argv[2:] or DEFAULT_LOCALES
    redo: dict[str, set[str]] = {}
    checked = 0

    for kind, (size, box, minimum) in SPEC.items():
        kind_dir = shots / kind
        if not kind_dir.is_dir():
            redo.setdefault(kind, set()).update(locales)
            print(f"missing directory: {kind_dir}", file=sys.stderr)
            continue
        for locale in locales:
            locale_dir = kind_dir / locale
            for scene in SCENES:
                f = locale_dir / f"{scene}.png"
                problem = None
                if not f.exists() or f.stat().st_size == 0:
                    problem = "missing or empty"
                else:
                    try:
                        actual_size, ch = inspect_png(f, box, minimum > 0)
                    except Exception as exc:
                        problem = f"corrupt ({exc})"
                        actual_size, ch = (0, 0), 0
                    if not problem and actual_size != size:
                        problem = f"size {actual_size} != {size}"
                    elif not problem and minimum and ch < minimum:
                        problem = f"status bar clipped ({ch} px)"
                if problem:
                    redo.setdefault(kind, set()).add(locale)
                    print(f"{kind}/{locale}/{scene}: {problem}", file=sys.stderr)
                else:
                    checked += 1

    if redo:
        for kind, bad in sorted(redo.items()):
            print(f"{kind}: {','.join(sorted(bad))}")
        sys.exit(1)

    print(f"OK: verified {checked} raw PNGs ({len(locales)} locales x {len(SCENES)} scenes x 2 devices)")


if __name__ == "__main__":
    main()
