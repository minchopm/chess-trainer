#!/bin/sh
# Downloads the three neural networks the app ships: two for Stockfish and one
# for Reckless.
#
# They are ~167 MB together and are not committed: they are build inputs with a
# canonical source, and their exact names are pinned by the engine versions in
# Vendor/. Run this once after cloning — it is the only setup step, and it needs
# nothing but curl.
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

# Reckless's, which the engine used to compile into itself. Its name is pinned by
# the vendored crate, the way Stockfish's are pinned by evaluate.h — but it is
# saved under a fixed name, because the app has to find it in a bundle where
# every network is a .nnue and the version in the real name changes under it.
RK_NAME=$(grep -o 'v[0-9]*-[a-f0-9]*\.nnue' "$ROOT/Vendor/Reckless/build/build.rs" | head -1)
RK_URL="https://github.com/codedeliveryservice/RecklessNetworks/releases/download/networks/$RK_NAME"

if [ -f "$DIR/reckless.nnue" ]; then
    echo "already present: reckless.nnue ($RK_NAME)"
else
    echo "downloading $RK_NAME as reckless.nnue ..."
    curl -sL --fail "$RK_URL" -o "$DIR/reckless.nnue"
fi

echo
ls -lh "$DIR" | tail -n +2 | awk '{printf "  %-26s %s\n", $9, $5}'
