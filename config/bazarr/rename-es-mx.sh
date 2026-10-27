#!/bin/sh
# Bazarr post-processing: Jellyfin does not parse the "es-MX" language tag Bazarr
# uses for Spanish (Latino, es-419), so the stream shows no language. Rename the
# freshly downloaded subtitle to the plain ".es" form, which Jellyfin recognises.
# Usage (Bazarr command): /config/rename-es-mx.sh "{{subtitles}}"
f="$1"
case "$f" in
  *.es-MX.srt|*.es-MX.hi.srt|*.es-MX.forced.srt) ;;
  *) exit 0 ;;
esac
dir=$(dirname "$f")
base=$(basename "$f")
new="$dir/$(printf '%s' "$base" | sed 's/\.es-MX\./.es./')"
# Never clobber an existing plain-es subtitle. Keep the es-MX file instead of deleting it, so
# Bazarr still counts Spanish (Latino) as present and does not search for it again.
[ -e "$new" ] || mv -- "$f" "$new"
exit 0
