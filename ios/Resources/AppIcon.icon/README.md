# AppIcon.icon — the app icon

This is the app icon. There is no `AppIcon.appiconset` beside it any more: two
things named AppIcon is a coin toss that `actool` happens to win the right way,
and one of them is a decision.

`project.yml` refers to it as `type: file`, so the generator hands the bundle to
`actool` as one wrapper instead of recursing into it as a group. An older
comment in that file said this could not be done with XcodeGen. It can.

What it buys, over the flat 1024 the icon used to be, is the three appearances
iOS 26 asks for — light, dark and tinted — which you can confirm in a build:

```
xcrun assetutil --info BrassPawn.app/Assets.car | grep IconImageStack
```

## The layer must stay square

`icon.json` has one layer, and it has to be the **square** artwork. Icon
Composer applies Apple's mask itself.

Give it the finished iOS export instead — which is what it arrived as — and the
layer's own curve reaches full opacity about 332px in on a 1024 icon while
Apple's mask corner is about 229. Between them is a ring where the layer is
transparent and the mask is not, and through it shows this document's `fill`,
which is `extended-srgb:0.000, 0.533, 1.000`. A blue rim on all four corners.

`web/tools/icons.py` writes the square layer here, from the same artwork it
cuts the favicon and the social card from:

```bash
python3 web/tools/icons.py
```

Re-export from Icon Composer and you will overwrite it with a rounded one
again. Run the script afterwards.

## Worth looking at on a device

The tinted appearance turns the icon monochrome, and this one is a photograph.
`"translucency": {"enabled": true, "value": 0.5}` in `icon.json` is what
governs how that reads. It has not been judged on hardware.
