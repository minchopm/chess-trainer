#!/usr/bin/env python3
"""Builds App/Localizable.xcstrings from Localization/keys.json + one file per language.

The catalogue is generated rather than edited: a String Catalog is a machine
format with five lines of JSON per string, and hand-editing thirty languages of
it is how translations quietly go missing.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCALES = [
    "ar-SA", "cs", "da", "de-DE", "el", "en-CA", "en-US", "es-ES", "fi", "fr-CA",
    "fr-FR", "he", "hi", "hu", "id", "it", "ja", "ko", "ms", "nl-NL", "no", "pl",
    "pt-BR", "ro", "ru", "sv", "th", "tr", "vi", "zh-Hans", "zh-Hant",
]

def main():
    keys = json.loads((ROOT / "Localization/keys.json").read_text())
    english = {k["key"]: k["english"] for k in keys}

    tables = {}
    for locale in LOCALES:
        path = ROOT / f"Localization/{locale}.json"
        tables[locale] = json.loads(path.read_text()) if path.exists() else {}

    # The English variants are English. Filling them in rather than leaving them
    # empty is what makes the app advertise them as supported languages.
    for locale in ("en-US", "en-CA"):
        tables[locale] = dict(english)

    strings = {}
    for key in sorted(english):
        localizations = {
            "en": {"stringUnit": {"state": "translated", "value": english[key]}}
        }
        for locale in LOCALES:
            value = tables[locale].get(key)
            if not value:
                continue          # no entry means English, which is the fallback
            localizations[locale] = {"stringUnit": {"state": "translated", "value": value}}
        strings[key] = {"extractionState": "manual", "localizations": localizations}

    catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
    out = ROOT / "App/Localizable.xcstrings"
    out.write_text(json.dumps(catalog, indent=2, ensure_ascii=False, sort_keys=True) + "\n")

    done = [(l, len(t)) for l, t in tables.items() if t]
    print(f"{len(english)} keys → {out.relative_to(ROOT)}")
    for locale, count in sorted(done):
        missing = len(english) - count
        print(f"  {locale:8} {count:4d} translated" + (f", {missing} left" if missing else " — complete"))
    if not done:
        print("  (no language files yet — English only)")

main()
