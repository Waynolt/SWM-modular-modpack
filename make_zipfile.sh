#!/bin/bash

filename="SWM_modular_modpack_v$(cat 'VERSION')_E19"
[ -e "$filename" ] && rm "$filename"
zip -r "${filename}.zip" 'Mods/' 'LICENCE' 'README.md'

exit $?
