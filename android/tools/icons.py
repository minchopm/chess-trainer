#!/usr/bin/env python3
"""Launcher icons from the iOS app icon. Run from android/: python3 tools/icons.py

The adaptive icon is the photograph itself as the background layer, drawn at
84% of the 108 dp canvas over its own darkened edge: the launcher shows the
middle two thirds of that canvas, which is then the photograph less a thin
border — the whole pawn, whatever shape the mask is.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

root = Path(__file__).resolve().parent.parent
source = Image.open(root.parent / "ios/Resources/AppIcon.icon/Assets/brasspawnAppicon-iOS-Default-1024x1024@1x.png").convert("RGB")
res = root / "app/src/main/res"
densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

for name, scale in densities.items():
    folder = res / f"mipmap-{name}"
    folder.mkdir(parents=True, exist_ok=True)
    size = round(48 * scale)
    legacy = source.resize((size, size), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (size * 4, size * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size * 4 - 1, size * 4 - 1), radius=size * 4 * 0.2, fill=255)
    legacy.putalpha(mask.resize((size, size), Image.LANCZOS))
    legacy.save(folder / "ic_launcher.png")

    canvas = round(108 * scale)
    inner = round(canvas * 0.84)
    # The photograph, blurred and darkened, fills what the smaller copy leaves.
    layer = source.resize((canvas, canvas), Image.LANCZOS).filter(ImageFilter.GaussianBlur(canvas / 12))
    layer = Image.blend(layer, Image.new("RGB", layer.size, (5, 6, 10)), 0.55)
    offset = (canvas - inner) // 2
    layer.paste(source.resize((inner, inner), Image.LANCZOS), (offset, offset))
    layer.save(folder / "ic_launcher_background.png")
print("icons written")
