#!/usr/bin/env python3
"""Pull the site's translations out of the places that already have them.

Three translated corpora exist for this product, none of them written for a
website:

  * the app's own string catalogue — 580 keys in 31 languages, which is where
    the modes are named and where the privacy and licence claims are worded;
  * the App Store screenshot captions — seven headline pairs per language,
    written to be read at the size of a thumb, each one already matched to the
    picture it sits over;
  * the narrator scripts — three spoken lines per language, which are the best
    single-sentence description of the product that exists in any of them.

Translating any of that a second time would be worse than reusing it, and it
would drift. So the website takes it verbatim: what a Japanese visitor reads
here is what a Japanese user sees in the app and on the App Store.

What is left over is small enough to be written by hand, and lives in
`src/app/i18n/manual.ts`. This script emits everything else:

    src/app/i18n/copy/<slug>.ts

Re-run it whenever the app's strings or the storefront copy change:

    python3 tools/harvest-copy.py
"""

from __future__ import annotations

import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
CAPTURES = Path(os.environ.get("BRASSPAWN_CAPTURES", Path.home() / "Desktop/BrassPawn"))
APP = Path(os.environ.get("BRASSPAWN_APP", Path.home() / "chess"))
OUT = ROOT / "src/app/i18n/copy"

# App catalogue key -> the name the site knows it by. Only keys whose English
# reads as website prose are here; the app says plenty that would be strange
# out of context.
STRINGS = {
    "slug": "menu.slug",
    "lede": "about.tacticsPositionalJudgementEndgameTechnique",
    "privacy": "about.theAppCollectsNothingSends",
    "freeSoftware": "about.thisApplicationIsFreeSoftware",
    "stockfish": "about.itIncludesStockfishWhichIs",
    "reckless": "about.itAlsoIncludesReckless",
    "coaching": "play.coachingGradesEveryMove",
    "online": "online.aRealOpponentOverGame",
    "photo": "photo.title",
    "takeOver": "watch.continueHere",
    "freeForever": "store.freeForever",
    "allowance": "store.comeBackAtNine",
    "noAds": "store.noAds",
    "unlimitedPuzzles": "store.unlimitedPuzzles",
    "unlimitedRush": "store.unlimitedRush",
    "unlimitedRest": "store.unlimitedRest",
    "renewal": "store.renewalTerms",
    "pro": "store.title",
    "monthly": "store.monthly",
    "lifetime": "store.lifetime",
    "privacyPolicy": "store.privacy",
    "termsOfUse": "store.terms",
    "licence": "about.licence",
    "credits": "about.credits",
}

MODES = {
    "play": "progress.play",
    "watch": "progress.watch",
    "tactics": "progress.tactics",
    "positional": "progress.positional",
    "endgames": "progress.endgames",
    "guess": "progress.guessTheElo",
    "online": "progress.online",
    "progress": "progress.progress",
    "rush": "rush.rush",
}

# The section headings in lines.md, in the order the file writes them, mapped
# to the clip each one narrates.
NARRATION_SECTIONS = {"Гледане": "watch", "Тактики": "tactics", "Треньор": "play"}


def load_storefront() -> dict:
    path = CAPTURES / "storefront/tools/copy.py"
    spec = importlib.util.spec_from_file_location("storefront_copy", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.COPY


def load_narration() -> dict[str, dict[str, str]]:
    """{tag: {clip: line}} out of the markdown table the scripts were tracked in."""
    text = (CAPTURES / "narration/lines.md").read_text()
    out: dict[str, dict[str, str]] = {}
    clip = None
    for line in text.splitlines():
        if line.startswith("## "):
            clip = NARRATION_SECTIONS.get(line[3:].strip())
            continue
        if not clip or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) != 3 or cells[0] in ("език", "---"):
            continue
        tag, _who, said = cells
        if set(tag) <= set("-"):
            continue
        out.setdefault(tag, {})[clip] = said
    return out


def load_app() -> dict:
    return json.loads((APP / "ios/App/Localizable.xcstrings").read_text())["strings"]


def value(strings: dict, key: str, tag: str) -> str | None:
    localisations = strings.get(key, {}).get("localizations", {})
    unit = (localisations.get(tag) or localisations.get("en") or {}).get("stringUnit", {})
    return unit.get("value")


def ts(v, indent: int = 0) -> str:
    """A TypeScript object literal that a person can read in a diff.

    Wraps only when the one-line form would run past a hundred columns, which
    keeps `modes` on one line and gives every paragraph of `said` its own.
    """
    pad = "  " * indent
    inner = "  " * (indent + 1)
    if isinstance(v, (list, tuple)):
        flat = "[" + ", ".join(ts(x) for x in v) + "]"
        if len(flat) + len(pad) <= 100:
            return flat
        rows = ",\n".join(inner + ts(x, indent + 1) for x in v)
        return "[\n" + rows + ",\n" + pad + "]"
    if isinstance(v, dict):
        flat = "{ " + ", ".join(f"{key(k)}: {ts(x)}" for k, x in v.items()) + " }"
        if len(flat) + len(pad) <= 100:
            return flat
        rows = ",\n".join(f"{inner}{key(k)}: {ts(x, indent + 1)}" for k, x in v.items())
        return "{\n" + rows + ",\n" + pad + "}"
    return json.dumps(v, ensure_ascii=False).replace("\\u2019", "\u2019")


# The header and footer's own words. They go into locales.ts, which is
# synchronous and in the main bundle, and so must not also be duplicated into
# Copy.ui, which arrives by dynamic import a moment later.
CHROME_KEYS = (
    "skip", "readSource", "elsewhere", "sourceOnGitHub", "reportIssue",
    "languages", "colApp", "colChess", "colLegal", "licence", "rights",
    "attribution", "inEnglish",
)

IDENT = re.compile(r"^[A-Za-z_$][A-Za-z0-9_$]*$")


def key(k: str) -> str:
    return k if IDENT.match(k) else json.dumps(k)


def main() -> int:
    for path, what in ((CAPTURES, "captures"), (APP, "app repo")):
        if not path.is_dir():
            print(f"{what} not found: {path}", file=sys.stderr)
            return 1

    locales = json.loads((HERE / "locales.json").read_text())["locales"]
    manual = json.loads((HERE / "manual.json").read_text())
    storefront = load_storefront()
    narration = load_narration()
    strings = load_app()

    OUT.mkdir(parents=True, exist_ok=True)
    missing: list[str] = []
    index: list[str] = []

    for loc in locales:
        tag, slug, store = loc["tag"], loc["slug"], loc["store"]

        # A language with no App Store localisation has none of the three corpora
        # this script assembles from, so there is nothing here to harvest for it.
        # Its file is written by hand; regenerating it would replace a real
        # translation with empty strings and the loader would still list it.
        if loc.get("handwritten"):
            if not (OUT / f"{slug}.ts").exists():
                missing.append(f"{tag}: copy/{slug}.ts is hand-written and absent")
            index.append(f"  '{slug}': () => import('./copy/{slug}').then((m) => m.copy),")
            continue


        said = {name: value(strings, key, tag) for name, key in STRINGS.items()}
        modes = {name: value(strings, key, tag) for name, key in MODES.items()}
        shots = {view: list(pair) for view, pair in storefront[store].items()}
        spoken = narration.get(tag, {})
        ui = {k: v for k, v in manual[tag].items() if k not in CHROME_KEYS}

        for name, v in {**said, **modes}.items():
            if not v:
                missing.append(f"{tag}: {name}")
        for clip in ("play", "tactics", "watch"):
            if clip not in spoken:
                missing.append(f"{tag}: spoken.{clip}")

        body = f"""// {loc['english']} ({tag}). Generated by tools/harvest-copy.py — do not edit.
//
// `said`, `modes`, `shots` and `spoken` were already translated: for the app's
// own screens, for its App Store page, and for the narrator to read aloud. The
// website repeats them word for word rather than translating the same claims a
// second time, so the sentence that persuaded somebody here is still there,
// unchanged, in the app they install.
//
// `ui` is the remainder — the two dozen strings that exist only on a website —
// and it is written by hand in tools/manual.json.

import type {{ Copy }} from '../types';

export const copy: Copy = {{
  said: {ts(said, 2)},
  modes: {ts(modes, 2)},
  shots: {ts(shots, 2)},
  spoken: {ts(spoken, 2)},
  ui: {ts(ui, 2)},
}};
"""
        (OUT / f"{slug}.ts").write_text(body)
        index.append(f"  '{slug}': () => import('./copy/{slug}').then((m) => m.copy),")

    loader = """// Generated by tools/harvest-copy.py — do not edit.
//
// A static map of dynamic imports, which is the form the bundler can see
// through: it splits each language into its own chunk, and a visitor to the
// Japanese page downloads Japanese and nothing else. A computed import path
// would defeat that and ship all thirty-one.

import type {{ Copy }} from './types';

export const COPY: Record<string, () => Promise<Copy>> = {{
{rows}
}};
""".format(rows="\n".join(index))
    (OUT.parent / "copy.ts").write_text(loader)

    # The header's own words go into this table rather than into the language
    # chunk, and that is a correctness decision rather than a size one. The
    # header renders before the router has resolved anything, on the server and
    # again in the browser; if its labels arrived a moment later than its
    # markup, hydration would find a different number of links than the page was
    # serialised with and duplicate them. Ten short strings per language, in the
    # main bundle, are the price of the header being right on the first frame.
    rows = ",\n".join(
        "  { "
        + ", ".join(f"{key(k)}: {json.dumps(loc[k], ensure_ascii=False)}" for k in
                    ("tag", "slug", "name", "english", "dir"))
        + ", nav: "
        + ts({k: manual[loc["tag"]][k] for k in
              ("film", "screens", "price", "questions", "download", "soon")})
        + ", chrome: "
        + ts({**{k: manual[loc["tag"]][k] for k in
                 ("skip", "inEnglish", "readSource", "elsewhere", "sourceOnGitHub",
                  "reportIssue", "languages", "colApp", "colChess", "colLegal",
                  "licence", "rights", "attribution")},
              "lede": value(strings, STRINGS["lede"], loc["tag"])})
        + " }"
        for loc in locales
    )
    (OUT.parent / "locales.ts").write_text(
        """// Generated by tools/harvest-copy.py from tools/locales.json — do not edit.

/** One of the thirty-one languages the app and this site ship in. */
export interface Locale {{
  /** BCP-47. Exactly what goes in `hreflang` and in `<html lang>`. */
  readonly tag: string;
  /** The URL segment. English is the site root and has no segment of its own. */
  readonly slug: string;
  /** The language's name for itself, which is the only name a switcher may use. */
  readonly name: string;
  /** Its name in English, for `title` and `aria-label` on that switcher. */
  readonly english: string;
  readonly dir: 'ltr' | 'rtl';
  /** What the title bar says on this language's page. See the note in tools/harvest-copy.py. */
  readonly nav: {{
    readonly film: string;
    readonly screens: string;
    readonly price: string;
    readonly questions: string;
    readonly download: string;
    readonly soon: string;
  }};
  /**
   * The header and footer, which every page in every language wears.
   *
   * Here rather than in `Copy.ui` for the reason the note above gives about
   * `nav`: `Copy` arrives by dynamic import, a moment after the markup it
   * belongs to. The footer would serialise in one language and hydrate in
   * another, and Angular would keep both sets of nodes. These are synchronous
   * and in the main bundle, which is what makes the chrome right on the first
   * frame.
   */
  readonly chrome: {{
    readonly skip: string;
    /** Marks a link that leaves this language behind. */
    readonly inEnglish: string;
    /** The app's own one-sentence description, from its catalogue. */
    readonly lede: string;
    readonly readSource: string;
    readonly elsewhere: string;
    readonly sourceOnGitHub: string;
    readonly reportIssue: string;
    readonly languages: string;
    readonly colApp: string;
    readonly colChess: string;
    readonly colLegal: string;
    readonly licence: string;
    readonly rights: string;
    readonly attribution: string;
  }};
}}

export const LOCALES: readonly Locale[] = [
{rows}
];

/** English lives at `/`; every other language at `/<slug>`. */
export const localePath = (locale: Locale): string => (locale.slug === 'en' ? '/' : `/${{locale.slug}}`);

export const bySlug = (slug: string): Locale | undefined => LOCALES.find((l) => l.slug === slug);

export const DEFAULT_LOCALE: Locale = LOCALES[0];
""".format(rows=rows)
    )

    # Run through the project's formatter rather than trying to emit its exact
    # output. Without this every regeneration would show up as a diff against
    # whatever prettier did to the files last time, and the real change — a
    # sentence somebody actually rewrote — would be buried in it.
    prettier = ROOT / "node_modules/.bin/prettier"
    if prettier.exists():
        subprocess.run(
            [str(prettier), "--write", "--log-level", "warn",
             str(OUT), str(OUT.parent / "copy.ts"), str(OUT.parent / "locales.ts")],
            cwd=ROOT,
            check=False,
        )

    print(f"wrote {len(locales)} languages to {OUT.relative_to(ROOT)}")
    if missing:
        print(f"\n{len(missing)} strings had no translation and fell back to English:")
        for m in missing[:40]:
            print(f"  {m}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
