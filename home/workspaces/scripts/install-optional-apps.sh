#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
    echo 'This installer is interactive; run it without arguments.' >&2
    exit 2
fi

command -v sudo >/dev/null || { echo 'sudo is required.' >&2; exit 1; }
command -v apt-get >/dev/null || { echo 'This installer requires Ubuntu/Debian with apt-get.' >&2; exit 1; }
command -v curl >/dev/null || { echo 'Install curl first: sudo apt install curl.' >&2; exit 1; }

PS3='Choose an option: '
select choice in 'Security: KeePassXC + VeraCrypt' 'Utilities: Tailscale + Spotify (SpotX-Bash)' 'Install both groups' 'Exit'; do
    case "$REPLY" in
        1) selection=security; break ;;
        2) selection=utilities; break ;;
        3) selection=all; break ;;
        4) exit 0 ;;
        *) echo 'Invalid choice.' ;;
    esac
done
[[ -n "${selection:-}" ]] || exit 0

if [[ "$selection" == security || "$selection" == all ]]; then
    sudo apt-get update
    sudo apt-get install -y keepassxc veracrypt
fi

if [[ "$selection" == utilities || "$selection" == all ]]; then
    # Official Tailscale installer configures its APT repository and package.
    curl -fsSL https://tailscale.com/install.sh | sh
    # SpotX-Bash upstream installer installs Spotify and applies SpotX patches.
    curl -fsSL https://raw.githubusercontent.com/SpotX-Official/SpotX-Bash/main/spotx.sh | bash -s -- --installdeb
fi

