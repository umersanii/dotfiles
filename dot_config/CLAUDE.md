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

---

## Ongoing: NVIDIA Isaac Sim Setup (IN PROGRESS)

**Goal**: Run `nvcr.io/nvidia/isaac-sim:5.0.0` (or 5.1.0) headlessly via Docker.

### Current State
- **Kernel**: `6.12.75-1-lts` (pinned via `IgnorePkg` in `/etc/pacman.conf`)
- **Driver**: `nvidia 610.43.02` (upgraded from 565.77)
- **GPU**: RTX 3070 Ti Laptop GPU
- **Docker runtime**: nvidia set as default in `/etc/docker/daemon.json`
- `nvidia-smi` works on host and inside Docker
- CUDA works on host (`cuInit` returns 0)
- CUDA works in Docker only with `--privileged`
- Isaac Sim 5.0.0 and 5.1.0-rc.19 both segfault in `librtx.scenedb.plugin.so` at `carbOnPluginStartup` — driver 610 is too new for Isaac Sim's bundled RTX libraries

### What Was Tried
- Isaac Sim 4.5.0 — broken: requires driver ≤565, but 565.77 can't build on kernel ≥6.12 (missing `phys_to_dma`, `dma_is_direct`, `ioremap_driver_hardened_wc`)
- Driver 565.77 on kernel 6.12 — broken: GCC 14 + missing kernel APIs, unfixable without patching driver source
- Isaac Sim 5.1.0-rc.19 — segfault (rc build, unstable)
- Isaac Sim 5.0.0 — segfault in RTX scenedb plugin, even with `--privileged`
- Tried on bare metal (no Docker) — also didn't work

### Next Step
Downgrade NVIDIA driver to ~575.x — new enough to compile on kernel 6.12, within Isaac Sim 5.0.0's tested range:
```bash
curl -s "https://archive.archlinux.org/packages/n/nvidia-dkms/" | grep "575\."
```
Then downgrade via `sudo pacman -U <archive-url>` for `nvidia-dkms`, `nvidia-utils`, `lib32-nvidia-utils`.

### Key Config Files
- `/etc/pacman.conf` — `IgnorePkg = linux-lts linux-lts-headers` (kernel pinned to 6.12)
- `/etc/docker/daemon.json` — nvidia default runtime
- `/usr/src/nvidia-565.77/Kbuild` — was patched with `-Wno-error=incompatible-pointer-types` (no longer relevant, driver is now 610)
