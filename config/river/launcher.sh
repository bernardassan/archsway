#!/bin/bash
readonly name=$0

if ! which fzf &>/dev/null; then
  printf "error: fzf is required to use %s.\n" "${name}" >&2
  exit 3
fi

declare user_input
if ! user_input="$(mktemp --tmpdir "${name}.input.XXXXXXXXX")"; then
  print "error: Failed to create tmp file. $TMPDIR (or /tmp if $TMPDIR is unset) may not be writable.\n" >&2
  exit 4
fi
trap 'rm -f $user_input &> /dev/null' EXIT

# quote 'EOF' ensures that the text block is taken literally (no expansion)
readarray -t HELP_MSG <<'EOF'
launcher help

ctrl-d       desktop mode (default)
ctrl-e       exe mode

Enter       Confirm selection

?           Help (this page)
ESC         Quit
EOF

readarray -t DESKTOP_NAMES < <(
  find /usr/share/applications -name '*.desktop' 2>/dev/null |
    while IFS= read -r file; do
      filename=${file##*/}        # strip path → basename
      echo "${filename%.desktop}" # strip extension
    done
)

readarray -t UNIQ_EXE_NAMES < <(
  IFS=:
  for dir in $PATH; do
    find -L "$dir" -maxdepth 1 -type f -executable 2>/dev/null
  done | while IFS= read -r file; do
    echo "${file##*/}" # strip directory
  done | sort -u
)

readonly DEFAULT_COMMAND="printf '%s\n' ${DESKTOP_NAMES[*]}"
readonly ALT_COMMAND="printf '%s\n' ${UNIQ_EXE_NAMES[*]}"
HELP=$(printf "printf '%%s\\n' %s" "$(printf ' %q' "${HELP_MSG[@]}")")
echo "$HELP"

echo "desktop" >"$user_input" &&
  FZF_DEFAULT_COMMAND=$DEFAULT_COMMAND \
    fzf \
    --no-multi \
    --with-shell="bash -c" \
    --height "100%" \
    --layout reverse-list \
    --margin "3%" \
    --padding "3%" \
    --info hidden \
    --header "Press ? for help or ESC to quit" \
    --prompt "desktop > " \
    --bind "enter:execute@
        state=\$(<$user_input)
        if [[ \$state == 'desktop' ]]; then
            riverctl spawn 'gtk-launch {}'
        else
            riverctl spawn 'ghostty -e {}'
        fi
    @+abort" \
    --bind "ctrl-d:unbind(ctrl-d)+reload($DEFAULT_COMMAND)+change-prompt(desktop > )+execute-silent(echo 'desktop' > '$user_input')+rebind(ctrl-e)" \
    --bind "ctrl-e:unbind(ctrl-e)+reload($ALT_COMMAND)+change-prompt(executable > )+execute-silent(echo 'terminal' > '$user_input')+rebind(ctrl-d)" \
    --bind "?:preview:($HELP)" \
    --preview-window "bottom,40%"
