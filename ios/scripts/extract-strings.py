#!/usr/bin/env python3
"""Rewrites user-facing literals in the views into catalogue lookups.

Run once. It replaces `Text("Hint")` with `Text(L.t("action.hint", "Hint"))`
and records every key in Localization/keys.json, which is what the per-language
files are keyed by from then on.
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PREFIX = {
    'TacticsScreen.swift': 'tactics', 'TacticsView.swift': 'tactics',
    'PositionalScreen.swift': 'positional', 'EndgameScreen.swift': 'endgame',
    'PlayScreen.swift': 'play', 'PlayTab.swift': 'play', 'RushScreen.swift': 'rush',
    'GuessTheEloScreen.swift': 'guess', 'OnlineScreen.swift': 'online',
    'RootView.swift': 'progress', 'AboutScreen.swift': 'about',
    'Components.swift': 'common', 'TrainingTab.swift': 'common',
    'BoardStage.swift': 'board', 'CompletionOverlay.swift': 'common',
    'ActionBar.swift': 'action', 'MoveValueController.swift': 'common',
    'CoachService.swift': 'coach', 'AppModel.swift': 'common',
}
CALLS = r'(Text|Label|Button|LabeledContent|Picker|Section|navigationTitle|accessibilityLabel)'
SKIP = re.compile(r'^[a-z0-9.]+$')      # SF Symbol names and the like

def slug(text, words=5):
    parts = re.findall(r"[A-Za-z0-9]+", text)[:words]
    if not parts:
        return "text"
    head = parts[0].lower()
    return head + "".join(p.capitalize() for p in parts[1:])

def main():
    keys = {}
    for path in sorted((ROOT / 'Sources/BrassPawnApp').rglob('*.swift')):
        source = path.read_text()
        prefix = PREFIX.get(path.name, 'common')
        changed = False

        def replace(match):
            nonlocal changed
            call, literal = match.group(1), match.group(2)
            if SKIP.match(literal) or len(literal) < 2 or '\\(' in literal:
                return match.group(0)
            key = f"{prefix}.{slug(literal)}"
            existing = keys.get(key)
            if existing and existing['english'] != literal:
                key += str(sum(ord(c) for c in literal) % 97)
            keys.setdefault(key, {'key': key, 'english': literal, 'files': []})
            if path.name not in keys[key]['files']:
                keys[key]['files'].append(path.name)
            changed = True
            escaped = literal.replace('"', '\\"')
            return f'{call}(L.t("{key}", "{escaped}")'

        source = re.sub(CALLS + r'\(\s*"((?:[^"\\]|\\.)+)"', replace, source)

        # ActionItem and CompletionResult take their titles by label.
        def replace_labelled(match):
            nonlocal changed
            label, literal = match.group(1), match.group(2)
            if SKIP.match(literal) or len(literal) < 2 or '\\(' in literal:
                return match.group(0)
            key = f"{prefix}.{slug(literal)}"
            existing = keys.get(key)
            if existing and existing['english'] != literal:
                key += str(sum(ord(c) for c in literal) % 97)
            keys.setdefault(key, {'key': key, 'english': literal, 'files': []})
            if path.name not in keys[key]['files']:
                keys[key]['files'].append(path.name)
            changed = True
            escaped = literal.replace('"', '\\"')
            return f'{label}L.t("{key}", "{escaped}")'

        source = re.sub(r'\b(title:\s*|primaryTitle:\s*|detail:\s*|what:\s*|reason:\s*|name:\s*)"((?:[^"\\]|\\.)+)"',
                        replace_labelled, source)

        if changed:
            path.write_text(source)

    out = ROOT / 'Localization/keys.json'
    out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps(sorted(keys.values(), key=lambda k: k['key']), indent=1, ensure_ascii=False) + "\n")
    print(f"{len(keys)} keys → {out}")

main()
