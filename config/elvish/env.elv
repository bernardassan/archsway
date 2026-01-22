use os
use path
use runtime
use str
use platform

set-env PREFIX ( if (has-env PREFIX) { put $E:PREFIX } else { put '' } )
set-env XDG_CACHE_HOME (put $E:HOME | path:join (all) .cache)
set-env XDG_CONFIG_HOME (put $E:HOME | path:join (all) .config)
set-env XDG_LOCAL_HOME (put $E:HOME | path:join (all) .local)
set-env XDG_DATA_HOME (put $E:XDG_LOCAL_HOME | path:join (all) share)
set-env XDG_STATE_HOME (put $E:XDG_LOCAL_HOME | path:join (all) state)

set-env GNUPGHOME $E:XDG_CONFIG_HOME/gnupg
if (not (os:is-dir $E:GNUPGHOME)) {
     os:mkdir-all &perm=0o700 $E:GNUPGHOME
}

set-env DOTFILES (put $E:XDG_CONFIG_HOME | path:join (all) dotfiles)
set E:ELVRC = $E:DOTFILES/config/elvish

set-env GTK_THEME 'Adwaita:dark'
set-env QT_STYLE_OVERRIDE 'adwaita-dark'

set-env MANROFFOPT '-c'
set-env MANPAGER $runtime:elvish-path" -c 'col --no-backspaces --spaces | bat -l man --plain'"

# Setup debuginfo daemon for packages in the official repositories
if (os:is-regular $E:PREFIX/etc/debuginfod/archlinux.urls) {
     cat $E:PREFIX/etc/debuginfod/archlinux.urls | set-env DEBUGINFOD_URLS (all)
}

fn append-to-path {|env|
     if (not (str:contains $E:PATH $env)) {
          set paths =  (put $env | conj $paths (all))
     }
}

fn is-termux {
     # (eq (uname -m) aarch64)
     if (and (eq $platform:os "android") (eq $platform:arch "arm64") (has-env PREFIX)) {
          put  $true
     } else {
          put $false
     }
}
edit:add-var is-termux~ $is-termux~

fn is-wsl {
     if (and (eq $platform:os "linux") (eq $platform:arch "amd64") (has-env WSLENV)) {
          put $true
     } else {
          put $false
     }
}
edit:add-var is-wsl~ $is-wsl~

# Add local/bin to path env
if (is-wsl) {
     set paths = [/usr/local/sbin /usr/local/bin /usr/bin ~/.local/bin]
     # https://github.com/yuk7/ArchWSL/issues/389#issuecomment-2683928012
     set-env GALLIUM_DRIVER d3d12
} else {
     append-to-path ~/.local/bin
}

if (has-external modular) {
     set-env MODULAR_HOME (put $E:XDG_LOCAL_HOME | path:join (all) modular)
     var MOJO_PATH = (modular config mojo.path)
     append-to-path $MOJO_PATH/bin
     # INFO: since the only currently supported linux distro is ubuntu/debian
     # you need to get ncurses and libedit library from debian
     # https://github.com/Sharktheone/arch-mojo/blob/main/src/install.py#L156
     if (or (not (has-env LD_LIBRARY_PATH)) (not (get-env LD_LIBRARY_PATH | str:contains (all) lib/mojo))) {
          set E:LD_LIBRARY_PATH = $E:XDG_LOCAL_HOME/lib/mojo:$E:LD_LIBRARY_PATH
     }
}

# Alternative rustup dist servers
# Global
# https://static.rust-lang.org & https://static.rust-lang.org/rustup - Default
#
# Regional
# https://mirrors.tuna.tsinghua.edu.cn/rustup - Tsinghua University
# https://mirrors.ustc.edu.cn/rust-static & https://mirrors.ustc.edu.cn/rust-static/rustup - USTC China
#
# Example:
# $ env RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup rustup update
if (or (has-external rustup) (has-external rustc) (os:is-dir $E:XDG_LOCAL_HOME/cargo)) {
     set-env RUSTUP_HOME (put $E:XDG_LOCAL_HOME | path:join (all) rustup)
     set E:CARGO_HOME = (put $E:XDG_LOCAL_HOME | path:join (all) cargo)
     append-to-path $E:CARGO_HOME/bin
     var rustup_rust_analyzer = $E:PREFIX/usr/lib/rustup/bin
     if (os:is-dir $rustup_rust_analyzer) { append-to-path $rustup_rust_analyzer }
}

if (has-external bun) {
     var bun_path  = (put $E:XDG_CACHE_HOME/.bun/bin)
     append-to-path $bun_path
}

if (has-external go) {
     set E:GOPATH = (put $E:XDG_LOCAL_HOME | path:join (all) go)
     set-env GOBIN (put $E:GOPATH | path:join (all) bin)
     append-to-path $E:GOBIN
}

if (has-external composer) {
     set E:COMPOSER_HOME = (put $E:XDG_LOCAL_HOME | path:join (all) composer)
     append-to-path $E:COMPOSER_HOME/vendor/bin
}

if (has-external vivid) {
     # alabaster_dark ayu catppuccin-latte iceberg-dark one-dark
     set-env LS_COLORS (vivid generate alabaster_dark)
}

if (os:exists /home/linuxbrew/.linuxbrew/bin/brew) {
     set-env HOMEBREW_PREFIX /home/linuxbrew/.linuxbrew
     set-env HOMEBREW_CELLAR /home/linuxbrew/.linuxbrew/Cellar
     set-env HOMEBREW_REPOSITORY /home/linuxbrew/.linuxbrew/Homebrew
     append-to-path /home/linuxbrew/.linuxbrew/bin
     append-to-path /home/linuxbrew/.linuxbrew/sbin

     # When MANPATH starts with :, man uses the manpath command to
     # automatically discovers man page directories based on what's in your PATH
     if (has-env MANPATH) {
          set E:MANPATH = ':'(str:trim-prefix $E:MANPATH ':')
     }

     if (has-env INFOPATH) {
          var info_path = /home/linuxbrew/.linuxbrew/share/info:
          if (not (str:has-prefix $E:INFOPATH $info_path)) {
               set-env INFOPATH $info_path(put $E:INFOPATH)
          }
     } else {
          set-env INFOPATH /home/linuxbrew/.linuxbrew/share/info:
     }

}

if (has-external starship) {
     if (is-termux) {
       set E:STARSHIP_CONFIG = $E:DOTFILES/config/starship/termux.toml
     } else {
       set E:STARSHIP_CONFIG = $E:DOTFILES/config/starship/starship.toml
     }
  eval (starship init elvish)
}

if (has-external carapace) {
  # enable completions from these shells when completions aren't avilable in current shell
  set-env CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
  set-env CARAPACE_MATCH 1 # make completion matching case insensitive
  set-env CARAPACE_ENV 1 # enable environment variable completion
  set-env CARAPACE_LENIENT 1 # allow unknown flags
  eval (carapace _carapace | slurp)
}

# needed here for setting EDITOR env
fn which {|bin|
     if (is-termux) {
          var bin_path = [(whereis -b $bin | str:fields (all))][-1]
          if (not (os:exists $bin_path)) {
               fail "fn which: "(styled $bin_path green)(styled " doesn't exist or isn't in $PATH" bold red)
          } else {
               echo $bin_path
          }
     } else {
          e:which -a $bin
     }
}
edit:add-var which~ $which~

set-env EDITOR (
     if (has-external hx) { which hx } ^
     elif (os:is-regular $E:PREFIX/usr/lib/helix/hx) { append-to-path $E:PREFIX/usr/lib/helix ; print $E:PREFIX/usr/lib/helix/hx } ^
     elif (has-external helix) { which helix } ^
     elif (has-external nvim) { which nvim } ^
     else { which vim }
)

# Configure gpg pinentry to use the correct TTY
set-env GPG_TTY (tty)

if (not (has-env SSH_AUTH_SOCK)) {
     if (has-external gpgconf) {
          set-env SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
     }
}
