# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles setup for an Arch Linux / Lenovo Legion 5 Pro machine, managed with [chezmoi](https://chezmoi.io). The source of truth lives at `~/.local/share/chezmoi/` (branch: `Legion-5-Pro`), not in `~/.config` directly.

## Key Commands

```bash
# Apply a specific config change from source to home
chezmoi apply

# Re-add a modified config back into the chezmoi source
chezmoi re-add ~/.config/<path/to/file>

# Sync changes to GitHub (pulls, commits, pushes)
~/.local/bin/dotfiles-sync.sh

# Check status of managed files
chezmoi status

# Edit a managed file (opens in $EDITOR and applies on save)
chezmoi edit ~/.config/<path/to/file>
```

## Architecture

- **Source directory**: `~/.local/share/chezmoi/dot_config/` maps to `~/.config/`
- **Auto-sync**: A systemd user timer (`dotfiles-sync.timer`) runs `dotfiles-sync.sh` hourly, which re-adds modified files, pulls remote, commits, and pushes to `origin Legion-5-Pro`
- **chezmoi config**: `~/.config/chezmoi/chezmoi.toml` — `autoAdd = true`, `autoCommit = true`, `autoPush = false`

## Stack

- **WM**: Hyprland (Wayland) — config in `hypr/`
- **Shell**: Fish — config in `fish/`
- **Bar/UI**: Quickshell (QML) — `quickshell/ii/` (main panel), `quickshell/waffle/` (alt panel)
- **Theme**: Matugen (Material You) — generates colors for GTK, Hyprland, Fuzzel, KDE
- **Terminal**: Kitty, Foot
- **Prompt**: Starship

## Editing Workflow

When editing configs directly in `~/.config/`, run `chezmoi re-add <file>` afterward to sync back to the source. The auto-sync timer will handle git push, or run `dotfiles-sync.sh` manually.

## Known Issues & Fixes

### External monitor shows black screen after switching from mirror to extended
When changing `hypr/monitors.conf` from mirror mode to extended, Quickshell won't spawn background/bar layers on the new monitor even after `hyprctl reload` or restarting Quickshell. This is because Wayland clients need a `wl_output` announcement event, which only happens on a physical hotplug.

**Fix**: Unplug and replug the HDMI cable after applying the config change.