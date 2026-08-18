#!/bin/sh
# Downloads the two Stockfish neural networks the app ships.
#
# They are ~107 MB together and are not committed: they are build inputs with a
# canonical source, and their exact names are pinned by the engine version in
# Vendor/Stockfish. Run this once after cloning.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$ROOT/Resources/Networks"
mkdir -p "$DIR"

BIG=$(grep -o 'nn-[a-f0-9]*\.nnue' "$ROOT/Vendor/Stockfish/src/evaluate.h" | head -1)
SMALL=$(grep -o 'nn-[a-f0-9]*\.nnue' "$ROOT/Vendor/Stockfish/src/evaluate.h" | tail -1)

for net in "$BIG" "$SMALL"; do
    if [ -f "$DIR/$net" ]; then
        echo "already present: $net"
        continue
    fi
    echo "downloading $net ..."
    curl -sL --fail "https://tests.stockfishchess.org/api/nn/$net" -o "$DIR/$net"
done

echo
ls -lh "$DIR" | tail -n +2 | awk '{printf "  %-26s %s\n", $9, $5}'
