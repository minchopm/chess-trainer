#!/usr/bin/env python3
"""Preview or apply the reviewed ASO translations to an explicit app version.

Examples (dry run unless --apply is present):
  python3 apply_localized_metadata.py --platform MAC_OS --version 1.3
  python3 apply_localized_metadata.py --platform IOS --version <next-version> --apply
Uses the existing ~/.appstore/config credentials without printing them.
"""
import argparse
import json
from pathlib import Path
from asc import call

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--platform', choices=['IOS', 'MAC_OS'], required=True)
parser.add_argument('--version', required=True)
parser.add_argument('--apply', action='store_true')
args = parser.parse_args()
source = Path(__file__).resolve().parents[3] / 'store-metadata/aso-2026-10-02/localizations.json'
copy = json.loads(source.read_text())
versions = call('GET', '/apps/6803566012/appStoreVersions?limit=200')['data']
matches = [v for v in versions if v['attributes']['platform'] == args.platform and v['attributes']['versionString'] == args.version]
if len(matches) != 1:
    raise SystemExit('Expected one existing version. This script does not create or submit app versions.')
version = matches[0]
if version['attributes']['appStoreState'] in {'READY_FOR_SALE', 'READY_FOR_DISTRIBUTION'}:
    raise SystemExit('Published version: description and keywords are locked. Select the next editable version.')
rows = call('GET', f"/appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=200")['data']
for row in rows:
    locale = row['attributes']['locale']
    if locale not in copy:
        raise SystemExit(f'No reviewed translation: {locale}')
    text = copy[locale]
    assert len(text['description']) <= 4000 and len(text['keywords']) <= 100
backup = source.parent / f"backup-{args.platform}-{args.version}.json"
if args.apply:
    if backup.exists():
        raise SystemExit(f'Backup already exists: {backup}. Review it before a repeat run.')
    backup.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n')
for row in rows:
    locale = row['attributes']['locale']
    text = copy[locale]
    if args.apply:
        call('PATCH', '/appStoreVersionLocalizations/' + row['id'], {
            'data': {'type': row['type'], 'id': row['id'], 'attributes': text}
        })
        actual = call('GET', '/appStoreVersionLocalizations/' + row['id'])['data']['attributes']
        assert all(actual[k] == value for k, value in text.items()), locale
    print(locale, 'verified' if args.apply else 'preview', len(text['description']), len(text['keywords']))
