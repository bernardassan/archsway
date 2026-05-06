# TODO: transition to PREFIXED paths and segregate into termux and linux/wsl
# TODO: most of the Cp's can be Ln's
# Arch Linux
Ln /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf /etc/fonts/conf.d/
Cp $E:DOTFILES/etc/xdg/reflector/reflector.conf /etc/xdg/reflector/reflector.conf
Cp $E:DOTFILES/etc/pacman.d/pacman.conf /etc/pacman.d/pacman.conf
Cp $E:DOTFILES/etc/systemd/journald.conf.d/journald.conf /etc/systemd/journald.conf.d/
Cp $E:DOTFILES/etc/systemd/resolved.conf.d/resolved.conf /etc/systemd/resolved.conf.d/
Cp $E:DOTFILES/etc/systemd/network/13-usb-ethernet.network /etc/systemd/network/20-usb-ethernet.network
Cp $E:DOTFILES/etc/iwd/main.conf /etc/iwd/
Cp $E:DOTFILES/etc/modules-load.d/* /etc/modules-load.d/
Cp $E:DOTFILES/etc/modprobe.d/* /etc/modprobe.d/
Cp $E:DOTFILES/etc/udev/rules.d/* /etc/udev/rules.d/
Cp $E:DOTFILES/etc/sysctl.d/* /etc/sysctl.d/
Cp $E:DOTFILES/etc/fstab /etc/fstab
Md /etc/systemd/logind.conf.d ; Cp $E:DOTFILES/etc/systemd/logind.conf.d/logind.conf /etc/systemd/logind.conf.d/
Md /etc/systemd/sleep.conf.d ; Cp $E:DOTFILES/etc/systemd/sleep.conf.d/sleep.conf /etc/systemd/sleep.conf.d/
ln $E:DOTFILES/config/fontconfig/fonts.conf $E:XDG_CONFIG_HOME/
ln $E:DOTFILES/config/mako $E:XDG_CONFIG_HOME/
# mpd and ncmcpp create folder and link the config into these folders
md $E:XDG_CONFIG_HOME/{mpd{/playlist} ncmpcpp}
ln $E:DOTFILES/config/mpd/* $E:XDG_CONFIG_HOME/mpd/
ln $E:DOTFILES/config/ncmpcpp/* $E:XDG_CONFIG_HOME/ncmpcpp/
ln $E:DOTFILES/config/mimeapps.list $E:XDG_CONFIG_HOME/

# Arch Linux & WSL
ln $E:DOTFILES/config/procps $E:XDG_CONFIG_HOME/
Cp $E:DOTFILES/etc/pacman.d/pacman.conf /etc/pacman.d/
echo "Include = /etc/pacman.d/pacman.conf" | sudo tee -a /etc/pacman.conf
Cp $E:DOTFILES/etc/makepkg.conf.d/makepkg.conf /etc/makepkg.conf.d/makepkg.conf
# setup efm-language server config
ln $E:XDG_CONFIG_HOME/helix/efm-langserver $E:XDG_CONFIG_HOME/

# Arch Linux & WSL & Termux
ln $E:ELVRC $E:XDG_CONFIG_HOME/
ln $E:DOTFILES/config/gnupg/* $E:GNUPGHOME/
ln $E:DOTFILES/config/git/ $E:XDG_CONFIG_HOME/
