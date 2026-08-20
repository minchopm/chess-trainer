#!/usr/bin/env python3
"""Builds the library of games the board plays out.

The games are real, and they are not typed in here. They come from published
collections of the players' own games, which is the only way to be sure that a
game attributed to Morphy is the game Morphy played: a famous score written
from memory is legal, plausible and quietly wrong, and nothing downstream would
catch it.

What it selects is the part worth reading. A watched game has to be doing
something on every move — so: decisive, both players named, short enough to sit
through, and finishing either in mate or inside twenty-five moves. That leaves
the brilliancies and the miniatures and throws away the seventy-move endgame
technique, which is admirable and is not a title sequence.

    python3 ios/scripts/import-classics.py            # download and build
    python3 ios/scripts/import-classics.py --local DIR  # from PGNs already here
"""

import argparse
import io
import json
import os
import re
import sys
import urllib.request
import zipfile
from pathlib import Path

SOURCE = "https://www.pgnmentor.com/players/{}.zip"

PLAYERS = [
    "Morphy", "Anderssen", "Steinitz", "Lasker", "Capablanca", "Alekhine",
    "Rubinstein", "Nimzowitsch", "Botvinnik", "Smyslov", "Tal", "Petrosian",
    "Spassky", "Fischer", "Karpov", "Kasparov", "Anand", "Kramnik", "Topalov",
    "Ivanchuk", "Shirov", "Carlsen", "Nakamura", "Caruana", "Bronstein",
    "Keres", "Larsen", "Geller", "Korchnoi", "Aronian", "Nepomniachtchi",
    "Ding", "Firouzja",
]

TAG = re.compile(r'\[(\w+)\s+"([^"]*)"\]')
# Move text minus everything that is not a move: numbers, comments, variations,
# annotation glyphs and the result.
COMMENT = re.compile(r"\{[^}]*\}")
VARIATION = re.compile(r"\([^()]*\)")
NUMBER = re.compile(r"\d+\.(\.\.)?")
NAG = re.compile(r"\$\d+")
RESULT = re.compile(r"(1-0|0-1|1/2-1/2|\*)$")

MAX_MOVES = 60
MIN_MOVES = 12
MINIATURE = 25

# Games worth watching that are too long to be miniatures.
#
# Only the identity is written here — two surnames and a year. The moves still
# come out of the database, so this list can be wrong about which game is
# famous and cannot be wrong about what was played.
NOTABLE = [
    ("Kasparov", "Topalov", 1999), ("Byrne", "Fischer", 1956),
    ("Rotlewi", "Rubinstein", 1907), ("Steinitz", "Bardeleben", 1895),
    ("Lasker", "Bauer", 1889), ("Bernstein", "Capablanca", 1914),
    ("Reti", "Bogoljubov", 1924), ("Short", "Timman", 1991),
    ("Larsen", "Spassky", 1970), ("Botvinnik", "Capablanca", 1938),
    ("Fischer", "Spassky", 1972), ("Ivanchuk", "Yusupov", 1991),
    ("Geller", "Euwe", 1953), ("Tal", "Botvinnik", 1960),
    ("Anand", "Aronian", 2013), ("Carlsen", "Karjakin", 2016),
    ("Karpov", "Kasparov", 1985), ("Polugaevsky", "Nezhmetdinov", 1958),
    ("Spassky", "Bronstein", 1960), ("Petrosian", "Spassky", 1966),
    ("Kramnik", "Kasparov", 2000), ("Alekhine", "Bogoljubov", 1922),
    ("Capablanca", "Marshall", 1918), ("Fischer", "Larsen", 1971),
    ("Shirov", "Topalov", 1998), ("Aronian", "Anand", 2013),
]


def notable(white, black, year):
    for one, two, when in NOTABLE:
        if when == year and one.lower() in white.lower() and two.lower() in black.lower():
            return True
    return False


def games(text):
    """Splits a PGN file into (tags, movetext) pairs."""
    chunks = re.split(r"\n\s*\n(?=\[)", text)
    pending_tags = None
    for chunk in chunks:
        chunk = chunk.strip()
        if not chunk:
            continue
        if chunk.startswith("["):
            tags = dict(TAG.findall(chunk))
            body = TAG.sub("", chunk).strip()
            if body:
                yield tags, body
            else:
                pending_tags = tags
        elif pending_tags is not None:
            yield pending_tags, chunk
            pending_tags = None


def moves_of(body):
    body = COMMENT.sub(" ", body)
    for _ in range(4):
        body = VARIATION.sub(" ", body)
    body = NAG.sub(" ", body)
    body = NUMBER.sub(" ", body)
    tokens = [t for t in body.split() if t and not RESULT.match(t)]
    return tokens


def year_of(tags):
    date = tags.get("Date", "")
    head = date.split(".")[0]
    return int(head) if head.isdigit() else None


def collect(sources):
    seen = set()
    out = []
    for path in sorted(sources):
        text = Path(path).read_text(encoding="latin-1")
        for tags, body in games(text):
            result = tags.get("Result", "")
            if result not in ("1-0", "0-1"):
                continue
            white, black = tags.get("White", ""), tags.get("Black", "")
            if not white or not black or "?" in white or "?" in black:
                continue
            year = year_of(tags)
            if year is None:
                continue

            san = moves_of(body)
            if not san:
                continue
            plies = len(san)
            moves = (plies + 1) // 2
            if moves < MIN_MOVES or moves > MAX_MOVES:
                continue

            # The database does not write the mating hash, so mate cannot be
            # read off the notation; shortness and a decisive result are the
            # signals that survive.
            famous = notable(white, black, year)
            if not famous and moves > MINIATURE:
                continue

            # The collections overlap: a Kasparov–Karpov game is in both
            # players' files, sometimes with the event spelled differently. The
            # moves are what identify a game.
            # The collections overlap: a Kasparov–Karpov game is in both
            # players' files, sometimes with the event spelled differently and
            # sometimes with the score recorded two moves longer. The players,
            # the year and the opening twenty plies identify a game; the whole
            # move list does not.
            key = (white.lower(), black.lower(), year, " ".join(san[:20]))
            if key in seen:
                continue
            seen.add(key)

            out.append({
                "id": f"{white.split(',')[0]}-{black.split(',')[0]}-{year}-{plies}".replace(" ", ""),
                "white": tidy(white),
                "black": tidy(black),
                "event": tags.get("Event", "").strip() or "Unknown",
                "site": tags.get("Site", "").strip(),
                "year": year,
                "result": "1–0" if result == "1-0" else "0–1",
                "eco": tags.get("ECO", ""),
                "notable": famous,
                "moves": " ".join(san),
            })
    return out


# How the databases spell people, and how people spell themselves.
ALIASES = {
    "Gary Kasparov": "Garry Kasparov", "G Kasparov": "Garry Kasparov",
    "Mihail Tal": "Mikhail Tal", "V Anand": "Viswanathan Anand",
    "M Carlsen": "Magnus Carlsen", "V Kramnik": "Vladimir Kramnik",
    "L Aronian": "Levon Aronian", "V Topalov": "Veselin Topalov",
    "A Shirov": "Alexei Shirov", "William Steinitz": "Wilhelm Steinitz",
    "JH. Bauer": "Johann Bauer", "Curt Von Bardeleben": "Curt von Bardeleben",
}

INITIAL = re.compile(r"\b([A-Z])\.?\s+(?=[A-Z][a-z])")


def tidy(name):
    """"Kasparov, Garry" is how a database writes it; nobody says it that way."""
    if "," in name:
        family, given = name.split(",", 1)
        name = f"{given.strip()} {family.strip()}"
    name = " ".join(name.split())
    if name in ALIASES:
        return ALIASES[name]
    # "Boris V Spassky" — a middle initial nobody uses.
    parts = name.split()
    if len(parts) == 3 and len(parts[1].rstrip(".")) == 1:
        name = f"{parts[0]} {parts[2]}"
    return ALIASES.get(name, name)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--local", help="directory of .pgn files already downloaded")
    parser.add_argument("--out", default="data/classics.json")
    parser.add_argument("--limit", type=int, default=900)
    args = parser.parse_args()

    if args.local:
        sources = [str(p) for p in Path(args.local).glob("*.pgn")]
    else:
        folder = Path(".classics-cache")
        folder.mkdir(exist_ok=True)
        sources = []
        for player in PLAYERS:
            target = folder / f"{player}.pgn"
            if not target.exists():
                print(f"  fetching {player}", file=sys.stderr)
                with urllib.request.urlopen(SOURCE.format(player), timeout=60) as response:
                    data = response.read()
                with zipfile.ZipFile(io.BytesIO(data)) as archive:
                    name = archive.namelist()[0]
                    target.write_bytes(archive.read(name))
            sources.append(str(target))

    found = collect(sources)
    # Mates first, then the shortest: the two things that make a game worth
    # watching rather than studying.
    found.sort(key=lambda g: (not g["notable"], len(g["moves"].split()), g["white"]))
    found = found[: args.limit]

    payload = {
        "note": (
            "Game scores from published collections of the players' own games "
            "(pgnmentor.com). Scores of played games are matters of record; "
            "no annotations are included."
        ),
        "games": found,
    }
    Path(args.out).write_text(json.dumps(payload, ensure_ascii=False) + "\n")
    named = [g for g in found if g["notable"]]
    print(f"{len(found)} games -> {args.out}  ({len(named)} of the named ones found)")
    for game in named:
        print(f"    {game['white']} — {game['black']}, {game['event']} {game['year']}")


if __name__ == "__main__":
    main()
