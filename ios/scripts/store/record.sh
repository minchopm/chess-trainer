#!/bin/sh
# One preview video.
#
# The app is launched first and held on the menu; the tape is started while it
# waits, and only then is it let go. Recording from before the launch and
# cutting the front off afterwards meant finding the cut by how bright the
# picture was, which mistook the home screen for the app, the app for the menu,
# and the menu for the board — a different wrong answer each run.
set -e
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
APP_ID=com.arte-soft.brasspawn
SCENE="${1:-demoWatch}"
LOC="${2:-en-US}"
LENGTH="${3:-26}"

OUT="${STORE_OUT:-$PWD/build/store}/videos"
mkdir -p "$OUT"
FILE="$OUT/$LOC-$SCENE.mp4"
rm -f "$FILE"

# Built and installed every time. This script used to launch whatever happened
# to be on the simulator, so weeks of fixes never reached a single recording.
DD="${STORE_OUT:-$PWD/build/store}/dd"
# Skipped when the caller has already built. A batch of ninety-three would
# otherwise spend an hour re-checking a build that cannot have changed.
if [ "${SKIP_BUILD:-0}" != "1" ]; then
  xcodebuild -project ios/BrassPawn.xcodeproj -scheme BrassPawn \
    -configuration Debug -destination "id=$UD" -derivedDataPath "$DD" \
    build >/dev/null
fi
# Erased first. A preview should show what somebody opening the app for the
# first time sees, and the free allowance is spent by every earlier run.
xcrun simctl uninstall $UD $APP_ID >/dev/null 2>&1 || true
xcrun simctl install $UD "$DD/Build/Products/Debug-iphonesimulator/BrassPawn.app"

CONTAINER=$(xcrun simctl get_app_container $UD $APP_ID data)
READY="$CONTAINER/Documents/shot-ready"
rm -f "$READY" "$CONTAINER/Documents/preview-go"
xcrun simctl launch $UD $APP_ID -shot "$SCENE" \
  -AppleLanguages "($LOC)" -AppleLocale "$(echo "$LOC" | tr '-' '_')" >/dev/null 2>&1
# Wait for the app to say the title board is drawn, rather than guessing how
# long a cold launch takes. Guessing put anything between four and eleven
# seconds of menu at the front of the file, depending on the day.
i=0
while [ ! -f "$READY" ] && [ $i -lt 180 ]; do sleep 0.5; i=$((i + 1)); done

xcrun simctl io $UD recordVideo --codec h264 "$FILE" >/dev/null 2>&1 &
REC=$!
# Long enough for the recorder to be writing frames rather than starting up.
sleep 6

# Let it go.
touch "$CONTAINER/Documents/preview-go"

sleep $((LENGTH + 18))
kill -INT $REC 2>/dev/null || true
wait $REC 2>/dev/null || true
xcrun simctl terminate $UD $APP_ID >/dev/null 2>&1 || true

# Cut to an exact length, front and back. The front trim is a fixed number
# rather than a search, because the moment the app was let go is known: it is
# `HEAD` seconds after the tape started, so this leaves a couple of seconds of
# menu before anything happens rather than however long the recorder took to
# wake up.
# Where the recorder actually started writing new frames. `recordVideo`
# repeats its first frame while it wakes up — anywhere between two and fourteen
# seconds — and the app is held on a moving menu the whole time, so anything
# still at the head of the file is the recorder rather than the app.
HEAD=$(python3 "$(dirname "$0")/stillness.py" "$FILE" --head)
HEAD=$(awk -v h="$HEAD" 'BEGIN { print (h < 0.5) ? 0.5 : h + 0.3 }')
TRIMMED="$OUT/$LOC-$SCENE-trimmed.mp4"
ffmpeg -v error -i "$FILE" -ss "$HEAD" -t "$LENGTH" -c:v libx264 -preset veryfast -crf 18 \
  -pix_fmt yuv420p -an "$TRIMMED" -y
mv "$TRIMMED" "$FILE"

# Refuse a take that stands still. Every fault found in these previews has been
# something not moving — a frozen frame left by a keyframe cut, a search typed
# behind the menu, a title board caught in the pause between two games, a game
# that never started — and every one was found by a person watching. Frames are
# compared rather than thresholded, because no single noise figure both catches
# a repeated frame and spares a camera orbiting a few pixels a second.
STILL=$(python3 "$(dirname "$0")/stillness.py" "$FILE")
if awk -v s="${STILL%% *}" 'BEGIN { exit (s > 2.0) ? 0 : 1 }'; then
  echo "still: ${STILL%% *}s at ${STILL##* }s" >&2
fi
echo "$FILE"
