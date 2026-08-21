#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <atlas.png> <Assets.xcassets>" >&2
    exit 64
fi

atlas=$1
catalog=$2
destination="$catalog/BrassIcons"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg is required to split the atlas" >&2
    exit 69
fi

names=(
    arrow.counterclockwise arrow.uturn.backward arrow.up.right backward.end.fill
    backward.fill backward.frame bolt.horizontal.circle chart.line.uptrend.xyaxis
    checkmark.circle checkmark.circle.fill chevron.backward chevron.left
    chevron.right cube creditcard doc.text
    equal.circle exclamationmark.triangle eye flag.checkered
    flag.fill forward.end forward.end.fill forward.fill
    forward.frame gearshape infinity lightbulb
    lock.shield magnifyingglass number.square pause.fill
    play.fill play.rectangle plus.circle speaker.slash.fill
    speaker.wave.2.fill sparkles square.grid.3x3 square.grid.3x3.middle.filled
    stop.circle target trophy.fill trash
    xmark.circle xmark.circle.fill timer chess
)

# The generated atlas keeps a regular eight-column layout, but the visual rows
# are not exactly equal-height. These boundaries fall in the transparent gaps
# so no glow or drop shadow gets clipped before the alpha trim.
x_edges=(0 241 454 665 853 1047 1254 1469 1774)
y_edges=(0 174 325 465 604 720 887)

mkdir -p "$destination"

cat > "$destination/Contents.json" <<'JSON'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

for row in {0..5}; do
    for column in {0..7}; do
        index=$((row * 8 + column))
        name=${names[$index]}
        x=${x_edges[$column]}
        y=${y_edges[$row]}
        width=$((x_edges[column + 1] - x))
        height=$((y_edges[row + 1] - y))
        imageset="$destination/$name.imageset"
        output="$imageset/$name.png"

        mkdir -p "$imageset"

        # First detect the non-transparent alpha bounds. The source background
        # is exact black, while the black enamel inside the icons is lifted and
        # remains intact at this deliberately narrow key tolerance.
        bbox_log=$(ffmpeg -hide_banner -i "$atlas" \
            -vf "crop=$width:$height:$x:$y,colorkey=0x000000:0.01:0.02,format=rgba,alphaextract,bbox=min_val=4" \
            -f null - 2>&1)
        bbox=$(printf '%s\n' "$bbox_log" | sed -nE 's/.*crop=([0-9]+:[0-9]+:[0-9]+:[0-9]+).*/\1/p' | tail -n 1)

        if [[ -z "$bbox" ]]; then
            echo "could not detect icon bounds for $name" >&2
            exit 65
        fi

        IFS=: read -r icon_width icon_height icon_x icon_y <<< "$bbox"
        margin=6
        trimmed_width=$((icon_width + margin * 2))
        trimmed_height=$((icon_height + margin * 2))
        side=$((trimmed_width > trimmed_height ? trimmed_width : trimmed_height))

        ffmpeg -y -hide_banner -loglevel error -i "$atlas" \
            -vf "crop=$width:$height:$x:$y,colorkey=0x000000:0.01:0.02,format=rgba,crop=$icon_width:$icon_height:$icon_x:$icon_y,pad=$side:$side:(ow-iw)/2:(oh-ih)/2:color=0x00000000,scale=256:256:flags=lanczos" \
            -frames:v 1 "$output"

        cat > "$imageset/Contents.json" <<JSON
{
  "images" : [
    {
      "filename" : "$name.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : false,
    "template-rendering-intent" : "original"
  }
}
JSON
    done
done

echo "wrote ${#names[@]} transparent icon assets to $destination"
