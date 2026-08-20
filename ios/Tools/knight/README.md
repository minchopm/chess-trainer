# The knight

The one piece a lathe cannot turn, so the one piece that is modelled.

```bash
blender --background --python ios/Tools/knight/knight.py -- --out DIR --preview
```

Writes `knight.usdz` (which SceneKit reads directly) and, with `--preview`, a
render to look at.

## Why it is generated and not downloaded

A bought or downloaded model is a licence to check, and most of the good ones
are Creative Commons **NonCommercial** — which this app cannot use: it sells a
subscription and a one-off unlock, and it is GPLv3 besides, which forbids
adding a restriction like NC on top. The outline here is the app's own, the
geometry is generated from it, and the piece carries no licence into the build.

## Where the shape lives

The outline is a run of **measured anchors**, and the app carries the same run
in `TurnedPieces.knightAnchors` — this script is where they are fitted and
looked at, not a second source of truth. Change one, change the other.

## How it is built

A closed outline, traced as beziers and straight runs, filled and extruded as a
**curve** rather than as a mesh. That matters: every hand-rolled version —
sweeping the outline into rings, filling the faces with a triangle fan,
subdividing and solidifying — either bridged straight across the throat notch
or blew up into spikes. Blender's curve code tessellates a concave outline
correctly and rolls the rim over in one step.

The mane is a second curve in brass, standing a little proud of the head. It is
the crest's own anchors offset inwards, so it cannot drift off the edge when the
head is reshaped, and it stops below the ears — carried further it breaks out
through the back of the skull, because the outline turns in there and a strip
offset sideways does not.

## Proportions

Measured off the reference set's profile rather than guessed at, which is what
the reference is for. Three readings that look obvious and are wrong:

- The **ears** are not two tall triangles. What stands above the forehead is
  mostly the mane, cut off square, with one small ear showing behind it and the
  other hidden. Drawn as blades it comes out a rabbit.
- The **muzzle** does not taper. Its front runs all but straight down, then
  turns under. A taper makes a fox; a round makes a seal.
- The **neck** is broad — arching back at half height and flaring to the collar,
  not rising as a stalk.
