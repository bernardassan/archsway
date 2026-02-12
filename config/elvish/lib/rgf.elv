#!/usr/bin/env elvish

# Switch between Ripgrep launcher mode (CTRL-R) and fzf filtering mode (CTRL-F)
use str

var path = "."
if (> (count $args) 0) {
    var user-path = $args[0]
    if (path:is-dir $user-path) {
        set path = $user-path
    } elif (path:is-regular $user-path) {
        set path = $user-path
    } else {
        echo "Expected the first argument to rgf to be a path"
        echo "Path '"$user-path"' does not exist or isn't a directory"
        exit 1
    }
}

fn cleanup {|result|
  rm -f /tmp/rg-fzf-{r,f} 2>/dev/null
  exit $result
}

var initial-query = ""
if (> (count $args) 1) {
  set initial-query = (str:join " " $args[1..])
}

var grep-cmd = [
    env
    LC_ALL=C
    grep
    --perl-regexp
    --color=always
    --line-number
    --binary-files=without-match
    --devices=skip
    --exclude='''.*'''
    --exclude-dir={'''.[a-zA-Z0-9]*''' '''*cache*''' zig-out zig-pkg node_modules build dist target vendor __pycache__}
    --ignore-case
    --recursive
    '"'$path'"'
    --regexp
]
var rg-prefix =  (str:join " " $grep-cmd)

var exit-code = 0

try {
    # Pipe empty stdin to fzf since fzf search ability is disabled initially
    printf "" | fzf --ansi --disabled --query $initial-query ^
      --with-shell='elvish -c' ^
      --bind "start:reload("$rg-prefix" {q})+unbind(ctrl-r)" ^
      --bind "change:reload:"$rg-prefix" {q}" ^
      --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f)" ^
      --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload("$rg-prefix" {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r)" ^
      --color "hl:-1:underline,hl+:-1:underline:reverse" ^
      --prompt '1. ripgrep> ' ^
      --delimiter : ^
      --header '╱ CTRL-R (ripgrep mode) ╱ CTRL-F (fzf mode) ╱' ^
      --preview 'bat --color=always {1} --highlight-line {2}' ^
      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' ^
      --bind 'enter:execute(hx {1} +{2})'
} catch err {
  set exit-code = $err[reason][exit-status]
  # fzf always exits with 130 even when it executes sucessfully
  if (eq  $exit-code 130) { set exit-code = 0 } else { put $err }

} finally {
    cleanup $exit-code
}
