#!/bin/bash

read -p "UserName: " user_name
read -s -p "Password: " password

touch ~/.hushlogin

pkg update -y
apt -o Dpkg::Options::="--force-confold" upgrade -y

pkg install -y x11-repo
pkg install -y termux-x11-nightly
pkg install -y proot-distro
proot-distro install heywoodlh/archlinux --override-alias archlinux

proot-distro login archlinux -- bash -c '
pacman -Syu --noconfirm sudo nano
useradd -m ${user_name}
echo "${user_name}:${password}" | chpasswd
echo "${user_name} ALL=(ALL:ALL) ALL" > /etc/sudoers.d/${user_name}
chmod 440 /etc/sudoers.d/${user_name}
visudo -c

cat << "EOF" > /home/${user_name}/.bashrc
export XDG_RUNTIME_DIR="/run/${user_name}/$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export DISPLAY=:0
EOF
chown ${user_name}: /home/${user_name}/.bashrc
'

cat << "EOF" > .bashrc
echo "Press Ctrl+C to cancel Arch Linux login..."
sleep 2
clear
exec proot-distro login archlinux --shared-tmp --user ${user_name}
EOF

exit
