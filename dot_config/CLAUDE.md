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

## Local LLM (Gemma 4 via Ollama)

- Hardware: RTX 3070 Ti Laptop (8GB VRAM) + 30GB RAM — see `whichllm` (`uvx whichllm@latest`) for live hardware-fit rankings
- Model: `gemma4:26b-a4b-it-q4_K_M` (MoE, ~4B active params, partial VRAM/RAM offload) pulled via `ollama pull gemma4:26b-a4b-it-q4_K_M`
- Requires Ollama ≥ 0.32 (function calling support) — installed at `/usr/local/bin/ollama`, `ollama.service` is an enabled system unit and starts automatically at boot
- Wired into the quickshell AI sidebar (`Super, A`) as an `extraModels` entry in `~/.config/illogical-impulse/config.json`, served through Ollama's OpenAI-compatible endpoint `http://localhost:11434/v1/chat/completions`
- Set as the default sidebar model via `ai.model` in `~/.local/state/quickshell/states.json` (runtime state, not chezmoi-managed) — the model ID there is the sanitized form of the model name (`:` → `_`), e.g. `gemma4_26b-a4b-it-q4_K_M`
- Bar icon feedback: `~/.config/quickshell/ii/services/Ai.qml` exposes `isGenerating` (aliased to the request `Process.running`); `~/.config/quickshell/ii/modules/ii/bar/LeftSidebarButton.qml` uses `Ai.isGenerating && Ai.currentModelId.startsWith("gemma")` to pulse the top-left icon size/color (blue `#4FC3F7`) and give it a stop-start spin while a Gemma response is generating
- Ollama auto-unloads idle models after 5 min (`--keepalive` to override); avoid loading it when other GPU/RAM-heavy work is running to prevent swap thrashing

## Rice Design Rules

The rice is **monochrome: the UI is black & white; color comes only from content or errors.** Check every visual change against this.

- **Allowed color**: content-derived accents (muser album-art accent via `cava-colors.py`, wallpaper/media itself) and error/destructive states (red `#ff5555`). Nothing else gets hue.
- **Hierarchy by brightness, not hue**: most important = white, secondary = mid-grey `#8a8a8a`, tertiary = dark `#262626`. Use exact hex values, never named colors (`green`, `cyan`) that resolve through a terminal palette.
- **Single source of truth per surface**: hardcoded B&W overrides win; matugen must not also generate for that surface (e.g. `enableQtApps: false` in `illogical-impulse/config.json` because Qt uses the hand-made `~/.local/share/color-schemes/BlackWhite.colors`).
- **Consistency checklist** when touching theming: GTK3/4 (`adw-gtk3-dark` + B&W `gtk.css`), Qt/KDE (`BlackWhite` scheme in `kdeglobals`), Hyprland borders (`hypr/custom/colors-override.conf`), Fuzzel, Starship, cursor (Bibata-Modern-Classic 24 via `XCURSOR_*` in `hypr/custom/env.conf` + `~/.icons/default`), icons (Tela-circle-black).
- **Readability over effects**: windows stay opaque (`custom/general.conf`); focus is shown by `dim_inactive`, not transparency.
- **Shape & motion**: rounding 18 / `rounding_power 2.4`, Material 3 expressive curves, exits faster than entrances. Keep new surfaces in line.
- **Kitty is out of scope** for theme changes unless explicitly asked.

## Known Issues & Fixes

### External monitor shows black screen after switching from mirror to extended
When changing `hypr/monitors.conf` from mirror mode to extended, Quickshell won't spawn background/bar layers on the new monitor even after `hyprctl reload` or restarting Quickshell. This is because Wayland clients need a `wl_output` announcement event, which only happens on a physical hotplug.

**Fix**: Unplug and replug the HDMI cable after applying the config change.