#!/usr/bin/env python3
"""Turn the iOS string catalog into the Android app's string tables.

    strings.py <Localizable.xcstrings> <android/localization> <out dir>

One JSON object per language, keyed exactly as on iOS, with Swift's format
specifiers left as they are: the app substitutes them itself (core's `L.t`),
so a translation is never touched on its way from one platform to the other.
Strings that exist only on Android live in android/localization/<lang>.json
(en.json is the source) and are laid over the catalog's.
"""
import json
import sys
from pathlib import Path


def main() -> None:
    catalog_path, extra_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    source = catalog.get("sourceLanguage", "en")
    tables: dict[str, dict[str, str]] = {source: {}}
    for key, entry in catalog["strings"].items():
        localizations = entry.get("localizations", {})
        for language, localization in localizations.items():
            unit = localization.get("stringUnit")
            if unit and unit.get("value"):
                tables.setdefault(language, {})[key] = unit["value"]
        # The catalog leaves the source language out when the key is the text.
        tables[source].setdefault(key, key)

    for extra in sorted(extra_dir.glob("*.json")):
        tables.setdefault(extra.stem, {}).update(json.loads(extra.read_text(encoding="utf-8")))

    out_dir.mkdir(parents=True, exist_ok=True)
    wanted = set()
    for language, table in sorted(tables.items()):
        name = f"{language}.json"
        wanted.add(name)
        text = json.dumps(table, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        target = out_dir / name
        if not target.exists() or target.read_text(encoding="utf-8") != text:
            target.write_text(text, encoding="utf-8")
    index = json.dumps(sorted(tables), separators=(",", ":"))
    (out_dir / "index.json").write_text(index, encoding="utf-8")
    wanted.add("index.json")
    for stale in out_dir.glob("*.json"):
        if stale.name not in wanted:
            stale.unlink()


if __name__ == "__main__":
    main()
