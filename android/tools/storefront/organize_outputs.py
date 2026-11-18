#!/usr/bin/env python3
"""Organizes raw screenshots and composed storefront JPEGs into:
1. ~/Desktop/BrassPawn/android-{phone,tablet}/screenshots/<locale>/01-menu.png ... 07-playSetup.png
2. ~/Desktop/BrassPawn/storefront/exports/android-{phone,tablet}/<locale>/01-menu.jpg ... 07-playSetup.jpg
3. <repo>/android/play-listing/<play-locale>/images/{phoneScreenshots,sevenInchScreenshots,tenInchScreenshots}/1_title.jpg ... 7_free.jpg
4. Visual contact sheets in ~/Desktop/BrassPawn/storefront/exports/:
   - contact-sheet-en-android-phone.png
   - contact-sheet-bg-android-phone.png
   - contact-sheet-en-android-tablet.png

Uses hardlinks (`os.link`) wherever identical files appear so disk usage stays minimal,
and runs full Google Play Console dimension/format/integrity verification.
"""
from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ANDROID_ROOT = HERE.parents[1]
DESKTOP_BP = Path.home() / "Desktop" / "BrassPawn"

SCENES = [
    ("01-menu", "1_title"),
    ("02-playMistake", "2_mistake"),
    ("03-tactics", "3_tactics"),
    ("04-online", "4_online"),
    ("05-positional", "5_positional"),
    ("06-playCoached", "6_coached"),
    ("07-playSetup", "7_free"),
]

APP_49 = [
    "ar-SA", "bg", "bn-BD", "ca", "cs", "da", "de-DE", "el", "en-US", "es-ES",
    "es-MX", "fi", "fr-CA", "fr-FR", "gu-IN", "he", "hi", "hr", "hu", "id",
    "it", "ja", "kk", "kn-IN", "ko", "ml-IN", "mr-IN", "ms", "nb", "nl-NL",
    "or-IN", "pa-IN", "pl", "pt-BR", "pt-PT", "ro", "ru", "sk", "sl-SI", "sv",
    "ta-IN", "te-IN", "th", "tr", "uk", "ur-PK", "vi", "zh-Hans", "zh-Hant",
]

# Google Play language tags -> play-listing directory names (all 44 from LingoVela + 7 new = 51).
PLAY_LOCALES = {
    "ar": "ar-SA",
    "bg": "bg",
    "bn-BD": "bn-BD",
    "ca": "ca",
    "cs-CZ": "cs",
    "da-DK": "da",
    "de-DE": "de-DE",
    "el-GR": "el",
    "en-AU": "en-AU",
    "en-CA": "en-CA",
    "en-GB": "en-GB",
    "en-US": "en-US",
    "es-ES": "es-ES",
    "es-419": "es-MX",
    "fi-FI": "fi",
    "fr-CA": "fr-CA",
    "fr-FR": "fr-FR",
    "gu": "gu",
    "iw-IL": "he",
    "hi-IN": "hi",
    "hr": "hr",
    "hu-HU": "hu",
    "id": "id",
    "it-IT": "it",
    "ja-JP": "ja",
    "kk": "kk",
    "kn-IN": "kn-IN",
    "ko-KR": "ko",
    "ml-IN": "ml-IN",
    "mr-IN": "mr-IN",
    "ms": "ms",
    "nl-NL": "nl-NL",
    "no-NO": "no",
    "pa": "pa",
    "pl-PL": "pl",
    "pt-BR": "pt-BR",
    "pt-PT": "pt-PT",
    "ro": "ro",
    "ru-RU": "ru",
    "sk": "sk",
    "sl": "sl-SI",
    "sv-SE": "sv",
    "ta-IN": "ta-IN",
    "te-IN": "te-IN",
    "th": "th",
    "tr-TR": "tr",
    "uk": "uk",
    "ur": "ur-PK",
    "vi": "vi",
    "zh-CN": "zh-Hans",
    "zh-TW": "zh-Hant",
}

RAW_ALIASES = {
    "en-AU": "en-US",
    "en-CA": "en-US",
    "en-GB": "en-US",
    "no": "nb",
    "gu": "gu-IN",
    "pa": "pa-IN",
}


def link_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        if os.path.samefile(src, dst):
            return
        dst.unlink()
    try:
        os.link(src, dst)
    except OSError:
        shutil.copy2(src, dst)


def make_phone_contact_sheet(exports_phone_locale: Path, out_png: Path, rtl: bool = False) -> None:
    cards = [Image.open(exports_phone_locale / f"{sc}.jpg").convert("RGB") for sc, _ in SCENES]
    if rtl:
        cards = list(reversed(cards))
    cw, ch = 420, 747
    sep = 3
    total_w = len(cards) * cw + (len(cards) - 1) * sep
    sheet = Image.new("RGB", (total_w, ch), (0, 0, 0))
    for i, card in enumerate(cards):
        resized = card.resize((cw, ch), Image.Resampling.LANCZOS)
        sheet.paste(resized, (i * (cw + sep), 0))
    out_png.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_png, format="PNG", optimize=True)


def make_tablet_contact_sheet(exports_tablet_locale: Path, out_png: Path) -> None:
    cards = [Image.open(exports_tablet_locale / f"{sc}.jpg").convert("RGB") for sc, _ in SCENES]
    # 4 on top row, 3 centered on bottom row so every 16:10 tablet card is large and crisp.
    cw, ch = 640, 400
    gap = 16
    pad = 24
    total_w = pad * 2 + 4 * cw + 3 * gap
    total_h = pad * 2 + 2 * ch + gap
    sheet = Image.new("RGB", (total_w, total_h), (5, 6, 10))
    draw = ImageDraw.Draw(sheet)
    for idx, card in enumerate(cards):
        resized = card.resize((cw, ch), Image.Resampling.LANCZOS)
        if idx < 4:
            x = pad + idx * (cw + gap)
            y = pad
        else:
            row2_w = 3 * cw + 2 * gap
            start_x = (total_w - row2_w) // 2
            x = start_x + (idx - 4) * (cw + gap)
            y = pad + ch + gap
        sheet.paste(resized, (x, y))
        draw.rectangle([x - 1, y - 1, x + cw, y + ch], outline=(45, 42, 36), width=1)
    out_png.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out_png, format="PNG", optimize=True)


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: organize_outputs.py <raw-shots-dir> <composed-dir>", file=sys.stderr)
        sys.exit(1)

    raw_in = Path(sys.argv[1])
    composed_in = Path(sys.argv[2])

    assert len(PLAY_LOCALES) == 51, f"Expected 51 Play locales, got {len(PLAY_LOCALES)}"
    play_folders = sorted(PLAY_LOCALES.values())
    all_locales = sorted(set(APP_49) | set(play_folders))

    # 1. Raw simulator captures -> ~/Desktop/BrassPawn/android-{phone,tablet}/screenshots/<locale>/
    raw_phone_root = DESKTOP_BP / "android-phone" / "screenshots"
    raw_tablet_root = DESKTOP_BP / "android-tablet" / "screenshots"

    for loc in APP_49:
        for kind, dst_root in [("phone", raw_phone_root), ("tablet", raw_tablet_root)]:
            for scene, _ in SCENES:
                src = raw_in / kind / loc / f"{scene}.png"
                assert src.is_file(), f"Missing raw shot: {src}"
                link_file(src, dst_root / loc / f"{scene}.png")

    for alias, src_loc in RAW_ALIASES.items():
        for dst_root in [raw_phone_root, raw_tablet_root]:
            for scene, _ in SCENES:
                link_file(dst_root / src_loc / f"{scene}.png", dst_root / alias / f"{scene}.png")

    # 2. Composed exports -> ~/Desktop/BrassPawn/storefront/exports/android-{phone,tablet}/<locale>/
    exports_root = DESKTOP_BP / "storefront" / "exports"
    exp_phone_root = exports_root / "android-phone"
    exp_tablet_root = exports_root / "android-tablet"

    for loc in all_locales:
        src_loc = loc if (composed_in / loc).is_dir() else RAW_ALIASES.get(loc, loc)
        for kind, dst_root in [("phone", exp_phone_root), ("tablet", exp_tablet_root)]:
            for scene, play_stem in SCENES:
                src = composed_in / src_loc / kind / f"{play_stem}.jpg"
                assert src.is_file(), f"Missing composed JPEG: {src}"
                link_file(src, dst_root / loc / f"{scene}.jpg")

    # 3. Google Play Console upload tree -> android/play-listing/<play-locale>/images/...
    play_root = ANDROID_ROOT / "play-listing"
    play_root.mkdir(parents=True, exist_ok=True)
    # Remove any stale non-51 locale directory if present
    wanted_set = set(play_folders)
    for child in play_root.iterdir():
        if child.is_dir() and not child.name.startswith("_") and child.name not in wanted_set:
            shutil.rmtree(child)

    verified_play_images = 0
    for play_lang, folder in sorted(PLAY_LOCALES.items()):
        images_dir = play_root / folder / "images"
        for scene, play_stem in SCENES:
            phone_src = exp_phone_root / folder / f"{scene}.jpg"
            tablet_src = exp_tablet_root / folder / f"{scene}.jpg"
            link_file(phone_src, images_dir / "phoneScreenshots" / f"{play_stem}.jpg")
            link_file(tablet_src, images_dir / "sevenInchScreenshots" / f"{play_stem}.jpg")
            link_file(tablet_src, images_dir / "tenInchScreenshots" / f"{play_stem}.jpg")

        # Validate Play Console constraints for every single linked image
        for img_type, expected_dims in [
            ("phoneScreenshots", (1080, 1920)),
            ("sevenInchScreenshots", (1920, 1200)),
            ("tenInchScreenshots", (1920, 1200)),
        ]:
            files = sorted((images_dir / img_type).glob("*.jpg"))
            assert len(files) == 7, f"{folder}/{img_type}: expected 7 files, got {len(files)}"
            for f in files:
                with Image.open(f) as im:
                    assert im.format == "JPEG", f"{f}: format {im.format}"
                    assert im.mode == "RGB", f"{f}: mode {im.mode}"
                    assert im.size == expected_dims, f"{f}: size {im.size} != {expected_dims}"
                    w, h = im.size
                    assert min(w, h) >= 320 and max(w, h) <= 3840
                    assert max(w, h) / min(w, h) <= 2.0
                    im.verify()
                verified_play_images += 1

    # 4. Generate contact sheets
    make_phone_contact_sheet(exp_phone_root / "en-US", exports_root / "contact-sheet-en-android-phone.png")
    make_phone_contact_sheet(exp_phone_root / "bg", exports_root / "contact-sheet-bg-android-phone.png")
    make_tablet_contact_sheet(exp_tablet_root / "en-US", exports_root / "contact-sheet-en-android-tablet.png")

    print(f"Organized raw screenshots: {len(all_locales)} locale folders x 7 scenes x 2 devices")
    print(f"Organized storefront exports: {len(all_locales)} locale folders x 7 scenes x 2 devices")
    print(f"Verified Play Console tree: {len(PLAY_LOCALES)} Play locales, {verified_play_images} JPEGs validated")
    print("Generated contact sheets:")
    print(" ", exports_root / "contact-sheet-en-android-phone.png")
    print(" ", exports_root / "contact-sheet-bg-android-phone.png")
    print(" ", exports_root / "contact-sheet-en-android-tablet.png")


if __name__ == "__main__":
    main()
