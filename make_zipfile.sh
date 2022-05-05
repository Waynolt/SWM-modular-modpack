#!/bin/bash

filename="SWM_modular_modpack_v$(cat 'VERSION')_E19.zip"
[ -e "$filename" ] && rm "$filename"
zip -r "${filename}" 'Mods/' 'LICENCE' 'README.md'

exit $?
