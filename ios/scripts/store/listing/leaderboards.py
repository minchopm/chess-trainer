#!/usr/bin/env python3
"""Create the online rank lists in Game Center: one leaderboard per clock.

    python3 leaderboards.py      create what is missing, and say what is there

Each clock has its own rating in the app, so each has its own list —
`brasspawn.online.<minutes>`, which is what `OnlineBoards.leaderboardID` asks
for. "Most recent score" rather than best: a rating is meant to go down as well
as up, and the entry's date is then when the player was last seen, which is
what the app's active and inactive lists are read from.

The names are the app's own words for multiplayer and for the clock, in each of
its languages. Safe to run again: each step looks before it writes.

New leaderboards go live with the next app version: they are added on the
version's page in App Store Connect, under Game Center, before it is submitted.
"""
import json
import pathlib
import sys

from asc import call

APP = "6803566012"
CLOCKS = [3, 5, 10, 15, 30]
CATALOG = pathlib.Path(__file__).resolve().parents[3] / "App" / "Localizable.xcstrings"
# The locales Game Center shows leaderboards in, as the app's listing has them.
LOCALES = ["ar-SA", "cs", "da", "de-DE", "el", "en-CA", "en-US", "es-ES", "fi", "fr-CA", "fr-FR", "he", "hi",
           "hu", "id", "it", "ja", "ko", "ms", "nl-NL", "no", "pl", "pt-BR", "ro", "ru", "sv", "th", "tr", "vi",
           "zh-Hans", "zh-Hant"]


def every(path):
    out, url = [], path
    while url:
        page = call("GET", url)
        out += page["data"]
        url = page.get("links", {}).get("next")
    return out


def words():
    strings = json.loads(CATALOG.read_text())["strings"]
    value = lambda key, locale: strings[key]["localizations"][locale]["stringUnit"]["value"]
    return {l: (value("play.multiplayer", l), value("clock.minutes", l)) for l in LOCALES}


def main():
    detail = call("GET", f"/apps/{APP}/gameCenterDetail")["data"]["id"]
    have = {b["attributes"]["vendorIdentifier"]: b["id"]
            for b in every(f"/gameCenterDetails/{detail}/gameCenterLeaderboards?limit=50")}
    names = words()
    for minutes in CLOCKS:
        vendor = f"brasspawn.online.{minutes}"
        board = have.get(vendor)
        if board:
            print(f"{vendor}: exists ({board})")
        else:
            board = call("POST", "/gameCenterLeaderboards", {"data": {
                "type": "gameCenterLeaderboards",
                "attributes": {
                    "referenceName": f"Online rating, {minutes} min",
                    "vendorIdentifier": vendor,
                    "defaultFormatter": "INTEGER",
                    "submissionType": "MOST_RECENT_SCORE",
                    "scoreSortType": "DESC",
                    # No range: a rating has no ceiling (see Glicko).
                },
                "relationships": {"gameCenterDetail": {"data": {"type": "gameCenterDetails", "id": detail}}},
            }})["data"]["id"]
            print(f"{vendor}: created ({board})")
        done = {l["attributes"]["locale"]
                for l in every(f"/gameCenterLeaderboards/{board}/localizations?limit=50")}
        added = 0
        for locale in LOCALES:
            if locale in done:
                continue
            mode, clock = names[locale]
            call("POST", "/gameCenterLeaderboardLocalizations", {"data": {
                "type": "gameCenterLeaderboardLocalizations",
                "attributes": {"locale": locale, "name": f"{mode} · {clock.replace('%lld', str(minutes))}"},
                "relationships": {"gameCenterLeaderboard": {"data": {"type": "gameCenterLeaderboards", "id": board}}},
            }})
            added += 1
        print(f"  localizations: {len(done) + added} ({added} added)")


if __name__ == "__main__":
    sys.exit(main())
