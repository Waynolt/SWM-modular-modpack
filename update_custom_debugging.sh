#!/bin/bash

if [ ! -e 'LICENCE' ]; then
  echo 'ERROR: it appears the script has been run from the wrong folder' >&2
  echo 'It needs to be run from the repo'\''s base folder' >&2
  exit 1
fi

export SOURCE_FOLDER='custom_debugging'
export TARGET_FILENAME='custom_debugging'

checkbox() {
  option_num="$1"
  option_checked="$2"
  option_name="$3"
  echo -n "${option_num}. ["
  [ $option_checked -eq 0 ] && echo -n "x" || echo -n " "
  echo "] ${option_name}"
}

do_encrypt=1
do_decrypt=1
while true; do
  clear
  echo "What to do with ${SOURCE_FOLDER}?"
  if [ -e "${SOURCE_FOLDER}/00_password_reminder.txt" ]; then
    echo "(Reminder: the password is $(cat "${SOURCE_FOLDER}/00_password_reminder.txt"))"
  fi
  checkbox 1 "$do_encrypt" 'Encrypt'
  checkbox 2 "$do_decrypt" 'Decrypt'
  echo '3. Proceed'
  echo ''
  echo 'Selection:'
  read -r user_input
  case $user_input in
    1|2)
      do_encrypt=1
      do_decrypt=1;;&
    1)
      do_encrypt=0;;
    2)
      do_decrypt=0;;
    3)
      break;;
  esac
done
do_reload_gpg_agent=1

if [ $do_encrypt -eq 0 ]; then
  target_tar="${TARGET_FILENAME}.tar.gz"
  rm -f "$target_tar" || true
  rm -f "${target_tar}.gpg" || true
  tar -czf "$target_tar" "$SOURCE_FOLDER"
  gpg -c "$target_tar"
  rm -f "$target_tar"
  do_reload_gpg_agent=0
fi

if [ $do_decrypt -eq 0 ]; then
  gpg -d "${TARGET_FILENAME}.tar.gz.gpg" | \
  tar -xz
  do_reload_gpg_agent=0
fi

if [ $do_reload_gpg_agent -eq 0 ]; then
  # Delete any cached password
  echo RELOADAGENT | gpg-connect-agent
fi

exit $?
