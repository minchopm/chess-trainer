#!/bin/sh
# Builds the vendored Reckless engine into an xcframework for iOS.
#
# Committed, and so normally not something anybody has to run: the xcframework it
# produces is twelve megabytes a slice and lives in the repository. Run it when
# the engine itself changes — then commit what comes out.
#
# Produces Vendor/Reckless/CReckless.xcframework with four slices: the device
# (aarch64-apple-ios), the simulator (aarch64-apple-ios-sim), Mac Catalyst
# (aarch64-apple-ios-macabi) and macOS (aarch64-apple-darwin). Catalyst is the
# Mac build of the app itself. Plain macOS is not there to run anything — it is
# there because `swift test` builds for the host, and the engine tests are the
# ones that matter. The two are different platforms to the linker even on the
# same machine, so both slices have to exist.
#

# Requires Rust 1.85 or newer — the crate is edition 2024:
#   rustup target add aarch64-apple-ios aarch64-apple-ios-sim aarch64-apple-ios-macabi
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/Vendor/Reckless"

# --no-default-features drops two things. Syzygy, whose build script needs clang
# and bindgen to compile Fathom, and which is not something a phone carries
# anyway. And `embedded-network`, which is the expensive one: with the network
# compiled in, each slice was 141 MB — the 60 MB file stored twice, once as data
# and once inside the bitcode fat LTO emits — against 235 KB of engine. Four
# slices of that is 564 MB, which is why this xcframework could not be committed
# and why everybody needed a Rust toolchain to produce it for themselves.
#
# The app loads the same network from its bundle instead, the way it already
# does for Stockfish. `fetch-networks.sh` puts it there.
for target in aarch64-apple-ios aarch64-apple-ios-sim \
              aarch64-apple-ios-macabi x86_64-apple-ios-macabi aarch64-apple-darwin; do
    echo "building $target ..."
    cargo build --manifest-path "$CRATE/Cargo.toml" \
        --release --no-default-features --lib --target "$target"
    # Debug symbols the app has no use for: 20 MB a slice becomes 12. The
    # library is committed, so this is repository weight rather than disk.
    strip -S "$CRATE/target/$target/release/libreckless.a"
done

# Catalyst ships both architectures — an App Store archive builds for arm64 and
# x86_64, and a Mac slice missing one will not link — so the two are lipo'd into
# a single library and the xcframework carries one fat Catalyst slice rather than
# two that would collide.
FAT="$CRATE/target/maccatalyst-libreckless.a"
lipo -create \
    "$CRATE/target/aarch64-apple-ios-macabi/release/libreckless.a" \
    "$CRATE/target/x86_64-apple-ios-macabi/release/libreckless.a" \
    -output "$FAT"

# The modulemap travels with the header so Swift can `import CReckless`.
HEADERS="$CRATE/target/xcframework-headers"
rm -rf "$HEADERS"
mkdir -p "$HEADERS"
cp "$CRATE/bridge/include/reckless.h" "$CRATE/bridge/include/module.modulemap" "$HEADERS/"

rm -rf "$CRATE/CReckless.xcframework"
xcodebuild -create-xcframework \
    -library "$CRATE/target/aarch64-apple-ios/release/libreckless.a" -headers "$HEADERS" \
    -library "$CRATE/target/aarch64-apple-ios-sim/release/libreckless.a" -headers "$HEADERS" \
    -library "$FAT" -headers "$HEADERS" \
    -library "$CRATE/target/aarch64-apple-darwin/release/libreckless.a" -headers "$HEADERS" \
    -output "$CRATE/CReckless.xcframework" >/dev/null

echo
echo "  $CRATE/CReckless.xcframework"
