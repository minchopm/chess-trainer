#!/usr/bin/env python3
"""Builds App/Localizable.xcstrings from Localization/keys.json + one file per language.

The catalogue is generated rather than edited: a String Catalog is a machine
format with five lines of JSON per string, and hand-editing thirty languages of
it is how translations quietly go missing.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCALES = [
    "ar-SA", "cs", "da", "de-DE", "el", "en-CA", "en-US", "es-ES", "fi", "fr-CA",
    "fr-FR", "he", "hi", "hu", "id", "it", "ja", "ko", "ms", "nl-NL", "no", "pl",
    "pt-BR", "ro", "ru", "sv", "th", "tr", "vi", "zh-Hans", "zh-Hant",
]

# Anything printf will read an argument for. `%%` is an escaped percent and
# takes none, so it is not one of these.
PLACEHOLDER = re.compile(
    r"%(?:\d+\$)?[-+ #0]*[\d*]*(?:\.[\d*]+)?(?:hh|h|ll|l|L|z|j|t|q)?([@dDiuUxXoOfeEgGcCsSpaAF%])"
)


def placeholders(text):
    return [m.group(1) for m in PLACEHOLDER.finditer(text) if m.group(1) != "%"]


def check(english, tables):
    """Every translation must ask printf for exactly what the English does.

    A translated string is a format string, and it is handed to `String(format:)`
    with the arguments the *English* wanted. Add a placeholder in translation and
    printf reads an argument that was never passed — which is not a wrong word on
    screen, it is the app going down.

    It has happened: the Hungarian for `store.freeToday` was written with a range
    where the English has a single count — four placeholders against three — so
    the app crashed for anyone with a Hungarian phone at the moment it told them
    what they get for free. Nothing in the pipeline noticed, because nothing was
    looking.
    """
    faults = []
    for locale, table in sorted(tables.items()):
        for key, text in sorted(table.items()):
            source = english.get(key)
            if source is None:
                continue
            wanted, given = placeholders(source), placeholders(text)
            if wanted != given:
                faults.append(
                    f"  {locale} {key}\n"
                    f"    en {source!r}\n"
                    f"       wants {wanted}\n"
                    f"    {locale} {text!r}\n"
                    f"       gives {given}"
                )
    return faults


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

    faults = check(english, tables)
    if faults:
        print(f"{len(faults)} translation(s) do not match the English format:\n")
        print("\n\n".join(faults))
        sys.exit(1)

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

def info_plist():
    """The permission prompts, which iOS shows from Info.plist rather than from
    the app's own catalogue.

    A separate file because they are keyed by Apple's names rather than ours,
    and a separate catalogue because Xcode looks for this one under a fixed
    name. Without it the camera prompt stays English in every language the app
    is otherwise translated into — and it is the first sentence a good many
    people would read.
    """
    source = ROOT / "Localization/infoplist.json"
    if not source.exists():
        return
    table = json.loads(source.read_text())
    strings = {}
    for key, values in table.items():
        strings[key] = {
            "extractionState": "manual",
            "localizations": {
                locale: {"stringUnit": {"state": "translated", "value": text}}
                for locale, text in values.items()
            },
        }
    catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
    out = ROOT / "App/InfoPlist.xcstrings"
    out.write_text(json.dumps(catalog, indent=2, ensure_ascii=False, sort_keys=True) + "\n")
    print(f"{len(strings)} Info.plist key(s) → {out.relative_to(ROOT)}")


info_plist()
