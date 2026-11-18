#!/usr/bin/env python3
"""Composes Brass Pawn's branded Android storefront screenshots on photovault-render
using headless Chrome (for native HarfBuzz/CoreText shaping across all 50+ scripts) and sips.

Usage:
    compose.py <shots-dir> <out-dir> [locale ...]

Inputs:
    <shots-dir>/phone/<shot-locale>/<scene>.png   (1280x2856)
    <shots-dir>/tablet/<shot-locale>/<scene>.png  (2560x1600)

Outputs:
    <out-dir>/<locale>/phone/1_title.jpg ... 7_free.jpg    (1080x1920, JPEG q=92)
    <out-dir>/<locale>/tablet/1_title.jpg ... 7_free.jpg   (1920x1200, JPEG q=92)
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[2]
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

SCENES = [
    ("01-menu", "1_title"),
    ("02-playMistake", "2_mistake"),
    ("03-tactics", "3_tactics"),
    ("04-online", "4_online"),
    ("05-positional", "5_positional"),
    ("06-playCoached", "6_coached"),
    ("07-playSetup", "7_free"),
]

# Maps Play/alias locale codes to their underlying raw screenshot folder name.
SHOT_SOURCE = {
    "en-AU": "en-US",
    "en-CA": "en-US",
    "en-GB": "en-US",
    "en": "en-US",
    "no": "nb",
    "gu": "gu-IN",
    "pa": "pa-IN",
    "ar": "ar-SA",
    "bn": "bn-BD",
    "de": "de-DE",
    "es": "es-ES",
    "fr": "fr-FR",
    "kn": "kn-IN",
    "ml": "ml-IN",
    "mr": "mr-IN",
    "nl": "nl-NL",
    "or": "or-IN",
    "pt": "pt-BR",
    "sl": "sl-SI",
    "ta": "ta-IN",
    "te": "te-IN",
    "ur": "ur-PK",
}

# Identical Play locales (same raw capture AND same copy) are hardlinked after rendering the primary.
IDENTICAL_TO = {
    "en-AU": "en-US",
    "en-CA": "en-US",
    "en-GB": "en-US",
    "no": "nb",
    "gu": "gu-IN",
    "pa": "pa-IN",
}

DEVICES = {
    "phone": ("pixel_10_pro", (59, 60), (1280, 2856), (1080, 1920), (1410, 2968)),
    "tablet": ("pixel_tablet", (119, 117), (2560, 1600), (1920, 1200), (2798, 1837)),
}

RTL_LANGS = {"ar", "he", "iw", "ur", "fa"}
NON_SERIF_LANGS = {
    "ar", "he", "iw", "ur", "fa",
    "hi", "bn", "gu", "kn", "ml", "mr", "or", "pa", "ta", "te",
    "th", "ja", "ko", "zh",
}

# Subtle per-frame pose (dx_px, rot_deg, text_align) echoing Brass Pawn's iOS StoreFront rhythm.
POSES = {
    "phone": [
        (0, 0.0, "left"),
        (-16, 1.05, "right"),
        (16, -0.95, "left"),
        (-14, 0.85, "right"),
        (14, -0.85, "left"),
        (-14, 0.95, "right"),
        (12, -0.80, "left"),
    ],
    "tablet": [
        (0, 0.0, "left"),
        (-22, 0.65, "right"),
        (22, -0.65, "left"),
        (-18, 0.55, "right"),
        (18, -0.55, "left"),
        (-20, 0.60, "right"),
        (16, -0.55, "left"),
    ],
}

LAYOUT = {
    "phone": dict(pad=68, top=62, box=286, hs_serif=72, hs_sans=56, dw=696, dy=390, sh=32, sb=58),
    "tablet": dict(pad=124, top=30, box=186, hs_serif=56, hs_sans=44, dw=1388, dy=240, sh=26, sb=46),
}

PAGE = """<!doctype html><html lang="{lang}" dir="{dir}"><meta charset="utf-8"><style>
{font_face}
html,body{{margin:0;width:{w}px;height:{wh}px;overflow:hidden;background:#05060A}}
#page{{position:absolute;left:0;top:100px;width:{w}px;height:{h}px;overflow:hidden;background:#05060A;
  font-family:{font_family};-webkit-font-smoothing:antialiased}}
#bg{{position:absolute;left:0;top:0;width:{w}px;height:{h}px;object-fit:cover;pointer-events:none}}
#copy{{position:absolute;left:{pad}px;right:{pad}px;top:{top}px;height:{box}px;display:flex;flex-direction:column;
  justify-content:center;align-items:{flex_align};text-align:{align};z-index:10}}
h1{{margin:0;font-weight:{weight};letter-spacing:{tracking};line-height:{lh};font-size:{hs}px;max-width:100%}}
.l1,.l2{{display:block;white-space:nowrap}}
.l1{{color:#F4EFE6}}
.l2{{color:#D6A95F;margin-top:{line_gap}px}}
#device{{position:absolute;left:calc(50% + {dx}px);top:{dy}px;width:{fw}px;height:{fh}px;transform-origin:50% 0%;
  transform:translateX(-50%) scale({scale:.6f}) rotate({rot}deg);
  filter:drop-shadow(0 {sh:.1f}px {sb:.1f}px rgba(0,0,0,0.82));z-index:5}}
#device img{{position:absolute}}
#screen{{position:absolute;left:{sx}px;top:{sy}px;width:{sw}px;height:{shh}px;border-radius:{radius}px;overflow:hidden;background:#05060A}}
#screen img{{left:0;top:0;width:{sw}px;height:{shh}px}}
#screen img.bar{{height:auto}}
.back{{left:0;top:0;width:{fw}px;height:{fh}px}}
</style>
<div id="page">
  <img id="bg" src="{bg_uri}">
  <div id="copy"><h1><span class="l1">{line1}</span><span class="l2">{line2}</span></h1></div>
  <div id="device">
    <div id="screen"><img src="{img_uri}">{bar_html}<img src="{mask_uri}"></div>
    <img class="back" src="{back_uri}">
  </div>
</div>
<script>
const c=document.getElementById('copy'),h=document.querySelector('h1');
const s1=document.querySelector('.l1'),s2=document.querySelector('.l2');
let hs={hs};
const minNowrap={min_nowrap},minWrap={min_wrap};
function fits(){{
  return c.scrollHeight<=c.clientHeight && s1.scrollWidth<=c.clientWidth && s2.scrollWidth<=c.clientWidth;
}}
while(!fits() && hs>minNowrap){{
  hs-=1.5;
  h.style.fontSize=hs+'px';
}}
if(!fits()){{
  s1.style.whiteSpace='normal'; s1.style.textWrap='balance';
  s2.style.whiteSpace='normal'; s2.style.textWrap='balance';
  while((c.scrollHeight>c.clientHeight || h.scrollWidth>c.clientWidth) && hs>minWrap){{
    hs-=1.5;
    h.style.fontSize=hs+'px';
  }}
}}
</script></html>"""


def esc(text: str) -> str:
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def resolve_shot_locale(shots: Path, kind: str, locale: str) -> str:
    if (shots / kind / locale).is_dir():
        return locale
    mapped = SHOT_SOURCE.get(locale)
    if mapped and (shots / kind / mapped).is_dir():
        return mapped
    base = locale.split("-")[0]
    mapped_base = SHOT_SOURCE.get(base, base)
    if (shots / kind / mapped_base).is_dir():
        return mapped_base
    return locale


def hardlink_or_copy(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        dst.unlink()
    try:
        os.link(src, dst)
    except OSError:
        shutil.copy2(src, dst)


def render(job: tuple) -> str | None:
    kind, locale, index, scene, out_stem, pair, shots, out_dir, work_dir, font_uri = job
    shot_locale = resolve_shot_locale(shots, kind, locale)
    shot = shots / kind / shot_locale / f"{scene}.png"
    if not shot.exists():
        return f"missing raw shot: {shot}"

    target = out_dir / locale / kind / f"{out_stem}.jpg"
    if os.environ.get("FORCE_COMPOSE") != "1" and target.exists() and target.stat().st_size > 5000:
        return None

    skin, (sx, sy), (sw, shh), (w, h), (fw, fh) = DEVICES[kind]
    lay = dict(LAYOUT[kind])
    lang = locale.split("-")[0]
    is_rtl = lang in RTL_LANGS
    use_sans = lang in NON_SERIF_LANGS

    dx, rot, align = POSES[kind][index]
    if is_rtl:
        dx = -dx
        rot = -rot
        align = "left" if align == "right" else "right"

    # In CSS flexbox without row-reverse, align-items:flex-start is visual start (right in dir=rtl, left in dir=ltr).
    if is_rtl:
        flex_align = "flex-start" if align == "right" else "flex-end"
    else:
        flex_align = "flex-start" if align == "left" else "flex-end"

    hs = lay["hs_sans"] if use_sans else lay["hs_serif"]
    scale = lay["dw"] / fw
    sh_px = lay["sh"]
    sb_px = lay["sb"]

    font_face = ""
    if font_uri and not use_sans:
        font_face = (
            f'@font-face{{font-family:"BrassSerif";src:url("{font_uri}") format("truetype");'
            f'font-weight:300 700;font-style:normal}}'
        )

    if use_sans:
        font_family = (
            '-apple-system,"SF Pro Display","Geeza Pro","Arial Hebrew","PingFang SC","PingFang TC",'
            '"Hiragino Sans","Apple SD Gothic Neo","Kohinoor Devanagari","Kohinoor Bangla",'
            '"Kohinoor Gujarati","Kohinoor Telugu","Kannada MN","Malayalam MN","Oriya MN",'
            '"Gurmukhi MN","Tamil MN","Thonburi","Noto Sans",sans-serif'
        )
        weight = "700"
        tracking = "-0.01em" if lang not in RTL_LANGS else "0"
        lh = "1.26"
        line_gap = 6 if kind == "phone" else 4
        min_nowrap = 32 if kind == "phone" else 26
        min_wrap = 24 if kind == "phone" else 20
    else:
        font_family = '"BrassSerif","Cormorant Garamond",Georgia,serif'
        weight = "600"
        tracking = "-0.01em"
        lh = "1.06"
        line_gap = 4 if kind == "phone" else 2
        min_nowrap = 42 if kind == "phone" else 34
        min_wrap = 30 if kind == "phone" else 24

    bg_prefix = "lamplight_rtl" if is_rtl else "lamplight"
    bg_uri = (HERE / "frames" / f"{bg_prefix}_{kind}_{index}.webp").resolve().as_uri()
    bar_html = ""
    if kind == "phone":
        bar_html = f'<img class="bar" src="{(HERE / "frames" / "statusbar_phone.png").resolve().as_uri()}">'

    tid = threading.get_ident()
    profile = work_dir / f"chrome_profile_{tid}"
    profile.mkdir(parents=True, exist_ok=True)
    stem_id = f"{kind}_{locale}_{scene}"
    html_path = work_dir / f"{stem_id}.html"
    png_path = work_dir / f"{stem_id}.png"

    html_path.write_text(
        PAGE.format(
            font_face=font_face,
            lang=locale,
            dir="rtl" if is_rtl else "ltr",
            w=w,
            h=h,
            wh=h + 200,
            font_family=font_family,
            pad=lay["pad"],
            top=lay["top"],
            box=lay["box"],
            flex_align=flex_align,
            align=align,
            weight=weight,
            tracking=tracking,
            lh=lh,
            hs=hs,
            line_gap=line_gap,
            dx=dx,
            dy=lay["dy"],
            fw=fw,
            fh=fh,
            scale=scale,
            rot=rot,
            sh=sh_px,
            sb=sb_px,
            sx=sx,
            sy=sy,
            sw=sw,
            shh=shh,
            radius=99 if kind == "phone" else 24,
            bg_uri=bg_uri,
            line1=esc(pair[0]),
            line2=esc(pair[1]),
            img_uri=shot.resolve().as_uri(),
            bar_html=bar_html,
            mask_uri=(HERE / "frames" / f"{skin}_mask.webp").resolve().as_uri(),
            back_uri=(HERE / "frames" / f"{skin}_back.webp").resolve().as_uri(),
            min_nowrap=min_nowrap,
            min_wrap=min_wrap,
        ),
        encoding="utf-8",
    )

    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            "--no-first-run",
            "--no-default-browser-check",
            f"--user-data-dir={profile}",
            f"--window-size={w},{h + 200}",
            f"--screenshot={png_path}",
            "--allow-file-access-from-files",
            html_path.resolve().as_uri(),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        timeout=120,
    )
    subprocess.run(
        [
            "sips",
            "-c",
            str(h),
            str(w),
            "-s",
            "format",
            "jpeg",
            "-s",
            "formatOptions",
            "92",
            str(png_path),
            "--out",
            str(target),
        ],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    png_path.unlink(missing_ok=True)
    html_path.unlink(missing_ok=True)
    return None


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: compose.py <shots-dir> <out-dir> [locale ...]", file=sys.stderr)
        sys.exit(1)

    shots = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    copy_path = Path(os.environ.get("STOREFRONT_COPY", HERE / "copy.json"))
    copy_data: dict[str, dict[str, list[str]]] = json.loads(copy_path.read_text(encoding="utf-8"))

    requested = sys.argv[3:] or sorted( p.name for p in (shots / "phone").iterdir() if p.is_dir() )
    cormorant = REPO_ROOT / "ios" / "Resources" / "Fonts" / "CormorantGaramond.ttf"
    font_uri = cormorant.resolve().as_uri() if cormorant.exists() else ""

    # Separate primary renders from identical aliases that can be hardlinked once primaries finish.
    requested_set = set(requested)
    deferred_links: list[tuple[str, str]] = []
    primary_locales: list[str] = []
    needed_primaries: set[str] = set()

    for loc in requested:
        src_loc = IDENTICAL_TO.get(loc)
        if src_loc and (src_loc in requested_set or (shots / "phone" / resolve_shot_locale(shots, "phone", src_loc)).is_dir()):
            deferred_links.append((loc, src_loc))
            needed_primaries.add(src_loc)
        else:
            primary_locales.append(loc)

    for src_loc in sorted(needed_primaries):
        if src_loc not in primary_locales:
            primary_locales.append(src_loc)

    workers = int(os.environ.get("COMPOSE_WORKERS", "6"))
    errors: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        work_dir = Path(tmp)
        jobs = []
        for locale in primary_locales:
            table = copy_data.get(locale) or copy_data.get(locale.split("-")[0]) or copy_data["en-US"]
            for kind in DEVICES:
                for index, (scene, out_stem) in enumerate(SCENES):
                    jobs.append((kind, locale, index, scene, out_stem, table[scene], shots, out_dir, work_dir, font_uri))

        with ThreadPoolExecutor(max_workers=workers) as pool:
            for err in pool.map(render, jobs):
                if err:
                    errors.append(err)
                    print(err, file=sys.stderr)

    for dst_loc, src_loc in deferred_links:
        for kind in DEVICES:
            for _, out_stem in SCENES:
                src_file = out_dir / src_loc / kind / f"{out_stem}.jpg"
                dst_file = out_dir / dst_loc / kind / f"{out_stem}.jpg"
                if src_file.exists():
                    hardlink_or_copy(src_file, dst_file)
                else:
                    errors.append(f"missing source for link: {src_file}")

    if errors:
        print(f"Finished with {len(errors)} errors", file=sys.stderr)
        sys.exit(1)

    total = len(requested) * len(DEVICES) * len(SCENES)
    print(f"Composed {total} JPEGs ({len(primary_locales)} rendered + {len(deferred_links)} hardlinked locales) -> {out_dir}")


if __name__ == "__main__":
    main()
