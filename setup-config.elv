# TODO: transition to PREFIXED paths and segregate into termux and linux/wsl
sudo ln --interactive --symbolic --relative --verbose /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf /etc/fonts/conf.d/
sudo ln --interactive --symbolic --relative --verbose etc/pacman.d/pacman.conf /etc/pacman.d/
ln fzf/rgf.sh /home/ultracode/.local/bin/rgf
ln ssh/config /home/ultracode/.ssh/
ln terminal/kitty/ $E:XDG_CONFIG_HOME/
ln fzf/fzt.sh /home/ultracode/.local/bin/fzt
ln git/ ~/.config/
ln -s /home/ultracode/.config/dotfiles/elvish/ /home/ultracode/.config/elvish
sudo cp etc/xdg/reflector/reflector.conf /etc/xdg/reflector/reflector.conf
ln fontconfig/fonts.conf $E:XDG_CONFIG_HOME/
cp etc/pacman.d/pacman.conf /etc/pacman.d/pacman.conf
ln procps/ $E:XDG_CONFIG_HOME/
sudo cp etc/systemd/journald.conf.d/journald.conf /etc/systemd/journald.conf.d/
sudo mkdir -p /etc/systemd/logind.conf.d ; sudo cp etc/systemd/logind.conf.d/logind.conf /etc/systemd/logind.conf.d/
sudo mkdir -p /etc/systemd/sleep.conf.d ; sudo cp etc/systemd/sleep.conf.d/sleep.conf /etc/systemd/sleep.conf.d/
sudo cp etc/systemd/resolved.conf.d/resolved.conf /etc/systemd/resolved.conf.d/
sudo cp etc/systemd/network/13-usb-ethernet.network /etc/systemd/network/20-usb-ethernet.network
sudo cp etc/iwd/main.conf /etc/iwd/
ln zig/zig-update.elv /home/ultracode/.local/bin/zig-update
ln mako/ $E:XDG_CONFIG_HOME/
sudo cp etc/modules-load.d/* /etc/modules-load.d/
sudo cp etc/modprobe.d/* /etc/modprobe.d/
sudo cp etc/udev/rules.d/* /etc/udev/rules.d/
sudo cp etc/sysctl.d/* /etc/sysctl.d/
sudo cp etc/fstab /etc/fstab
ln config/* $E:XDG_CONFIG_HOME/
ln mako/ $E:XDG_CONFIG_HOME/
md $E:XDG_CONFIG_HOME/gnupg
ln config/gnupg/* $E:XDG_CONFIG_HOME/gnupg/
ln config/zls.json $E:XDG_CONFIG_HOME/
# mpd and ncmcpp create folder and link the config into these folders
# just like for gnupg
md $E:XDG_CONFIG_HOME/{mpd{/playlist} ncmpcpp}
ln config/mpd/* $E:XDG_CONFIG_HOME/mpd/
ln config/ncmpcpp/* $E:XDG_CONFIG_HOME/ncmpcpp/
# link efm-language-server config
ln efm-langserver/ $E:XDG_CONFIG_HOME/
Ln /bin/helix /bin/hx
Cp etc/makepkg.conf.d/makepkg.conf /etc/makepkg.conf.d/makepkg.conf

# TODO: Integrate Turmux setup config (ADD PEFIXES)
ln config/gnupg/* $E:XDG_CONFIG_HOME/gnupg/
ln config/git/ ~/.config/
ln -s ~/.config/dotfiles/elvish/ ~/.config/elvish
ln -s mimeapps.list $E:XDG_CONFIG_HOME
