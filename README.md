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

Requires chezmoi:
```bash
sudo pacman -S chezmoi
```

Then apply:
```bash
chezmoi init --apply git@github.com:umersanii/dotfiles.git
```

Switch to the Legion 5 Pro branch:
```bash
chezmoi git -- checkout Legion-5-Pro
chezmoi apply
```

## Auto-sync

A systemd user timer syncs changes to GitHub every hour automatically.

To manually sync after editing a config:
```bash
chezmoi re-add ~/.config/hypr/hyprland/hyprland.conf
~/.local/bin/dotfiles-sync.sh
```
