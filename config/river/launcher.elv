#!/usr/bin/env elvish
use str
use re
use os
use file
use path

var name = (path:base (src)[name])

# Check if fzf is available
if (not (has-external fzf)) {
    echo "error: fzf is required to use "$name"." >&2
    exit 3
}

# Help message
var help-msg = ^
  'launcher help

   ctrl-d       desktop mode (default)
   ctrl-e       exe mode

   Enter       Confirm selection

   ?           Help (this page)
   ESC         Quit'

# Desktop entries
var desktop-store = /tmp/$name.store.desktop
var desktop-names
if (os:exists $desktop-store) {
  set desktop-names = (slurp < $desktop-store)
} else {
  set desktop-names = [(find /usr/share/applications -name '*.desktop' 2>/dev/null |
    peach {|file|
      var base = (path:base $file)
      put (str:trim-suffix $base .desktop)
    })]

  print $desktop-names > $desktop-store
}

# Unique executables in PATH
var exe-store = /tmp/$name.store.exe
var uniq-exe-names
if (os:exists $exe-store) {
  set uniq-exe-names = (slurp < $exe-store)
} else {
  set uniq-exe-names = [
    put (all $paths | peach {|dir|
      if (path:is-dir $dir) {
        find -L $dir -maxdepth 1 -type f -executable 2>/dev/null
      }
    } | peach {|file| path:base $file } | order | compact)
  ]

  print $uniq-exe-names > $exe-store
}

# Command strings for fzf
var default-command = 'all '(print $desktop-names)' | peach {|file| printf "%s\n" $file}'
var alt-command = 'all '(print $uniq-exe-names)' | peach {|file| printf "%s\n" $file}'

try {
  # Create a tmp file for user input state
  var user-input = (os:temp-file $name'.*')

  # Cleanup resources on closure exit
  defer {
      file:close $user-input
      os:remove $user-input[name]
  }

  # Initialize state
  print 'desktop' > $user-input[name]

  # Setup fzf environment variable
  set-env FZF_DEFAULT_COMMAND $default-command

  # Run fzf with all bindings
  fzf ^
    --no-multi ^
    --with-shell='elvish -c' ^
    --height '100%' ^
    --layout 'reverse-list' ^
    --margin '3%' ^
    --padding '3%' ^
    --info 'hidden' ^
    --header 'Press ? for help or ESC to quit' ^
    --prompt 'desktop > ' ^
    --bind "enter:execute@
        var state = (slurp < "$user-input[name]")
        if (eq $state 'desktop') {
            riverctl spawn 'gtk-launch {}'
        } else {
            riverctl spawn 'ghostty -e {}'
        }
    @+abort" ^
    --bind "ctrl-d:unbind(ctrl-d)+reload("$default-command")+change-prompt(desktop > )+execute-silent(print 'desktop' > "$user-input[name]")+rebind(ctrl-e)+rebind(?)+toggle-preview" ^
    --bind "ctrl-e:unbind(ctrl-e)+reload("$alt-command")+change-prompt(executable > )+execute-silent(print 'terminal' > "$user-input[name]")+rebind(ctrl-d)+rebind(?)+toggle-preview" ^
    --preview-window 'bottom,40%' ^
    --bind "?:unbind(?)+preview(print '"$help-msg"')+rebind(ctrl-d)+rebind(ctrl-e)" ^
} catch err {
  # fzf always exits with 130 even when it executes sucessfully
  if (eq  $err[reason][exit-status] 130) { } else {
    put $err
    fail "Error executing fzf"
  }
}
