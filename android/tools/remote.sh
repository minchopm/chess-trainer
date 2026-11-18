#!/bin/bash
# Build and run the Android app on the second Mac, where the Android SDK, the
# NDK and the emulator live — this Mac is shared by too much else.
#
#   tools/remote.sh push                 mirror what the build needs to the second Mac
#   tools/remote.sh gradle <args…>       run Gradle there (android/)
#   tools/remote.sh build                push + assembleDebug
#   tools/remote.sh emulator             start this app's own emulator (headless), if it is not running
#   tools/remote.sh install              install the debug APK on it
#   tools/remote.sh launch [am extras…]  start the app (fresh process)
#   tools/remote.sh shot <name>          screenshot into android/shots/<name>.png
#   tools/remote.sh adb <args…>          adb against this app's emulator
#   tools/remote.sh ui                   dump the accessibility tree (text, descriptions, bounds)
#   tools/remote.sh tap "<label>"        tap the centre of the node with that text or description
#
# The emulator is this app's own (AVD BrassPawn_API_36 on port 5580), so nothing
# here touches the emulators other work is using.
set -euo pipefail

HOST="${BRASSPAWN_REMOTE:-photovault-render}"
DIR="BrassPawn-android/src"
SERIAL="emulator-5580"
AVD="BrassPawn_API_36"
PACKAGE="com.artesoft.brasspawn"
SDK='$HOME/Library/Android/sdk'
JBR='/Applications/Android Studio.app/Contents/jbr/Contents/Home'
here="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$here/.." && pwd)"

remote() { ssh -o BatchMode=yes "$HOST" "$@"; }
adb() { remote "$SDK/platform-tools/adb -s $SERIAL $(printf '%q ' "$@")"; }

case "${1:-}" in
push)
    remote "mkdir -p $DIR/android"
    cd "$repo"
    rsync -a --delete -R \
        --exclude 'android/build' --exclude 'android/*/build' --exclude 'android/.gradle' \
        --exclude 'android/.kotlin' --exclude 'android/local.properties' --exclude 'android/shots' \
        --exclude 'android/app/.cxx' --exclude '.DS_Store' \
        android \
        data/tactics.json data/positions.json data/endgames.json data/classics.json data/games.json \
        ios/Vendor/Stockfish/src ios/Vendor/Stockfish/bridge \
        ios/Resources/BoardAssets.xcassets ios/Resources/Assets.xcassets/BrassIcons \
        ios/Resources/Sounds ios/Resources/Fonts ios/Resources/Legal \
        ios/Resources/Networks/nn-*.nnue \
        ios/Resources/AppIcon.icon ios/App/Localizable.xcstrings \
        "$HOST:$DIR/"
    remote "echo sdk.dir=$SDK > $DIR/android/local.properties"
    ;;
gradle)
    shift
    remote "cd $DIR/android && JAVA_HOME='$JBR' ANDROID_HOME=$SDK ./gradlew --console=plain $(printf '%q ' "$@")"
    ;;
build)
    "$0" push
    "$0" gradle :app:assembleDebug "${@:2}"
    ;;
emulator)
    if remote "$SDK/platform-tools/adb devices" | grep -q "^$SERIAL"; then
        echo "$SERIAL is running"
        exit 0
    fi
    if ! remote "$SDK/emulator/emulator -list-avds" | grep -qx "$AVD"; then
        remote "echo no | JAVA_HOME='$JBR' $SDK/cmdline-tools/latest/bin/avdmanager create avd -n $AVD \
            -k 'system-images;android-36;google_apis_playstore;arm64-v8a' -d pixel_9 --force >/dev/null"
        remote "printf 'hw.ramSize=2048\nhw.keyboard=yes\ndisk.dataPartition.size=6G\n' >> \$HOME/.android/avd/$AVD.avd/config.ini"
    fi
    # Headless, host GPU (software rendering makes the whole system unresponsive), no audio device.
    remote "nohup $SDK/emulator/emulator -avd $AVD -port 5580 -no-window -no-audio -gpu host \
        -no-snapshot-save -no-boot-anim >\$HOME/BrassPawn-android/emulator.log 2>&1 &"
    remote "$SDK/platform-tools/adb -s $SERIAL wait-for-device shell 'while [ \"\$(getprop sys.boot_completed)\" != 1 ]; do sleep 2; done'"
    echo "$SERIAL booted"
    ;;
install)
    adb install -r "$DIR/android/app/build/outputs/apk/debug/app-debug.apk" 2>/dev/null \
        || remote "$SDK/platform-tools/adb -s $SERIAL install -r \$HOME/$DIR/android/app/build/outputs/apk/debug/app-debug.apk"
    ;;
launch)
    shift
    adb shell am force-stop "$PACKAGE"
    adb shell am start -n "$PACKAGE/.MainActivity" "$@"
    ;;
shot)
    mkdir -p "$here/shots"
    remote "$SDK/platform-tools/adb -s $SERIAL exec-out screencap -p" > "$here/shots/$2.png"
    echo "$here/shots/$2.png"
    ;;
adb)
    shift
    adb "$@"
    ;;
ui)
    adb shell uiautomator dump /sdcard/ui.xml >/dev/null
    adb exec-out cat /sdcard/ui.xml | python3 "$here/tools/ui_nodes.py"
    ;;
tap)
    adb shell uiautomator dump /sdcard/ui.xml >/dev/null
    point="$(adb exec-out cat /sdcard/ui.xml | python3 "$here/tools/ui_nodes.py" --find "$2")"
    [ -n "$point" ] || { echo "no node labelled: $2" >&2; exit 1; }
    adb shell input tap $point
    ;;
*)
    sed -n '2,16p' "$0"
    exit 1
    ;;
esac
