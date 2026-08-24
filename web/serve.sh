#!/bin/sh
# Dev server, for the editor's preview pane.
#
# Pins the Node the Angular CLI needs and runs from this directory, so the
# preview can be launched from a parent project without inheriting its Node.
cd "$(dirname "$0")" || exit 1
export PATH="/Users/minchomilev/.nvm/versions/node/v24.19.0/bin:$PATH"
exec npm start -- "$@"
