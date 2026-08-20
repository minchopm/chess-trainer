# The knight

The one piece a lathe cannot turn, and so the one piece with a front, a back and
a shape of its own.

## Where the shape lives

In the app: `TurnedPieces.knightAnchors` in `ios/Sources/BoardScene/Knight.swift`
— the outline as measured anchors, plus the depth it is cut to at each height.
Look at it with

```bash
RENDER_KNIGHT=1 swift test --package-path ios --filter KnightAngles
```

which renders the geometry the app actually ships, from four angles. Use it for
anything that changes the head: it read perfectly from the side for a long time
while being flat from everywhere else, because the side was the only angle it
was ever looked at.

This directory used to build the head as well, in Blender. That was a mistake
worth recording: two builders of one shape drift apart the moment either is
changed, and this one did.

## What is here

`reference.py` renders a downloaded model orthographically from the side, the
front and three quarters. `measure.py` scans a render back into numbers — how
far the piece reaches at each height and how wide it is, in head-heights, so
they read straight into a piece of any size.

```bash
blender --background --python ios/Tools/knight/reference.py -- MODEL.glb --out /tmp/ref
python3 ios/Tools/knight/measure.py /tmp/ref/reference-side.png
python3 ios/Tools/knight/measure.py /tmp/ref/reference-front.png
```

## Why measure rather than copy

Most good models are Creative Commons **NonCommercial**, which this app cannot
use: it sells a subscription and a one-off unlock, and it is GPLv3 besides,
which forbids adding a restriction like NC on top. Proportions are not the
model. Nothing of it ships, and nothing of it is in this repository.

## What the measuring found

Three readings of a knight's head look obvious and are all wrong, and each cost
a round of drawing before the numbers settled it:

- The **ears** are not two tall triangles. What stands above the forehead is
  mostly the mane, cut off square with sharp corners, with one small ear showing
  behind it — a fortieth of the piece's height before the two merge. This is
  what the `runs` column of `measure.py` is for: at one height it reported two
  separate spans, which a min-and-max reading hides.
- The **muzzle** does not taper. Its front runs all but straight down for a
  tenth of the height before it turns under.
- The **neck** is broad, arching back to its fullest at half height and flaring
  to the collar — half again the width a knight is usually drawn with.
