#!/usr/bin/env elvish

# Switch between Ripgrep launcher mode (CTRL-R) and fzf filtering mode (CTRL-F)
use str
use os
use flag
use path

fn cleanup {|result|
  rm -f /tmp/rg-fzf-{r,f} stderr>$os:dev-null
  if (not (eq $result 0)) { exit $result}
}

fn grep-cmd {|path|
    var cmd = [
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
    put (str:join " " $cmd)
}

var usage = ^
'Usage:
rgf $path $query
'

fn rgf {|@args|
    var path = "."
    var query = ""

    var argc = (count $args)

    put "count "$argc
    if (> $argc 0) {
        set path = $args[0]
        if (not (or (path:is-dir $path) (path:is-regular $path))) {
            print $usage
            fail "Path '"$path"' does not exist or isn't a directory"
        }
    }

    if (> $argc 1) {
      set query = (str:join " " $args[1..])
    }

    var exit-code = 0
    try {
        var rg-prefix =  (grep-cmd $path)
        # Pipe empty stdin to fzf since fzf search ability is disabled initially
        printf "" | fzf --ansi --disabled --query $query ^
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
}
