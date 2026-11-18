#!/bin/bash
# Runs on photovault-render against emulator-5580 ONLY: captures Brass Pawn's 7 localized storefront scenes.
#
# Usage (on photovault-render):
#   capture_remote.sh <phone|tablet|both|reset> <out-dir> [comma-separated-locales] [comma-separated-scenes]
#
# Strict rule: NEVER touch emulator-5554. Only emulator-5580 (BrassPawn_API_36) is used.
set -euo pipefail

SERIAL="emulator-5580"
if [ "$SERIAL" != "emulator-5580" ]; then
    echo "Refusing to run on any emulator other than emulator-5580" >&2
    exit 1
fi

ADB="$HOME/Library/Android/sdk/platform-tools/adb"
PACKAGE="com.artesoft.brasspawn"
START="am start -n $PACKAGE/.MainActivity"

MODE="${1:-both}"
OUT="${2:-$HOME/BrassPawn-android/storefront-shots}"
LOCALES_CSV="${3:-ar-SA,bg,bn-BD,ca,cs,da,de-DE,el,en-US,es-ES,es-MX,fi,fr-CA,fr-FR,gu-IN,he,hi,hr,hu,id,it,ja,kk,kn-IN,ko,ml-IN,mr-IN,ms,nb,nl-NL,or-IN,pa-IN,pl,pt-BR,pt-PT,ro,ru,sk,sl-SI,sv,ta-IN,te-IN,th,tr,uk,ur-PK,vi,zh-Hans,zh-Hant}"
SCENES_CSV="${4:-01-menu,02-playMistake,03-tactics,04-online,05-positional,06-playCoached,07-playSetup}"

a() { "$ADB" -s "$SERIAL" "$@"; }
demo() { a shell am broadcast -a com.android.systemui.demo "$@" >/dev/null; }

reset_display() {
    a shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
    demo -e command exit >/dev/null 2>&1 || true
    a shell cmd overlay disable com.android.internal.display.cutout.emulation.hole >/dev/null 2>&1 || true
    a shell wm size reset >/dev/null 2>&1 || true
    a shell wm density reset >/dev/null 2>&1 || true
    a shell settings put system user_rotation 0 >/dev/null 2>&1 || true
    a shell settings put system accelerometer_rotation 1 >/dev/null 2>&1 || true
    echo "reset $SERIAL display to defaults"
}

if [ "$MODE" = "reset" ]; then
    reset_display
    exit 0
fi

prepare_status_bar() {
    a shell settings put global sysui_demo_allowed 1
    demo -e command exit || true
    sleep 0.5
    demo -e command enter
    demo -e command clock -e hhmm 0941
    demo -e command notifications -e visible false
    demo -e command battery -e level 100 -e plugged false
    demo -e command network -e mobile hide
    demo -e command network -e wifi show -e level 4 -e fully true
    demo -e command status -e volume hide -e bluetooth hide -e location hide -e alarm hide -e sync hide -e mute hide -e speakerphone hide
    sleep 1.5
}

check_png() {
    local file="$1" want_w="$2" want_h="$3"
    [ -s "$file" ] || return 1
    local dims
    dims="$(sips -g pixelWidth -g pixelHeight "$file" 2>/dev/null | awk '/pixelWidth/{w=$2} /pixelHeight/{h=$2} END{print w"x"h}')"
    [ "$dims" = "${want_w}x${want_h}" ]
}

shoot_kind() {
    local kind="$1"
    local size density cutout want_w want_h
    if [ "$kind" = "phone" ]; then
        size="1280x2856"; density="480"; cutout="hole"; want_w="1280"; want_h="2856"
    elif [ "$kind" = "tablet" ]; then
        size="2560x1600"; density="320"; cutout=""; want_w="2560"; want_h="1600"
    else
        echo "Unknown kind: $kind" >&2
        exit 1
    fi

    echo "=== Preparing $kind ($size @ ${density}dpi) on $SERIAL ==="
    a shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
    a shell settings put system accelerometer_rotation 0
    a shell settings put system user_rotation 0
    if [ -n "$cutout" ]; then
        a shell wm size "$size"
        a shell wm density "$density"
        sleep 2
        a shell cmd overlay enable "com.android.internal.display.cutout.emulation.$cutout" || true
        sleep 2
    else
        a shell cmd overlay disable com.android.internal.display.cutout.emulation.hole >/dev/null 2>&1 || true
        a shell wm size "$size"
        a shell wm density "$density"
        sleep 2
        # Restart SystemUI cleanly after removing the phone cutout so the tablet status bar lays out unclipped.
        a shell pkill -f com.android.systemui >/dev/null 2>&1 || true
        sleep 4
    fi

    IFS=',' read -r -a LOCALES <<< "$LOCALES_CSV"
    IFS=',' read -r -a SCENES <<< "$SCENES_CSV"

    a logcat -c || true
    local first=1
    local settle="${SETTLE:-1.25}"

    for locale in "${LOCALES[@]}"; do
        mkdir -p "$OUT/$kind/$locale"
        local shot_any=0
        for scene in "${SCENES[@]}"; do
            local target="$OUT/$kind/$locale/$scene.png"
            if [ "${FORCE:-0}" != "1" ] && check_png "$target" "$want_w" "$want_h"; then
                continue
            fi
            shot_any=1
            local attempt=0
            while [ $attempt -lt 3 ]; do
                attempt=$((attempt + 1))
                if [ $first -eq 1 ]; then
                    a shell $START --es storefront_scene "$scene" --es storefront_locale "$locale" >/dev/null
                    for _ in $(seq 1 60); do
                        a logcat -d | grep -q "Displayed $PACKAGE" && break
                        sleep 0.5
                    done
                    sleep 2.5
                    prepare_status_bar
                    # Re-deliver once after SystemUI demo bar settles so insets are final.
                    a shell $START --activity-single-top --es storefront_scene "$scene" --es storefront_locale "$locale" >/dev/null 2>&1
                    sleep 1.5
                    first=0
                else
                    a shell $START --activity-single-top --es storefront_scene "$scene" --es storefront_locale "$locale" >/dev/null 2>&1
                    sleep "$settle"
                fi
                a exec-out screencap -p > "${target}.tmp"
                if check_png "${target}.tmp" "$want_w" "$want_h"; then
                    mv "${target}.tmp" "$target"
                    break
                fi
                echo "  retry $attempt for $kind/$locale/$scene (wrong dims or empty)" >&2
                rm -f "${target}.tmp"
                first=1
                a shell settings put system accelerometer_rotation 0
                a shell settings put system user_rotation 0
                a shell wm size "$size"
                a shell wm density "$density"
                sleep 2
            done
            if [ ! -f "$target" ]; then
                echo "FAILED: $kind/$locale/$scene" >&2
                exit 1
            fi
        done
        if [ $shot_any -eq 1 ]; then
            echo "[$kind] captured $locale"
        else
            echo "[$kind] verified cached $locale"
        fi
    done
}

case "$MODE" in
    phone)  shoot_kind phone ;;
    tablet) shoot_kind tablet ;;
    both)   shoot_kind phone; shoot_kind tablet ;;
    *)      echo "Unknown mode: $MODE" >&2; exit 1 ;;
esac

if [ "${RESET_AFTER:-0}" = "1" ]; then
    reset_display
fi
