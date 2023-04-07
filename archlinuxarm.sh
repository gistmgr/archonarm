#!/usr/bin/env bash
# - - - - - - - - -
# Run this script as root
# - - - - - - - - -
if [ "$USER" != "root" ] || [ $(id -u) != 0 ]; then
  echo "Please run this script as root"
  exit 1
fi
# - - - - - - - - -
ADD_USER="${1:-jason}"
HOSTNAME="${HOSTNAME:-jasons-chromebook}"
TIME_ZONE="${TIME_ZONE:-America/New_York}"
ADD_USER_GROUPS="sys network power wheel optical rfkill video storage audio users scanner lp"
# - - - - - - - - -
pacman-key --init
pacman-key --populate archlinuxarm
# - - - - - - - - -
pacman -Syyu --noconfirm --overwrite '*'
# - - - - - - - - -
[ -f "$(builtin command -v "git")" ] || pacman -Syy --noconfirm git
[ -f "$(builtin command -v "bash")" ] || pacman -Syy --noconfirm bash
[ -f "$(builtin command -v "sudo")" ] || pacman -Syy --noconfirm sudo
# - - - - - - - - -
if [ ! -f "/etc/init_done.conf" ]; then
  pacman -Syyu --noconfirm vim nano neovim usbutils xfce4 xfce4-goodies xorg-server lightdm lightdm-gtk-greeter xf86-input-libinput \
    networkmanager network-manager-applet alsa-utils xorg-xmodmap xbindkeys linux-firmware linux-firmware-marvell cgpt wget linux-aarch64-headers \
    pipewire pipewire-alsa pipewire-pulse pavucontrol bash-completion bluez blueman firefox base-devel bluez-utils bluez-tools curl --overwrite '*' &&
    echo "$(date)" | tee "/etc/init_done.conf" &>/dev/null
fi
# - - - - - - - - -
[ -d "/etc/sudoers.d" ] || mkdir -p "/etc/sudoers.d"
# - - - - - - - - -
if ! grep -sq "$ADD_USER" /etc/passwd; then
  useradd -m -G wheel -s /bin/bash $ADD_USER
  passwd $ADD_USER
fi
for add_group in $ADD_USER_GROUPS; do
  grep -qs "$add_group:x.*$ADD_USER" /etc/group || { grep -qs "^$add_group" /etc/group && usermod -a -G $add_group $ADD_USER; }
done
# - - - - - - - - -
if [ ! -f "/etc/sudoers.d/$ADD_USER" ]; then
  cat <<EOF | tee "/etc/sudoers.d/$ADD_USER" &>/dev/null
$ADD_USER ALL=(ALL) NOPASSWD:ALL
EOF
fi
# - - - - - - - - -
if ! builtin command -v yay &>/dev/null; then
  sudo -u $ADD_USER bash -c "git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin && cd /tmp/yay-bin && makepkg -si"
  [ -d "/tmp/yay-bin" ] && rm -Rf "/tmp/yay-bin"
fi
# - - - - - - - - -
[ -f "$(builtin command -v "code")" ] || [ ! -f "$(builtin command -v "yay")" ] || sudo -u $ADD_USER yay -Syyu --noconfirm visual-studio-code-bin
# - - - - - - - - -
mkdir -p "/etc/X11/xorg.conf.d"
cat <<EOF | tee /etc/X11/xorg.conf.d/70-synaptics.conf &>/dev/null
Section "InputClass"
        Identifier "touchpad"
        Driver "synaptics"
        MatchIsTouchpad "on"
        Option "FingerHigh" "5"
        Option "FingerLow" "5"
        Option "TapButton1" "1"
        Option "TapButton2" "3"
        Option "TapButton3" "2"
        Option "HorizTwoFingerScroll" "on"
        Option "VertTwoFingerScroll" "on"
EndSection
EOF
# - - - - - - - - -
mkdir -p /etc/skel
# - - - - - - - - -
if [ -f "$(builtin command -v xvkbd)" ]; then
  cat <<EOF | tee "/etc/skel/.xbindkeysrc" &>/dev/null
"xvkbd -xsendevent -text "[Prior]""
    m:0x4 + c:111
    Control + Up
"xvkbd -xsendevent -text "[Next]""
    m:0x4 + c:116
    Control + Down
"xvkbd -xsendevent -text "[Delete]""
    m:0x4 + c:22
    Control + BackSpace
"xvkbd -xsendevent -text "[End]""
    m:0x4 + c:114
    Control + Right
"xvkbd -xsendevent -text "[Home]""
    m:0x4 + c:113
    Control + Left
EOF
fi
# - - - - - - - - -
mkdir -p "/etc/tmpfiles.d"
cat <<EOF | tee "/etc/tmpfiles.d/brightness.conf" &>/dev/null
f /sys/class/backlight/backlight/brightness 0666 - - - 800
EOF
# - - - - - - - - -
curl -q -LSsf "https://github.com/gistmgr/archonarm/raw/main/brightness" | tee /usr/local/bin/brightness &>/dev/null && chmod 755 /usr/local/bin/brightness
# - - - - - - - - -
#cat <<EOF | tee "$HOME/.config/pulse/default.pa" &>/dev/null
#.include /etc/pulse/default.pa
#load-module module-null-sink sink_name=corrected_speakers sink_properties=device.description=corrected_speakers
#load-module module-loopback source=corrected_speakers.monitor sink=alsa_output.platform-sound.stereo-fallback remix=false
#set-sink-volume alsa_output.platform-sound.stereo-fallback 6553
#set-default-sink corrected_speakers
#
#EOF
# - - - - - - - - -
echo 'LANG=en_US.UTF-8' | tee '/etc/locale.conf' &>/dev/null
grep -qs '^en_US.UTF' "/etc/locale.gen" || echo 'en_US.UTF-8 UTF-8' | tee "/etc/locale.gen" &>/dev/null
locale-gen
# - - - - - - - - -
hwclock --systohc
hostnamectl set-hostname "$HOSTNAME"
timedatectl set-timezone "$TIME_ZONE"
ln -sf "/usr/share/zoneinfo/$TIME_ZONE" "/etc/localtime"
# - - - - - - - - -
systemctl disable systemd-resolved
systemctl enable bluetooth lightdm NetworkManager gpm
printf '%s\n%s\n' "nameserver 1.1.1.1" "nameserver 8.8.8.8" >"/etc/resolv.conf"
# - - - - - - - - -
cp -Rfa "/etc/skel/." "$HOME/"
# - - - - - - - - -
printf '\n\n%s\n\n' 'Done: it is advised that you restart you system'
