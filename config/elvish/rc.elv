use os
use re
use str
use path
use unix

use ./env
use ./aliases
use ./modules

if ($env:is-wsl~) {
     # remove resource limits on core file generation
     if (has-key $unix:rlimits[core] cur) {
          del unix:rlimits[core][cur] # (unlimited)
     }

     fn enable-coredump {|&path=/tmp/core|
       var core_pattern = $path/"core.%P.%u.%g.%s.%t.%c.%h.%e"
       var actual_core_pattern = (str:trim-prefix (sysctl kernel.core_pattern) "kernel.core_pattern = ")
       try { var stat = (os:stat $path)
       } catch err { os:mkdir-all &perm=0o777 $path }

       if (not (eq $core_pattern $actual_core_pattern)) {
          try {
             sudo sysctl -w kernel.core_pattern=$core_pattern stdout>$os:dev-null
          } catch err {
             fail $err
          }
       }
     }
     edit:add-var enable-coredump~ $enable-coredump~
}

# elvish limited vi editing mode
set edit:insert:binding[Ctrl-'['] = $edit:command:start~

# Automatically run river window manager on virtual terminal tty 1-3
# On other ttys you must run manually with the tty option
fn start-river {|&tty=$false|
     if (or (re:match "/dev/tty[1-3]" (tty)) $tty) {
        # for river's log output to be handled by journald
          if (and (has-external river) (os:eval-symlinks $E:XDG_CONFIG_HOME/river/init | os:is-regular (all))) {
             # set XDG_CURRENT_DESKTOP
               set E:XDG_CURRENT_DESKTOP = river

               var deps = [
               &ghostty="terminal emulator"
               &openssh="ssh connectivity"
               &vivid="ls colors manager"
               &wl-clipboard="wayland copy/pasting"
               &rsync="remote/local file syncing"
               &starship="prompt customization"
               &git="version control"
               ]

               var optional_deps = [
               &mpc="music player keys control"
               &brightnessctl="for screen brightness control"
               &carapace-bin="shell completions"
               &grim="for screenshots"
               &waylock="for screen lock"
               &fuzzel="as menu launcher"
               &swayidle="idle state management"
               &imv="image viewer"
               &wpaperd="wayland wallaper daemon"
               &xdg-desktop-portal-wlr="screen sharing"
               &wlsunset="for night light/blue light management"
               &cliphist="for clipboard history"
               &slurp="for region slection during screenshots"
               &batsignal="for battery status notification"
               &kanshi="for automatic output management"
               &swaynag="for interactive section"
               &lswt="for listing wayland windows with their attributes"
               ]

               for package [(keys $deps)] {
                    if (not (has-external $package)) {
                         fail $package" is required "$deps[$package]
                    }
               }
               for package [(keys $optional_deps)] {
                    if (not (has-external $package)) {
                         echo $package" is optionally required "$optional_deps[$package]
                    }
               }
               if (not (os:is-regular $E:PREFIX/usr/share/sounds/freedesktop/stereo/camera-shutter.oga)) {
                    echo "sound-theme-freedesktop package is optionally required"
               }

               exec systemd-cat --identifier=river river -no-xwayland
        } else {
               echo "Either river is not installed or found in $E:PATH"
               echo "Also make sure that your river config is located at $E:XDG_CONFIG_HOME/river/init"
        }
     }
}
edit:add-var start-river~ $start-river~

start-river

fn cmdline-history-filter {|command|
     var ignorelist = [ ]
     for ignore $ignorelist {
          if (str:has-prefix $command $ignore) {
               put $false
               return
          }
          # filter sudo command with commands in the $ignorelist
          if (and (str:has-prefix $command sudo) (str:contains $command ' '$ignore' ')) {
               put $false
               return
          }
     }
     put $true
}
set edit:add-cmd-filters = (conj $edit:add-cmd-filters $cmdline-history-filter~)

# To use the included Secure Shell Agent you need to start the gpg agent
fn gpg-integration {
     if (has-external gpg-connect-agent) {
          gpg-connect-agent updatestartuptty /bye stderr>$os:dev-null stdout>&stderr
     }
}
gpg-integration

fn kitty-shell-integration {
     if (has-external kitty) {
          # https://iterm2.com/documentation-escape-codes.html
          # https://sw.kovidgoyal.net/kitty/shell-integration
          # https://codeberg.org/dnkl/foot/#supported-oscs
          # https://codeberg.org/dnkl/foot/wiki#shell-integration
          var OSC = (print (str:from-utf8-bytes 0x1b)(str:from-utf8-bytes 0x5d))
          var ST = (print (str:from-utf8-bytes 0x1b)(str:from-utf8-bytes 0x5c))

          fn osc {|code| print $OSC$code$ST }
          fn send-title {|title| osc '0;'$title }
          fn send-pwd {
               send-title (tilde-abbr $pwd | path:base (one))
               osc '7;'(put $pwd)
          }
          set edit:before-readline = [ { send-pwd } { osc '133;A' } ]
          set edit:after-readline = [
               {|c| send-title (str:split ' ' $c | take 1) }
               {|c| osc '133;C' }
          ]
          set after-chdir = [ {|_| send-pwd } ]
     }
}

# shell integration
if (eq $E:TERM "xterm-ghostty") {
     try {
       use ghostty-integration
     } catch { } # integration already loaded
} elif (eq $E:TERM "xterm-kitty") {
     kitty-shell-integration
 }
