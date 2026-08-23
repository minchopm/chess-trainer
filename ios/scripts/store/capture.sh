#!/bin/sh
# Store screenshots, every language, no tapping.
#
# The app is opened straight into a named scene by a launch argument, so the
# only thing that changes between languages is the words. Duplicated locales —
# the two Englishes, the two Frenches — are shot once and copied, because their
# catalogues are byte-identical.
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
OUT="${STORE_OUT:-$PWD/build/store}/screenshots"
# Overridable, because the iPad listing wants a handful rather than all of
# them and shooting seven in twenty-nine languages to use three is an hour
# spent on pictures nobody will look at.
SCENES="${SCENES:-menu playSetup playCoached playMistake playValues boardEngines watchList}"

# One capture per distinct translation set.
SHOOT="${ONLY:-en-US ar-SA cs da de-DE el es-ES fi fr-FR he hi hu id it ja ko ms nl-NL no pl pt-BR ro ru sv th tr vi zh-Hans zh-Hant}"
# Locales that get a copy of another's pictures, as "target=source".
COPIES="en-CA=en-US fr-CA=fr-FR"

mkdir -p "$OUT"

# Built once, here, rather than trusting whatever is on the simulator. The
# recording script learned this the hard way: it had been launching a build
# from weeks earlier without anybody noticing.
DD="${STORE_OUT:-$PWD/build/store}/dd"
xcodebuild -project ios/BrassPawn.xcodeproj -scheme BrassPawn \
  -configuration Debug -destination "id=$UD" -derivedDataPath "$DD" \
  build >/dev/null
APP="$DD/Build/Products/Debug-iphonesimulator/BrassPawn.app"

for loc in $SHOOT; do
  mkdir -p "$OUT/$loc"
  # Erased between languages. The store should show the app as it arrives —
  # walnut board, system face — and not as this simulator was left after
  # somebody spent an afternoon trying the other themes. It also hands each
  # language its own unspent free allowance, so no picture is of a paywall.
  xcrun simctl terminate $UD $APP_ID >/dev/null 2>&1 || true
  xcrun simctl uninstall $UD $APP_ID >/dev/null 2>&1 || true
  xcrun simctl install $UD "$APP"
  READY="$(xcrun simctl get_app_container $UD $APP_ID data)/Documents/shot-ready"
  n=0
  for scene in $SCENES; do
    n=$((n + 1))
    shot="$OUT/$loc/$(printf '%02d' $n)-$scene.png"
    # Already taken: skip. Makes the whole thing re-runnable after a new scene
    # is added, without shooting the twenty-eight languages again.
    [ -f "$shot" ] && continue
    xcrun simctl terminate $UD $APP_ID >/dev/null 2>&1 || true
    rm -f "$READY"
    xcrun simctl launch $UD $APP_ID \
      -shot "$scene" \
      -AppleLanguages "($loc)" \
      -AppleLocale "$(echo "$loc" | tr '-' '_')" >/dev/null 2>&1
    # Wait for the app to say the scene is arranged, rather than for a number
    # of seconds. The numbers were tuned on a warm simulator; a first launch
    # after a fresh install takes long enough that they photographed a black
    # screen, or the menu still sitting over the screen that was asked for.
    i=0
    while [ ! -f "$READY" ] && [ $i -lt 120 ]; do sleep 0.5; i=$((i + 1)); done
    [ -f "$READY" ] || echo "  $loc/$scene: never became ready"
    # A breath for the last animation to land.
    sleep 1
    xcrun simctl io $UD screenshot "$shot" >/dev/null 2>&1
  done
  echo "captured $loc"
done

for pair in $COPIES; do
  target="${pair%%=*}"; source="${pair##*=}"
  rm -rf "$OUT/$target"; cp -R "$OUT/$source" "$OUT/$target"
  echo "copied $source -> $target"
done

xcrun simctl terminate $UD $APP_ID >/dev/null 2>&1 || true
echo "done: $(find "$OUT" -name '*.png' | wc -l | tr -d ' ') pictures in $(ls "$OUT" | wc -l | tr -d ' ') folders"
