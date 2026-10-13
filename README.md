# Ubuntu + Niri + DankMaterialShell backup

Captured: 2026-10-02
Source system: Ubuntu 26.04.1 LTS, x86_64, Niri on Wayland.

This bundle captures the current configured state. A separate snapshot immediately after DankMaterialShell's default setup was not saved, so this bundle cannot reproduce that historical baseline by itself. On a fresh system, complete DMS's normal first-run/default setup, then restore these files.

## Included

- `home/.config/niri/`: Niri config and DMS-managed KDL fragments.
- `home/.config/DankMaterialShell/settings.json`: DMS user settings.
- `home/.config/nvim/`, `home/.config/kitty/`, `home/.config/fish/`: Neovim, Kitty, Fish configs. Fish plugin list and commented Hyprland autostart file included; Fish universal variables and machine-specific VPN alias excluded.
- `home/workspaces/scripts/`: four original scripts plus the optional software installer; executable modes preserved.
- `home/Pictures/thumb-1920-1301855.jpg`: wallpaper reported by `dms ipc call wallpaper get`.
- `home/.local/share/fonts/JetBrainsMonoNerdFont/`: installed user font files.
- `etc/apt/sources.list.d/avengemedia-ubuntu-danklinux-resolute.sources`: package source for Niri/DMS packages.

No DMS plugin files, GTK/Qt/Matugen defaults, or DankSearch/Fcitx5 defaults are included.

## Restore

Use an Ubuntu release supported by the PPA. The saved source targets `resolute` (Ubuntu 26.04); for another release, confirm PPA support and use its matching suite. Package versions are not pinned: APT installs the latest available compatible versions from the configured source.

From this backup directory:

```sh
sudo install -Dm0644 etc/apt/sources.list.d/avengemedia-ubuntu-danklinux-resolute.sources /etc/apt/sources.list.d/avengemedia-ubuntu-danklinux-resolute.sources
sudo apt update
sudo apt install niri dms dms-greeter quickshell neovim kitty fish
```

Complete DMS's normal first-run/default setup. Then restore the user files:

```sh
cp -a home/.config/niri home/.config/nvim home/.config/kitty home/.config/fish "$HOME/.config/"
cp -a home/.config/DankMaterialShell/settings.json "$HOME/.config/DankMaterialShell/settings.json"
mkdir -p "$HOME/workspaces" "$HOME/Pictures" "$HOME/.local/share/fonts"
cp -a home/workspaces/scripts "$HOME/workspaces/"
cp -a home/Pictures/thumb-1920-1301855.jpg "$HOME/Pictures/"
cp -a home/.local/share/fonts/JetBrainsMonoNerdFont "$HOME/.local/share/fonts/"
systemctl --user enable --now dms.service
fc-cache -f
```

The restored Neovim config requires its bundled dependency setup. Run it after copying the config and scripts:

```sh
bash "$HOME/workspaces/scripts/install-nvim-deps.sh"
```

To use Fish as the login shell, optionally run `chsh -s "$(command -v fish)"` and start a new login session.

Chạy installer tùy chọn để mở menu TUI. Chọn nhóm bảo mật, tiện ích, cả hai hoặc thoát:

```sh
bash "$HOME/workspaces/scripts/install-optional-apps.sh"
```

Nhóm bảo mật cài KeePassXC và VeraCrypt. Nhóm tiện ích cài Tailscale, Spotify và áp dụng SpotX-Bash. Installer tải và chạy script chính thức của Tailscale và SpotX-Bash; xem mã nguồn trước nếu cần xác minh.

Select the Niri session at login. Verify this bundle's integrity with `sha256sum -c SHA256SUMS` from this directory.
