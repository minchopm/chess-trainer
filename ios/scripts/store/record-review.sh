#!/bin/sh
# The screen recording App Review asks for: the Mac app, launched from Finder,
# walked through the flow a customer takes, with the real cursor on real
# buttons. Apple asked for it on 1.1 for macOS (Guideline 2.1, Sep 2026); what it
# has to show, and why, is in review-notes.md.
#
#     sh ios/scripts/store/record-review.sh            # builds Release, waits, records
#     APP=/path/Brass\ Pawn.app sh ...                 # an app already built
#     NOWAIT=1 sh ...                                  # start now; you are away already
#
# It drives this Mac's own mouse, so it waits until nobody is using it: ninety
# seconds with no input and no video playing. Then it takes about four minutes,
# and it stops the moment the cursor moves or anything but Brass Pawn (or the
# Finder window it launches from) comes to the front — a take that stops is a
# take to reshoot, a click that lands in somebody's browser is not.
#
# Needs: Accessibility and Screen Recording for whatever runs it, ffmpeg, and a
# Release build with the engine networks in it (fetch-networks.sh).
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
IOS=$(cd "$HERE/../.." && pwd)
WORK=${WORK:-$IOS/build/review}   # ignored by git; a take is hundreds of MB
mkdir -p "$WORK"
WORK=$(cd "$WORK" && pwd)
D="$WORK/drive"
export DRIVE_STATE="$WORK/drive-state"
RAW="$WORK/take.mp4"
OUT="$WORK/BrassPawn-AppReview-macOS.mp4"
# The window, in points. The board's square positions below are measured for
# exactly this size: change it and they have to be measured again.
X=144; Y=100; W=1440; H=900
REC=""

log()  { echo "[$(date +%H:%M:%S)] $*"; }
stop_recording() { if [ -n "$REC" ]; then kill -INT "$REC" 2>/dev/null; wait "$REC" 2>/dev/null; REC=""; fi; }
fail() { log "ABORT: $*"; stop_recording; exit 1; }

# — The app: a Release build, copied into a folder of its own so the launch is
# a double-click on one icon in an otherwise empty Finder window.
if [ -z "${APP:-}" ]; then
    log "building Release"
    xcodebuild -project "$IOS/BrassPawn.xcodeproj" -scheme BrassPawn -configuration Release \
        -destination 'platform=macOS,variant=Mac Catalyst,arch=arm64' \
        -derivedDataPath "$WORK/dd" build > "$WORK/build.log" 2>&1 || fail "build failed, see $WORK/build.log"
    APP="$WORK/dd/Build/Products/Release-maccatalyst/BrassPawn.app"
fi
rm -rf "$WORK/stage"; mkdir -p "$WORK/stage/Brass Pawn"
ditto "$APP" "$WORK/stage/Brass Pawn/Brass Pawn.app" || fail "could not stage the app"
export APP_PATH="$WORK/stage/Brass Pawn/Brass Pawn.app"
xcrun swiftc -O "$HERE/review-drive.swift" -o "$D" || fail "the driver did not build"

# — Where each square of the round board is on screen. A board seen in
# perspective is a plane under a homography, so the four corners of the grid fix
# every square; the centres are not evenly spaced up the board.
/usr/bin/python3 - "$X" "$Y" > "$WORK/squares.json" <<'PY'
import json, sys
a1, h1, a8, h8 = (57.5, 782.5), (754.0, 782.5), (172.5, 310.0), (639.0, 310.0)
def solve(M, b):
    n = len(b); M = [r[:] + [b[i]] for i, r in enumerate(M)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                k = M[r][c] / M[c][c]; M[r] = [x - k * y for x, y in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]
A, b = [], []
for (u, v), (x, y) in zip([(0, 0), (1, 0), (0, 1), (1, 1)], [a1, h1, a8, h8]):
    A.append([u, v, 1, 0, 0, 0, -u * x, -v * x]); b.append(x)
    A.append([0, 0, 0, u, v, 1, -u * y, -v * y]); b.append(y)
h = solve(A, b) + [1.0]
ox, oy = float(sys.argv[1]), float(sys.argv[2])
out = {}
for f in range(8):
    for r in range(8):
        u, v = (f + 0.5) / 8, (r + 0.5) / 8
        w = h[6] * u + h[7] * v + h[8]
        out["abcdefgh"[f] + str(r + 1)] = [ox + (h[0] * u + h[1] * v + h[2]) / w,
                                           oy + (h[3] * u + h[4] * v + h[5]) / w]
print(json.dumps(out))
PY

tap()  { EXACT=1 "$D" tap "$@" || fail "tap $*"; }
tapc() { "$D" tap "$@" || fail "tap $*"; }
waitfor() { "$D" waitfor "$1" "${2:-20}" || fail "never saw: $1"; }
square() {
    xy=$(/usr/bin/python3 -c "import json; print(*json.load(open('$WORK/squares.json'))['$1'])")
    # shellcheck disable=SC2086
    "$D" click $xy || fail "square $1"
}
move()  { square "$1"; sleep 0.45; square "$2"; }
hover() { xy=$("$D" find "$1") || fail "find $1"; "$D" move $xy 0.8 || fail "hover $1"; }

# — The window's frame, saved by a proper quit so the launch opens it in place.
"$D" quit 2>/dev/null; sleep 2
open -g "$APP_PATH"
for _ in $(seq 1 60); do "$D" winget >/dev/null 2>&1 && break; sleep 0.5; done
"$D" win "$X" "$Y" "$W" "$H" >/dev/null || fail "could not place the window"
sleep 1; "$D" quit; sleep 3

# — Wait until the Mac is left alone.
if [ "${NOWAIT:-0}" != 1 ]; then
    log "waiting for 90 seconds without input and without video"
    while :; do
        idle=$("$D" idle)
        playing=$(pmset -g assertions | grep "PreventUserIdleDisplaySleep" | grep "pid" | grep -vicE "caffeinate|powerd")
        [ "$idle" -ge 90 ] && [ "$playing" -eq 0 ] && break
        sleep 5
    done
fi
log "starting"

# — Finder, showing the one icon, filling the frame.
open -R "$APP_PATH"; sleep 2.5
TARGET=finder WINDOW_TITLE="Brass Pawn" "$D" win "$X" "$Y" "$W" "$H" >/dev/null || fail "no Finder window"
TARGET=finder WINDOW_TITLE="Brass Pawn" "$D" raise; sleep 1.2
[ "$("$D" front)" = "Finder" ] || fail "Finder is not in front"
# Icons, not a list. Finder keeps the view per folder, so only this one changes.
TARGET=finder "$D" key 18 cmd || fail "icon view"; sleep 1.5
"$D" park $((X + 556)) $((Y + 720))

# — Roll. ffmpeg rather than `screencapture -v`: the latter falls behind
# encoding a Retina screen in real time and drops the backlog when it is
# stopped, which cost the first delivered take its last forty seconds.
rm -f "$RAW"
ffmpeg -hide_banner -loglevel error -y -f avfoundation -pixel_format nv12 \
    -capture_cursor 1 -capture_mouse_clicks 1 -framerate 30 -i "Capture screen 0:none" \
    -vf "crop=$((W * 2)):$((H * 2)):$((X * 2)):$((Y * 2)),scale=1920:1200:flags=lanczos,format=yuv420p" \
    -c:v h264_videotoolbox -b:v 16M "$RAW" < /dev/null &
REC=$!
sleep 3

log "1  launch"
TARGET=finder WINDOW_TITLE="Brass Pawn" MAXW=400 ROLE=AXImage "$D" dtap "Brass Pawn" || fail "no app icon in Finder"
for _ in $(seq 1 12); do "$D" running && break; sleep 0.5; done
if ! "$D" running; then
    log "   the icon did not open it; the name will"
    TARGET=finder WINDOW_TITLE="Brass Pawn" MAXW=400 ROLE=AXTextField "$D" dtap "Brass Pawn" || fail "no app in Finder"
fi
for _ in $(seq 1 60); do "$D" winget >/dev/null 2>&1 && break; sleep 0.5; done
waitfor "PLAY · TRAIN · WATCH" 30
sleep 6

log "2  play against the engine, coached"
tap "Play"; waitfor "START GAME"; sleep 2
tap "START GAME"; sleep 2
move e2 e4; sleep 2; waitfor "Your move." 40; sleep 3
move g1 f3; sleep 2; waitfor "Your move." 40; sleep 3
move f1 c4; sleep 2; waitfor "Your move." 40; sleep 3.5
tapc "Takeback"; sleep 3
tapc "Hint"; sleep 4          # every piece that can move, ringed
tapc "Hint"; sleep 5          # and the move
tap "Back"; sleep 1.5
if "$D" has "Leave" 2>/dev/null; then tap "Leave"; fi
waitfor "PLAY · TRAIN · WATCH"; sleep 2

log "3  settings: no account anywhere"
tap "Settings"; waitfor "ENGINE"; sleep 2.5
"$D" reveal "LICENCES, CREDITS" $((X + 720)) $((Y + 500)) || fail "about never came into view"
sleep 2.5
tapc "LICENCES, CREDITS"; waitfor "Read the full licence"; sleep 3.5
"$D" scroll $((X + 720)) $((Y + 500)) -420 || fail "scroll about"; sleep 3.5
tap "Back"; sleep 1.5
tap "Back"; waitfor "PLAY · TRAIN · WATCH"; sleep 2

log "4  a training mode, then the paywall"
tap "TACTICS"; waitfor "Solution"; sleep 3.5
tapc "Hint"; sleep 3.5
tapc "Hint"; sleep 4
tapc "Solution"; sleep 3
waitfor "Next puzzle" 20; sleep 4
tapc "Next puzzle"; sleep 3
tap "Back"; sleep 1.5
if "$D" has "Leave" 2>/dev/null; then tap "Leave"; fi
waitfor "PLAY · TRAIN · WATCH"; sleep 2
# The paywall is shown, never used: nothing is bought on camera.
tap "Brass Pawn Pro"; waitfor "Restore purchases"; sleep 3
hover "Renews automatically"; sleep 1.5
hover "No renewal"; sleep 1.5
hover "Restore purchases"; sleep 2
tap "Back"; waitfor "PLAY · TRAIN · WATCH"; sleep 2

log "5  multiplayer"
# The lobby, not a search. Pressing Find Opponent could pair this take with a
# real stranger and then walk out on them, which costs them rating.
tap "Play"; sleep 2
tap "online"; waitfor "FIND OPPONENT"; sleep 3
# The lobby rebuilds when Game Center reports in, and the clocks are not in the
# tree until it has.
EXACT=1 "$D" waitfor "ten" 20 || fail "the clocks never appeared"
tap "ten"; sleep 2.5
EXACT=1 hover "FIND OPPONENT"; sleep 2.5
tap "play"; sleep 1.5
tap "Back"; waitfor "PLAY · TRAIN · WATCH"; sleep 4

log "done"
stop_recording

# — The file Apple gets: smaller than the capture, and indexed at the front so
# it plays while it loads. A contact sheet beside it, to check every step.
ffmpeg -v error -y -i "$RAW" -vf "fps=30,format=yuv420p" -c:v libx264 -preset slow -crf 21 \
    -movflags +faststart -an "$OUT" || fail "encode"
ffmpeg -v error -y -i "$OUT" -vf "fps=1/8,scale=480:-2,tile=4x8:padding=6:color=black" \
    -frames:v 1 "$WORK/sheet.png"
ffprobe -v error -show_entries format=duration,size -of default=nw=1 "$OUT"
log "written: $OUT"
