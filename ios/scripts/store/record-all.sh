#!/bin/sh
# Three previews in every language the app ships in.
#
# The two Canadas are copies rather than shoots: their catalogues are
# byte-identical to the Englishes and Frenches they follow, so the recording
# would be the same file made twice.
set -e
HERE="$(dirname "$0")"

# The simulator to drive. Named rather than baked in: an identifier from
# somebody else's machine is a script that works in one place and quietly does
# the wrong thing everywhere else.
UD="${SIMULATOR_UDID:-}"
if [ -z "$UD" ]; then
  UD=$(xcrun simctl list devices booted -j 2>/dev/null \
       | awk -F'"' '/"udid"/ { print $4; exit }')
fi
if [ -z "$UD" ]; then
  echo "No booted simulator. Boot one, or set SIMULATOR_UDID." >&2
  exit 1
fi
OUT="${STORE_OUT:-$PWD/build/store}/videos"
SCENES="demoWatch demoTactics demo"
SHOOT="en-US ar-SA cs da de-DE el es-ES fi fr-FR he hi hu id it ja ko ms nl-NL no pl pt-BR ro ru sv th tr vi zh-Hans zh-Hant"
COPIES="en-CA=en-US fr-CA=fr-FR"

# Built once here rather than ninety-three times below.
xcodebuild -project ios/BrassPawn.xcodeproj -scheme BrassPawn \
  -configuration Debug -destination "id=$UD" \
  -derivedDataPath "${STORE_OUT:-$PWD/build/store}/dd" build >/dev/null
export SKIP_BUILD=1

for loc in $SHOOT; do
  for scene in $SCENES; do
    file="$OUT/$loc-$scene.mp4"
    # Already recorded: skip, so this is re-runnable after one language went
    # wrong without shooting the other twenty-eight again.
    [ -f "$file" ] && continue
    # Three attempts. A take now and then opens on a still frame — the
    # recorder waking up, a pause between two title games — and the check
    # below is the only thing between that and a store listing. It found one
    # bad take in four on a quiet machine, so a batch of ninety-three without
    # it would have shipped a handful.
    n=1
    while [ $n -le 3 ]; do
      sh "$HERE/record.sh" "$scene" "$loc" 24 >/dev/null 2>"$OUT/.err"
      bad=$(grep -o "still:.*" "$OUT/.err" || true)
      length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null)
      short=$(awk -v d="${length:-0}" 'BEGIN { print (d < 15 || d > 31) ? "short" : "" }')
      [ -z "$bad" ] && [ -z "$short" ] && break
      echo "  retaking $loc/$scene: $bad$short"
      rm -f "$file"
      n=$((n + 1))
    done
    [ -f "$file" ] || echo "  GAVE UP on $loc/$scene"
  done
  echo "recorded $loc"
done

for pair in $COPIES; do
  target="${pair%%=*}"; source="${pair##*=}"
  for scene in $SCENES; do
    cp "$OUT/$source-$scene.mp4" "$OUT/$target-$scene.mp4"
  done
  echo "copied $source -> $target"
done

echo "done: $(ls "$OUT"/*.mp4 | wc -l | tr -d ' ') videos"
