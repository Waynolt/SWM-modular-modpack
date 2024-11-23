#!/bin/bash

if [ ! -e 'LICENCE' ]; then
  echo 'ERROR: it appears the script has been run from the wrong folder' >&2
  echo 'It needs to be run from the repo'\''s base folder' >&2
  exit 1
fi

releases_folder='releases'
filename="${releases_folder}/SWM_modular_modpack_E19.zip"
included_items=(
  'Mods/'
  'LICENCE'
  'README.md'
  'VERSION'
)

mkdir -p "$releases_folder" || exit $?
[ -e "$filename" ] && rm "$filename" && echo "The old version of $filename has been deleted" >&2
echo "Generating $filename" >&2
zip -r "${filename}" "${included_items[@]}"

exit $?
