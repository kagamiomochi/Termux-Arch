#!/bin/bash
set -Eeuo pipefail

if ! command -v pkg >/dev/null 2>&1; then
  echo "This script must be run in Termux." >&2
  exit 1
fi

read -r -p "UserName: " user_name
if [[ ! "$user_name" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Invalid username. Use lowercase letters, numbers, underscores, or dashes." >&2
  exit 1
fi

IFS= read -r -s -p "Password: " password
echo

touch ~/.hushlogin

pkg update -y
apt -o Dpkg::Options::="--force-confold" upgrade -y || true

pkg install -y x11-repo termux-x11-nightly proot-distro || exit 1

if ! proot-distro list 2>/dev/null | grep -q '^archlinux$'; then
  proot-distro install heywoodlh/archlinux --override-alias archlinux || exit 1
fi

proot-distro login archlinux -- bash -eu -c '
  user_name="${1}"
  password="${2}"

  if ! id -u "${user_name}" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "${user_name}"
  fi

  pacman -Syu --noconfirm --needed sudo nano

  printf "%s:%s\n" "${user_name}" "${password}" | chpasswd

  sudoers_file="/etc/sudoers.d/${user_name}"
  printf "%s ALL=(ALL:ALL) ALL\n" "${user_name}" > "${sudoers_file}"
  chmod 440 "${sudoers_file}"
  visudo -cf "${sudoers_file}" >/dev/null

  bashrc_file="/home/${user_name}/.bashrc"
  cat > "${bashrc_file}" <<EOF
export XDG_RUNTIME_DIR="/run/${user_name}/$(id -u)"
mkdir -p "\$XDG_RUNTIME_DIR"
chmod 700 "\$XDG_RUNTIME_DIR"
export DISPLAY=:0
EOF

  chown "${user_name}:${user_name}" "${bashrc_file}"
' _ "${user_name}" "${password}"

cat > ~/.bashrc <<EOF
echo "Press Ctrl+C to cancel Arch Linux login..."
sleep 2
clear
exec proot-distro login archlinux --shared-tmp --user "${user_name}"
EOF

echo "Setup complete. Run: proot-distro login archlinux --shared-tmp --user ${user_name}"
exit 0
