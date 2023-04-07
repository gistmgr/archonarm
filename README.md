## Install archlinux on Samsung chromebook plus(kevin)  

<https://archlinuxarm.org/platforms/armv8/rockchip/samsung-chromebook-plus>  
  
---

```shell
sudo -u root bash
```

---

### Internal setup
```shell
DISK="/dev/mmcblk1"
BOOT="/dev/mmcblk1p1"
ROOT="/dev/mmcblk1p2"
```
### USB Setup
```shell
DISK="/dev/sda"
BOOT="/dev/sda1"
ROOT="/dev/sda2"
```

---

```shell
umount ${DISK}*
```

### Type g then w

```shell
fdisk ${DISK}
cgpt create ${DISK}
cgpt add -i 1 -t kernel -b 8192 -s 65536 -l Kernel -S 1 -T 5 -P 10 ${DISK}
PART_SIZE="$(cgpt show ${DISK} | grep 'Sec GPT table' | awk '{print $1}' | sed 's| *||g')"
echo "Setting root partition to $((PART_SIZE/1000/1000/2)) Gigabytes"
cgpt add -i 2 -t data -b 73728 -s $(($PART_SIZE - 73728)) -l Root ${DISK}
partx -a ${DISK}
mkfs.ext4 $ROOT
```

---

```shell
curl -q -LSf "http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-chromebook-latest.tar.gz" -o "/tmp/ArchLinuxARM-aarch64-chromebook-latest.tar.gz"
mkdir /tmp/root
mount $ROOT /tmp/root || exit 1
tar -xf "/tmp/ArchLinuxARM-aarch64-chromebook-latest.tar.gz" -C /tmp/root
dd if=/tmp/root/boot/vmlinux.kpart of=$BOOT
```

### Mount

```shell
mkdir /tmp/root
mount $ROOT /tmp/root
mount -t proc /proc /tmp/root/proc/
mount --rbind /sys /tmp/root/sys/
mount --rbind /dev /tmp/root/dev/
if [ -f "/boot/cmdline.txt" ]; then 
cp -Rf "/boot/cmdline.txt" "/tmp/root/boot/cmdline.txt"
else
printf '%s\n' "net.ifnames=0 biosdevname=0" >"/tmp/root/boot/cmdline.txt"
fi
chroot /tmp/root
```

#### Setup

```shell
echo 'LANG=en_US.UTF-8' | tee '/etc/locale.conf' &>/dev/null
grep -qs '^en_US.UTF' "/etc/locale.gen" || echo 'en_US.UTF-8 UTF-8' | tee "/etc/locale.gen" &>/dev/null
locale-gen
passwd root
userdel -r alarm
rm -Rf "/etc/resolv.conf"
printf '%s\n%s\n' "nameserver 1.1.1.1" "nameserver 8.8.8.8" >"/etc/resolv.conf"
pacman-key --init
pacman-key --populate archlinuxarm
pacman -R --noconfirm netctl
pacman -R --noconfirm pulseaudio
pacman -Syyu --noconfirm
pacman -Syy --noconfirm pipewire pipewire-alsa pipewire-pulse
pacman -Syy --noconfirm wget curl cgpt networkmanager bash bash-completion git sudo gpm nano openssh
pacman -Syy --noconfirm uboot-rock64 rockchip-tools firmware-gru devtools-alarm linux-firmware-marvell
systemctl disable systemd-resolved
systemctl enable NetworkManager sshd gpm
mkdir -p "/root/.local/bin"
curl -q -LSsf "https://github.com/gistmgr/archonarm/raw/main/archlinuxarm.sh" -o "/root/.local/bin/archlinux_setup.sh" 
chmod -Rf 755 "/root/.local/bin/archlinux_setup.sh"
rm -Rf /etc/netctl*
systemctl disable systemd-resolved
systemctl enable NetworkManager sshd gpm
exit 0
```

#### Finalize

```shell
umount "/tmp/root/proc"
umount "/tmp/root/sys"
umount "/tmp/root/dev"
umount "/tmp/root"
sync
exit
```
