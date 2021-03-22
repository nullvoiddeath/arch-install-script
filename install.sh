read -p 'Enter Hostname: ' hostvar
read -p 'Enter your Username: ' uservar
read -p 'Enter user password: ' userpass
read -p 'Enter root password: ' root_password
read -p 'Enter root partition size: ' rootsize
read -p 'Enter swap size (ideally half of RAM size): ' swapsize
timedatectl set-ntp true
dhcpcd
echo "nameserver 8.8.8.8 > /etc/resolv.conf"
echo "nameserver 8.8.4.4 >> /etc/resolv.conf"
#iwctl --passphrase passphrase station device connect SSID
lsblk
read -p 'Enter device to install Arch on: ' sdavar
#disk partitioning
sgdisk -oG /dev/sda
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:"EFI" /dev/$sdavar
sgdisk -n 0:0:+{rootsize}GiB -t 0:8300 -c 0:"root" /dev/$sdavar
sgdisk -n 0:0:+{swapsize}GiB -t 0:8200 -c 0:"swap" /dev/$sdavar
sgdisk -n 0:0:0 -t 0:8300 -c 0:"home" /dev/$sdavar
mkfs.fat -F32 -n BOOT /dev/${sdavar}1
mkfs.ext4 /dev/${sdavar}2
mkfs.ext4 /dev/${sdavar}4
mkswap -L swap /dev/${sdavar}3
swapon /dev/${sdavar}3
mount /dev/${sdavar}2 /mnt
mkdir -p /mnt/home
mount /dev/${sdavar}4 /mnt/home
mkdir -p /mnt/boot/efi
mount /dev/${sdavar}1 /mnt/boot/efi

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
pacman -S grub efibootmgr --noconfirm
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
echo "root:${root_password}" | chpasswd

pacman -S xorg-server xf86-video-vesa sudo --noconfirm
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
useradd -m -g users -G wheel $uservar
echo "${uservar}:${userpass}" | chpasswd
exit
EOF

umount -R /mnt
reboot

