#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  SUDO=()
  TARGET_USER=${SUDO_USER:-root}
else
  SUDO=(sudo)
  TARGET_USER=$(id -un)
fi

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify this Linux distribution." >&2
  exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != ubuntu ]]; then
  echo "This installer supports Ubuntu only (detected: ${PRETTY_NAME:-unknown})." >&2
  exit 1
fi

arch=$(dpkg --print-architecture)
codename=${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}
if [[ -z $codename ]]; then
  echo "Could not determine Ubuntu codename." >&2
  exit 1
fi

"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y ca-certificates curl
"${SUDO[@]}" install -m 0755 -d /etc/apt/keyrings
"${SUDO[@]}" curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
"${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.asc
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' "$arch" "$codename" \
  | "${SUDO[@]}" tee /etc/apt/sources.list.d/docker.list >/dev/null

"${SUDO[@]}" apt-get update
"${SUDO[@]}" apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
"${SUDO[@]}" systemctl enable --now docker
if [[ $TARGET_USER != root ]]; then
  "${SUDO[@]}" usermod -aG docker "$TARGET_USER"
fi

printf '\nInstalled versions:\n'
docker --version
"${SUDO[@]}" docker compose version
if [[ $TARGET_USER != root ]]; then
  printf '\nAdded %s to the docker group. Log out and back in before running Docker without sudo. The docker group grants root-level access.\n' "$TARGET_USER"
else
  printf '\nInstalled. The script ran as root, so no non-root user was added to the docker group.\n'
fi
