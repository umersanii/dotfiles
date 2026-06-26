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

### Driver Compatibility Research (confirmed 2026-06-27)
- Isaac Sim 5.0.0 officially supports driver branches: **R570** (570.169), **R580** (580.95.05), **R595** (595.58.03)
- Driver **610.x is NOT listed** in any supported branch → causes `librtx.scenedb.plugin.so` segfault at `carbOnPluginStartup`
- R595 is not available in Arch repos/archive; R580 is the best available target
- All required 580.119.02-1 packages confirmed in Arch archive

### Current State
- **Kernel**: `6.12.75-1-lts` (pinned via `IgnorePkg` in `/etc/pacman.conf`)
- **Driver**: `nvidia-open-dkms 580.119.02` ✅ downgraded from 610.43.02 on 2026-06-27
  - DKMS module rebuilt successfully, CDI file updated
  - **NOT YET REBOOTED** — new driver not active until reboot
- **GPU**: RTX 3070 Ti Laptop GPU
- **Docker runtime**: nvidia set as default in `/etc/docker/daemon.json`
- Isaac Sim 5.0.0 and 5.1.0-rc.19 both segfault in `librtx.scenedb.plugin.so` at `carbOnPluginStartup` (with driver 610)

### What Was Tried
- Isaac Sim 4.5.0 — broken: requires driver ≤565, but 565.77 can't build on kernel ≥6.12 (missing `phys_to_dma`, `dma_is_direct`, `ioremap_driver_hardened_wc`)
- Driver 565.77 on kernel 6.12 — broken: GCC 14 + missing kernel APIs, unfixable without patching driver source
- Isaac Sim 5.1.0-rc.19 — segfault (rc build, unstable)
- Isaac Sim 5.0.0 — segfault in RTX scenedb plugin, even with `--privileged` and on bare metal
- Driver 610.43.02 — too new, not in any Isaac Sim supported branch

### Next Steps
1. **Pin nvidia packages** in `/etc/pacman.conf` to prevent auto-upgrade back to 610:
   ```bash
   sudo sed -i 's/IgnorePkg = linux-lts linux-lts-headers/IgnorePkg = linux-lts linux-lts-headers nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings/' /etc/pacman.conf
   ```
2. **Reboot** to activate the new driver
3. Verify with `nvidia-smi` (should show 580.119.02)
4. Re-run Isaac Sim 5.0.0 and check if segfault is gone

If 580 still segfaults → try R570 (570.153.02-1) from Arch archive.

### Key Config Files
- `/etc/pacman.conf` — `IgnorePkg = linux-lts linux-lts-headers` (kernel pinned to 6.12); add nvidia packages after downgrade
- `/etc/docker/daemon.json` — nvidia default runtime
