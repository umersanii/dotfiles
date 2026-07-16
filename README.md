# Dotfiles — Legion 5 Pro

Personal dotfiles for my Arch Linux setup on the Lenovo Legion 5 Pro, managed with [chezmoi](https://chezmoi.io).

## System

- **Machine**: Lenovo Legion 5 Pro
- **OS**: Arch Linux
- **WM**: Hyprland (Wayland)
- **Shell**: Fish

## What's Included

### Window Manager
- **Hyprland** (`hypr/`) — Wayland compositor
  - `hyprland/` — main config and scripts
  - `hyprlock/` — lock screen
  - `custom/` — per-machine overrides and scripts

### Shell & Terminal
- **Fish** (`fish/`) — shell config and functions
- **Kitty** (`kitty/`) — GPU-accelerated terminal
- **Foot** (`foot/`) — lightweight Wayland terminal
- **Starship** (`starship.toml`) — cross-shell prompt

### Bar & UI
- **Quickshell** (`quickshell/`) — QML-based desktop shell
  - `ii/` — main panel family (bar, sidebar, dock, lock, notifications, overlays)
  - `waffle/` — alternative panel family (action center, start menu, task view)

### Theme & Appearance
- **Matugen** (`matugen/`) — Material You color generation
  - Templates for GTK, Hyprland, Fuzzel, AGS, KDE
- **GTK 3/4** (`gtk-3.0/`, `gtk-4.0/`) — GTK theme config
- **Fuzzel** (`fuzzel/`) — app launcher

### Media & Utilities
- **MPV** (`mpv/`) — media player config
- **Cava** (`cava/`) — audio visualizer
- **Btop** (`btop/`) — resource monitor
- **Fastfetch** (`fastfetch/`) — system info fetch
- **Wlogout** (`wlogout/`) — logout menu
- **Git** (`git/`) — global git config

## Installation

### 1. Prerequisites
- Arch Linux (or an Arch-based distro) with `sudo` access
- An SSH key added to your GitHub account (the repo is cloned over SSH)
- An AUR helper — [`yay`](https://aur.archlinux.org/packages/yay) is used by the package install script below:
  ```bash
  git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si
  ```

### 2. Install chezmoi and apply the dotfiles
```bash
sudo pacman -S chezmoi
chezmoi init --apply git@github.com:umersanii/dotfiles.git
```

Switch to the Legion 5 Pro branch:
```bash
chezmoi git -- checkout Legion-5-Pro
chezmoi apply
```

### 3. Install packages
`chezmoi apply` automatically runs `run_onchange_install-packages.sh`, which installs the full stack (Hyprland, Quickshell/`illogical-impulse`, fish, kitty, starship, matugen, wlogout, fuzzel, btop, fastfetch, pipewire, etc.) via `pacman`/`yay`. Re-run it manually any time with:
```bash
chezmoi apply
```
(chezmoi re-runs the script automatically whenever its contents change; use `chezmoi state delete-bucket --bucket=scriptState` if you need to force a re-run.)

### 4. Machine-specific caveats
- `hypr/monitors.conf` is tracked as-is (not templated per-machine) — edit it by hand if the new device has a different display layout.
- After changing `monitors.conf` from mirrored to extended, Quickshell won't spawn on the new monitor until you physically unplug/replug the cable (see Known Issues in `CLAUDE.md`).
- Re-enable the auto-sync timer (see below) since `systemctl --user enable` state isn't part of the dotfiles themselves:
  ```bash
  systemctl --user enable --now dotfiles-sync.timer
  ```

## Auto-sync

A systemd user timer syncs changes to GitHub every hour automatically.

To manually sync after editing a config:
```bash
chezmoi re-add ~/.config/hypr/hyprland/hyprland.conf
~/.local/bin/dotfiles-sync.sh
```
