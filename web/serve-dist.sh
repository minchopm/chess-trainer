#!/bin/sh
# Serve the production build, with media/ mounted where the deployed site has it.
#
# The dev server cannot show the localised pages: media/ is deliberately outside
# the Angular build, so nothing serves /media under `ng serve`. This serves the
# real artefact instead — the same files the bucket gets — and resolves /media
# out of the project directory.
#
# It resolves rather than symlinks because `ng build` empties its output
# directory, which silently takes a symlink with it: the pages then look right,
# every film 404s, and it reads as a bug in the player.
exec python3 "$(dirname "$0")/tools/serve-dist.py" "${1:-4401}"
