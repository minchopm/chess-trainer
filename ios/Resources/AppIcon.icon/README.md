# AppIcon.icon — the Icon Composer document

Kept here so the icon has a source in the repository rather than only on
somebody's Desktop. **It is not wired into the build.** The app icon is still
the flat square at `Assets.xcassets/AppIcon.appiconset/AppIcon.png`, which
`web/tools/icons.py` writes from the same artwork.

Two things have to be true before switching, and neither is today.

## The layer is the wrong image

`icon.json` names `brasspawnAppicon-iOS-Default-1024x1024@1x.png` as its only
layer — and that file is the *finished* export, with Apple's squircle already
cut out of its alpha. Icon Composer expects the artwork; it applies the mask
itself.

The consequence is visible. The layer's own curve reaches full opacity about
332px in from the corner on a 1024 icon. Apple's mask corner is about 229px.
Between the two there is a ring where the layer is transparent and the mask is
not, and what shows through it is the document's `fill` — which is
`extended-srgb:0.000, 0.533, 1.000`, a blue. A blue fringe around all four
corners.

The fix is in Icon Composer, not here: give the layer the square artwork.

## The project generator has to be able to see it

`project.yml` lists resources by explicit path, so this directory is inert
until something adds it. Wiring it means a `sources:` entry, pointing
`ASSETCATALOG_COMPILER_APPICON_NAME` at `AppIcon.icon` rather than the
appiconset, retiring `AppIcon.appiconset`, and running `xcodegen` — which
rewrites `project.pbxproj` wholesale.
