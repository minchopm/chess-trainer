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

## How it is built

A closed outline, traced as beziers and straight runs, filled and extruded as a
**curve** rather than as a mesh. That matters: every hand-rolled version —
sweeping the outline into rings, filling the faces with a triangle fan,
subdividing and solidifying — either bridged straight across the throat notch
or blew up into spikes. Blender's curve code tessellates a concave outline
correctly and rolls the rim over in one step.

The mane is a second curve in brass, standing a little proud of the head.
