#!/bin/sh
# Copies the licence and attribution into the app's resources.
#
# They are duplicated because a bundle cannot reference a Markdown file outside
# it by extension, and the About screen reads plain .txt. Run this after editing
# either document at the repository root.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cp "$ROOT/LICENSE" "$ROOT/ios/Resources/Legal/LICENSE.txt"
cp "$ROOT/NOTICE.md" "$ROOT/ios/Resources/Legal/NOTICE.txt"
echo "legal texts synced into ios/Resources/Legal"
