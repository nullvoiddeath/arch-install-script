read -p 'Enter Hostname: ' hostvar
read -p 'Enter your Username: ' uservar
timedatectl set-ntp true
dhcpcd
echo "nameserver 8.8.8.8 > /etc/resolv.conf"
echo "nameserver 8.8.4.4 >> /etc/resolv.conf"
#iwctl --passphrase passphrase station device connect SSID
lsblk

#disk partitioning
sgdisk -oG /dev/sda
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:"EFI" /dev/sda
sgdisk -n 0:0:+4GiB -t 0:8300 -c 0:"root" /dev/sda
sgdisk -n 0:0:+1GiB -t 0:8200 -c 0:"swap" /dev/sda
sgdisk -n 0:0:0 -t 0:8300 -c 0:"home" /dev/sda
mkfs.fat -F32 -n BOOT /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda4
mkswap -L swap /dev/sda3
swapon /dev/sda3
mount /dev/sda2 /mnt
mkdir -p /mnt/home
mount /dev/sda4 /mnt/home
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi

#installing
pacstrap /mnt base base-devel linux linux-firmware
genfstab -p /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
pacman-key --init
pacman-key --populate archlinux

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo en_US.UTF-8 > /etc/locale.conf
locale-gen
export LANG=en_US.UTF-8
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc --utc
echo $hostvar > /etc/hostname
mkinitcpio -p linux
pacman -S alsa alsa-utils wireless_tools wpa_supplicant dialog networkmanager dhcpcd --noconfirm

#boot manager
pacman -S grub efibootmgr
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
passwd

pacman -S xorg-server xf86-video-vesa sudo --noconfirm
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
useradd -m -g users -G wheel $uservar
passwd $uservar
exit
EOF

umount -R /mnt
reboot
