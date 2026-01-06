#!/bin/bash

function finish() {
  result=$?
  # Your cleanup code here
  exit ${result}
}
trap finish EXIT ERR

COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m' # No Color (Reset)

error_msg() {
  # Use -e to enable interpretation of backslash escapes
  echo -e "${COLOR_RED}Error: $1${COLOR_RESET}"  >&2
}

if ! command -v rsync &>/dev/null; then
  error_msg "rsync is needed for firefox profile on ram"
  exit 255
fi

#Clears the Internal Field Separator (IFS) variable for the current shell environment
#Thereby removing default word-splitting behavior
IFS=

set -o errexit   # abort on nonzero exitstatus
set -o noglob    # Disable pathname expansion
set -o nounset   # abort on unbound variable
set -o pipefail  # don't hide errors within pipes
set -o noclobber # not overwrite an existing file redirection operators
set -o errtrace

cd ~/.mozilla/firefox || exit

profile=7ffqcodd.default-release
static=$profile-static

if ! { test -L $profile || test -d $profile; }; then
  if test -d $static; then
    mv "$static" "$profile"
  else
    error_msg "Firefox profile  $(pwd)${profile} doesn't exist"

    profile=$(find -O3 . -maxdepth 1 \( -type l -or -type d \) -regex ".+release$" | cut --characters 3-)

    error_msg "The detected profile on your system is ${profile} so replace '\$profile' in the script with this"

    exit 254
    fi
fi

volatile=/dev/shm/firefox-$profile-$USER

if ! test -r "$volatile"; then
  mkdir -m0700 "$volatile"
fi

if [[ "$(readlink "$profile")" != "$volatile" ]]; then
  mv "$profile" "$static"
  ln -s "$volatile" "$profile"
fi

if test -e "$profile"/.unpacked; then
  rsync --archive --verbose --delete --exclude .unpacked ./"$profile"/ ./"$static"/
else
  rsync --archive --verbose ./"$static"/ ./"$profile"/
  touch "$profile"/.unpacked
fi

# catch signals and exit
# trap exit SIGINT SIGTERM EXIT
# main "$@"
