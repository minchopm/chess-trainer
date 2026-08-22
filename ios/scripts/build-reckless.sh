#!/bin/sh
# Builds the vendored Reckless engine into an xcframework for iOS.
#
# Produces Vendor/Reckless/CReckless.xcframework with three slices: the device
# (aarch64-apple-ios), the simulator (aarch64-apple-ios-sim), and macOS
# (aarch64-apple-darwin). macOS is not there to run the app — it is there because
# `swift test` builds for the host, and the engine tests are the ones that matter.
#
# Neither the xcframework nor the network is committed: both are build outputs or
# build inputs with a canonical source, in the same spirit as fetch-networks.sh.
#
# Requires Rust 1.85 or newer — the crate is edition 2024:
#   rustup target add aarch64-apple-ios aarch64-apple-ios-sim
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CRATE="$ROOT/Vendor/Reckless"

NETWORK="v60-7f587dfb.nnue"
NETWORK_URL="https://github.com/codedeliveryservice/RecklessNetworks/releases/download/networks/$NETWORK"

# Vendor the network rather than let build.rs fetch it, so a build never reaches
# the network. build.rs honours EVALFILE and resolves a relative path against the
# crate root.
mkdir -p "$CRATE/networks"
if [ ! -f "$CRATE/networks/$NETWORK" ]; then
    echo "downloading $NETWORK (63 MB) ..."
    curl -sL --fail "$NETWORK_URL" -o "$CRATE/networks/$NETWORK"
fi
EVALFILE="networks/$NETWORK"
export EVALFILE

# --no-default-features drops Syzygy, whose build script needs clang and bindgen
# to compile Fathom. Tablebases are not something a phone carries anyway.
for target in aarch64-apple-ios aarch64-apple-ios-sim aarch64-apple-darwin; do
    echo "building $target ..."
    cargo build --manifest-path "$CRATE/Cargo.toml" \
        --release --no-default-features --lib --target "$target"
done

# The modulemap travels with the header so Swift can `import CReckless`.
HEADERS="$CRATE/target/xcframework-headers"
rm -rf "$HEADERS"
mkdir -p "$HEADERS"
cp "$CRATE/bridge/include/reckless.h" "$CRATE/bridge/include/module.modulemap" "$HEADERS/"

rm -rf "$CRATE/CReckless.xcframework"
xcodebuild -create-xcframework \
    -library "$CRATE/target/aarch64-apple-ios/release/libreckless.a" -headers "$HEADERS" \
    -library "$CRATE/target/aarch64-apple-ios-sim/release/libreckless.a" -headers "$HEADERS" \
    -library "$CRATE/target/aarch64-apple-darwin/release/libreckless.a" -headers "$HEADERS" \
    -output "$CRATE/CReckless.xcframework" >/dev/null

echo
echo "  $CRATE/CReckless.xcframework"
