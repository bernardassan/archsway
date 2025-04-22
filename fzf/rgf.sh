#!/bin/env bash
# Switch between Ripgrep launcher mode (CTRL-R) and fzf filtering mode (CTRL-F)
path="."
if test -n "$1"; then
  user_path=$1
  if test -d "$user_path"; then
    path=$user_path
  elif test -f "$user_path"; then
  # this case doesn't need bat try to fix it
    path=$user_path
  else
    echo "Expected the first argument to rgf to be a path"
    echo "Path '${user_path}' does not exist or isn't a directory"
    exit 1
  fi
fi

function finish() {
  result=$?
  # Your cleanup code here
  rm -f /tmp/rg-fzf-{r,f} &>/dev/null
  exit ${result}
}
trap finish EXIT SIGINT ERR SIGTERM

RG_PREFIX="grep --extended-regexp --color=always --recursive --line-number --binary-files=without-match --exclude='.*' --exclude-dir='.git' --exclude-dir='*cache*' --ignore-case $path --regexp"
# Assign elements from index 2 onwards with default empty array
INITIAL_QUERY="${*:2}"
: | fzf --ansi --disabled --query "$INITIAL_QUERY" \
  --bind "start:reload($RG_PREFIX {q})+unbind(ctrl-r)" \
  --bind "change:reload:$RG_PREFIX {q}" \
  --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f)" \
  --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload($RG_PREFIX {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r)" \
  --color "hl:-1:underline,hl+:-1:underline:reverse" \
  --prompt '1. ripgrep> ' \
  --delimiter : \
  --header '╱ CTRL-R (ripgrep mode) ╱ CTRL-F (fzf mode) ╱' \
  --preview 'bat --color=always {1} --highlight-line {2}' \
  --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
  --bind 'enter:execute(hx {1} +{2})'
