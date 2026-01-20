# ArchSway
Archlinux on river/sway from scratch with the most minimal dependencies. DIY is awesome

# Standard Installation Steps
[Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)

# Filesystem Setup
- **ESP** [/efi](https://wiki.archlinux.org/title/EFI_system_partition#Create_the_partition) should be 2GiB if you plan on installing [efi applications](https://wiki.archlinux.org/title/Systemd-boot#UEFI_Shells_or_other_EFI_applications) like [arch rescue](https://codeberg.org/bernardassan/arch-rescue-image) else 512MiB otherwise
- **ROOT** should be a (_xfs_ for hdd | _f2fs_ for nvme) with a size of **30GiB** - **60GiB**
- **HOME** & **FILES** (_btrfs_ | _ext4_) partition with **HOME** between **60-120GiB** and **FILES** of __arbitrary size__ for multimedia content
- **ROOT** is mounted on `/` with the dedicated **HOME** &| **FILES** _subvolume_ | _partition_ mounted to `/home` and `/home/${username}/files` repectively.
- Setup [**zram**](https://github.com/bernardassan/archsway/blob/master/etc/udev/rules.d/zram.rules) `3x` RAM size to allow running more memory hungry tasks `.eg compiling llvm, clang, clang-tools, lldb`.
- Use a ZRAM backing device equal to RAM size **12GiB** and a [swap](https://github.com/bernardassan/archsway/blob/master/etc/fstab) partition for [**hibernation**](https://github.com/bernardassan/archsway/blob/master/etc/kernel/cmdline) also of size equal to RAM **12Gib**

**NOTE:**
- **make sure to create and mount Btrfs with Zstd compression on first mount during installation**
- **format & mount all drives with a [logical sector or block size](https://wiki.archlinux.org/title/Advanced_Format) of 4096**

## needed base system modules

- Configure mkinitcpio [linux-zen.preset](https://github.com/bernardassan/archsway/blob/master/etc/mkinitcpio.d/linux-zen.preset) to generate a efi uki image
- Use [/efi](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points) as ESP partition and set systemd-boot [loader.conf](https://github.com/bernardassan/archsway/blob/master/efi/loader/loader.conf) to your efi uki (unified kernel image) image
- Extend mkinitcpio image generation with zstd [compression](https://github.com/bernardassan/archsway/blob/master/etc/mkinitcpio.conf.d/compression.conf) and add kernel [cmdline](https://github.com/bernardassan/archsway/blob/master/etc/kernel/cmdline) parameters
- Enable systemd-boot as boot manager (`bootctl install`)
- Enable iwd, systemd-networkd, systemd-resolved system services
- Enabling `systemd-boot-update` service to update systemd-boot on systemd upgrade
- river/sway as window manager with swayidle and waylock for idle and lock
  management and levee/yambar for bar management
    - base
    - xfsprogs | f2fs-tools | btrfs-progs | dosfstools | exfatprogs
    - intel-ucode microcode
    - iwd for wifi
    - ghostty/kitty/foot terminal
    - Install only needed linux-firmware, check firmwares you might need with `lspci` and [use dynamic debug](https://wiki.archlinux.org/title/Linux_firmware#Detecting_loaded_firmware) to know more details about the exact firmwares loaded at kernel startup
    - linux-zen
    - intel-media-driver for hardware video acceleration
    - polkit for seat and privileged access management
    - man-db and [man-pages](https://wiki.archlinux.org/title/Man_page) and enable man-db.timer service
    - Set up GPG with SSH authentication enabled
    - helix/neovim for config clone [awesome-helix](https://github.com/bernardassan/awesome-helix.git) to $XDG_CONFIG_HOME/helix or [awesome-neovim](https://github.com/bernardassan/awesome-neovim.git) to $XDG_CONFIG_HOME/nvim
    - sudo
    - elvish/fish (set default shell with `chsh -s $(which shellname)`)

### basic configuration

- iwd for wifi and enable its builtin dhcp client
- symlink /run/systemd/resolve/stub-resolv.conf to /etc/resolv.conf for DNS resolution
- setup reflector for choosing the fastest Pacman mirror list
- Configure network using [systemd-networkd](https://github.com/bernardassan/archsway/tree/master/etc/systemd/network) and [systemd-resolved](https://github.com/bernardassan/archsway/tree/master/etc/systemd/resolved.conf.d)
- Setup [vconsole ](https://github.com/bernardassan/archsway/blob/master/etc/vconsole.conf) terminal fonts
- On the freshly installed system, use the following fonts
    + use fonts with great unicode support, like `ttf-dejavu` or `noto-fonts` as the system default font
    + ttf-jetbrains-mono or ttc-iosevka for monospace,
    + ttf-nerd-fonts-symbols-mono for nerd font symbols and noto-font-emoji for emoji
    >_NOTE_: don't forget to `ln -s /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf /etc/fonts/conf.d/`
- configure [Intel_graphics](https://wiki.archlinux.org/title/Intel_graphics) hardware acceleration
- setup [laptop](https://wiki.archlinux.org/title/Laptop), zram, disk, network and [power management](https://wiki.archlinux.org/title/Power_management) options using [udev](https://github.com/bernardassan/archsway/tree/master/etc/udev/rules.d) rules, [sysctl](https://github.com/bernardassan/archsway/tree/master/etc/sysctl.d) and [modprobe](https://github.com/bernardassan/archsway/tree/master/etc/modprobe.d) config
- Configure [hibernation](https://github.com/bernardassan/archsway/tree/master/etc/modprobe.d) by adding resume kernel parameter, resume hook to mkinitcpio, and rebuilding kernel
- Enable [Active State Power Management](https://wiki.archlinux.org/title/Power_management#Active_State_Power_Management)
  if [supported ](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/power_management_guide/aspm) and add or remove `powersave > /sys/module/pcie_aspm/parameters/policy` from udev powersave rules based on the results
- Configure sudo for current user using `sudo -E visudo -sf /etc/sudoers.d/${username}`. Example [sudoers file](https://github.com/bernardassan/archsway/tree/master/etc/sudoers.d)
- Configure [logind](https://github.com/bernardassan/archsway/tree/master/etc/systemd/logind.conf.d), [journald](https://github.com/bernardassan/archsway/tree/master/etc/systemd/logind.conf.d) and [sleep](https://github.com/bernardassan/archsway/tree/master/etc/systemd/sleep.conf.d)
- For extra [Performance Improvements](https://wiki.archlinux.org/title/Improving_performance)
- For [pacman](https://wiki.archlinux.org/title/Pacman), enable the following options under the option section in /etc/pacman.conf
```bash
[options]
Color
CheckSpace
VerbosePkgLists
ParallelDownloads = 5
```
- Set up [makepkg.conf](https://github.com/bernardassan/archsway/blob/master/etc/makepkg.conf.d/makepkg.conf) and Increase /tmp tmpfs size to 90% of RAM by copying and changing the Options field of `Mount` from the default size of 50% to 90% in the drop-in config file. This helps to prevent OOM when compiling clang on /tmp `sudo -E systemctl edit tmp.mount --drop-in=hugetmp.mount`
```bash
[Mount]
Options=
Options=mode=1777,strictatime,nosuid,nodev,size=90%%,nr_inodes=1m
```
>_NOTE_: This is to be used in conjunction with `zram`

## INSTALLS
- base-devel for Basic c/c++ build tools to build Arch Linux packages
- mold as linker for C, Rust and C++
- lldb/gdb for debugging Zig, C, and C++
- clang/gcc for C++ development with clangd
- zig with zls for zig development
- rustup with default profile and rust-analyzer component for Rust development
- luajit for lua development
- iptables-nft and nftable(automatically installed as a dependency of iptables-nft) for firewall configuration (enable the nftables service)
- nmap and tcpdump for network analysis and auditing
- yay for AUR package management
- android-file-transfer with libmtp for connecting Android phones mtp management
- aria2 as download manager
- bat is a Cat clone with syntax highlighting and git integration
- bluez and bluez-utils for Bluetooth
- brightnessctl for controlling backlight
- carapace-bin for completions in elvish
- fzf for fuzzy search
- vivid for LS_COLORS
- starship for prompt
- [Helix](https://github.com/bernardassan/awesome-helix) and [Neovim](https://github.com/bernardassan/awesome-neovim) awesomely set up with the relevant LSPs and static analyzers for `Zig`, `C`, `Rust`, `C++`, `Luajit`, `Python`, `Shell`, and `Web-Development`.
- dictd server with dict client and some dictionary sources for yay like `dict-wikt-en-all`, `dict-freedict-eng-spa`, `dict-freedict-spa-eng`, `dict-foldoc`, `dict-gcide`, `dict-wn`.
    - NOTE: to disable online mode, comment out `server dict.org` in  /etc/dict/dict.conf
    - Make sure locale is properly configured in `DICTD_ARGS` of /etc/conf.d/dictd else, the service unit will fail
    - Since dict uses en_US.UTF-8 by default, make sure to comment it out in /etc/locale.gen and compile it along side your locale of choice `es_MX.UTF-8`
- ffmpegthumbnailer & gnome-epub-thumbnailer for thumbnails
- firefox with speech-dispatcher (for Text-to-Speech) as pdf reader or zathura and firefox-ublock-origin as adblocker and foliate/fbreader as epub reader
- wlsunset for controlling screen blue light
- git for version control
- grim and slurp for screenshot
- mako as a lightweight notification daemon for Wayland
- docker for containerization of apps
- scrcpy for mirroring android device (with adb for copying to Android)
- libreoffice-fresh for working with openoffice documents and hunspell-en_us for spellcheck, [for help setting up spellcheck](https://ask.libreoffice.org/t/how-do-you-get-the-spell-checker-to-work/28998)
- mpd for music daemon, ncmpcpp for ui interface, and mpc for controlling playing
- mpv as multimedia player
- sound-theme-freedesktop for standard sounds and tones used in Linux
- pipewire and pipewire-audio for audio/video routing and processing, pipewire-pulse as pulseaudio replacement and WirePlumber as pipewire session manager
- lf as file manager
- fastfetch for displaying system information
- openssh and rsync for syncing files with a remote over ssh
- remmina as remote desktop client with a plugin like freerdp|libvncserver
- usb_modeswitch for enabling modem mode for zero-cd based modems
- wl-clipboard for wayland clipboard
- batsignal for battery status notifications
- kanshi for wayland output management
- fuzzel as the application launcher
- cliphist as clipboard history manager
- qt5-wayland for runing qt5 apps under wayland
- xdg-desktop-portal-wrl for WebRTC screen sharing
- xdg-utils to assist applications with desktop integration tasks
- yt-dlp YouTube downloader
- zoxide for efficient directory movement

## Configuring Firefox
- Enable Firefox [Hardware video acceleration](https://wiki.archlinux.org/title/Firefox#Hardware_video_acceleration) by setting media.ffmpeg.vaapi.enabled to true and Hardware WebRender by setting `gfx.webrender.all` to `true` and `media.hardware-video-decoding.force-enabled` to `true`
- Enable insert [new tabs after current](https://wiki.archlinux.org/title/Firefox#New_tabs_position) by setting `browser.tabs.insertAfterCurrent` to `true`
- Enable [Firefox Profile on Ram](https://wiki.archlinux.org/title/Firefox/Profile_on_RAM) when using zram/nvme/ssd
- Move Firefox [disk cache to ram](https://wiki.archlinux.org/title/Firefox/Tweaks#Move_disk_cache_to_RAM) by setting `browser.cache.disk.parent_directory` to `/run/user/1000/firefox`
- Increase [session save interval](https://wiki.archlinux.org/title/Firefox/Tweaks#Longer_interval_between_session_information_record) from the default of 15 seconds (15000 milliseconds) to 30 minutes (1,800,000 milliseconds) by setting `browser.sessionstore.interval` to `1800000`
- Enable auto [unloading of inactive tabs](https://wiki.archlinux.org/title/Firefox/Tweaks#Automatically_unload_inactive_tabs)


## OPTIONAL
- configure /etc/motd with the Message Of The Day Eg. `WELCOME MASTER MALPHA! WE ARE READY TO SERVE YOU!!!`
- Checkout [Archlinux General Recommendation](https://wiki.archlinux.org/title/Firefox/Profile_on_RAM#Place_profile_in_RAM_manually)
- enable DNSOverTLS for resolved
- Enable synchronizing the system clock across the network by enabling [systemd-timesyncd.service](https://wiki.archlinux.org/title/Systemd-timesyncd)
- Disable journaling to persistent storage by setting Storage in journal.conf to volatile and masking `systemd-journal-flush.service`
- link kitty to xterm
- Enable DNS over HTTPS in Firefox
- modify relector configuration in /etc/xdg/reflector/reflector.conf to sort based on download rate with --sort rate

## TERMUX
To use [pacman](https://wiki.archlinux.org/title/Pacman) as the package manager for [Termux](https://termux.dev/en/) follow these [instructions](https://wiki.termux.com/wiki/Switching_package_manager)
If you want to compile [AUR](https://wiki.archlinux.org/title/Arch_User_Repository) packages follow these [instructions](https://wiki.termux.com/wiki/AUR)
- openssl-tool
- openssh
- zig
- rust
- golang
- python
- bsdtar
- fzf
- bat
- starship
- fastfetch
- git
- helix
- man

## WSL

Install [ArchLinux WSL](https://archlinux.org/download/) on Windows 11 using `wsl --install archlinux`. After installing, follow these [instructions](https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL) to set up ArchLinux on WSL 2.
- Download and install a Nerd Font of your choosing, like [IosevkaTerm](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/IosevkaTerm/IosevkaTermNerdFontMono-Medium.ttf) and use it as your default font for Windows Terminal
- Install starship `winget install -e --id Starship.Starship` and add `Invoke-Expression (&starship init powershell)` to your $PROFILE as in [Microsoft.PowerShell_profile](https://github.com/bernardassan/archsway/tree/master/wsl/WindowsPowerShell/Microsoft.PowerShell_profile.ps1)
- Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser` in PowerShell to enable running of scripts
- Add the wheel group `groupadd -f wheel` as it isn't available by default in Archlinux WSL
- create a non-root user and add him to the wheel group `useradd -mG wheel -s /bin/elvish username`
- Set a password for your new user with `passwd username`
- To set a different host name, disable hostname generation, and set a static hostname in [wsl.conf](https://github.com/bernardassan/archsway/blob/899d464762fead2b17995e2fa8ba06942cc369cf/wsl/etc/wsl.conf#L6)
- Configure [sudoers](https://github.com/bernardassan/archsway/tree/master/etc/sudoers.d) file at /etc/sudoers.d/`username`

## Using a custom build WSL kernel
- To compile the WSL kernel, you need `base-devel`, `bc`, `cpio`, `pahole`, `python`, and `rsync`.
- Then set `swap=32GB` in .wslconfig to ensure you can compile the kernel without running out of memory
- Run `zcat /proc/config.gz | /bin/sed '/is not set/d' > .config` to get a copy of all the set config used by the current WSL kernel
- Run `env KCONFIG_CONFIG=Microsoft/config-wsl ./scripts/kconfig/merge_config.sh .config` to merge `.config` with `Microsoft/config-wsl`, overriding options in `Microsoft/config-wsl`.
- Then `env KCONFIG_CONFIG=Microsoft/config-wsl make olddefconfig` or `env KCONFIG_CONFIG=Microsoft/config-wsl make oldconfig` to use default values for new kernel configs not in `$E:KCONFIG_CONFIG`.
- ensure CONFIG_TUN=y and CONFIG_TAP=y are set in Microsoft/config-wsl to enable [userspace networking](https://www.kernel.org/doc/html/latest/networking/tuntap.html) used by podman and VPNs
- Use mold `set-env LD mold` to link faster, this reduced the whole compile/link phase from about 1hr30min to 30min for me
- follow instructions at [updating wsl kernel](https://learn.microsoft.com/en-us/community/content/wsl-user-msft-kernel-v6)
- At the end, you should have a [.wslconfig](https://github.com/bernardassan/archsway/blob/master/wsl/wslconfig) like mine
