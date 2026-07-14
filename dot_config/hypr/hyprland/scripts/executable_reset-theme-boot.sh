#!/bin/bash
# reset-theme-boot: undo a leftover music-theme-sync tint from an unclean
# shutdown. music-theme-sync.sh only restores base colors/wallpaper/border on
# a clean TERM/INT/EXIT; a hard shutdown or crash mid-song leaves
# base-colors.json / base-wallpaper snapshots in place and colors.json /
# wallpaperPath stuck on the tinted values. Runs once at Hyprland start,
# before quickshell reads colors.json.

BASE_COLORS="$HOME/.cache/muser/base-colors.json"
BASE_WALL_FILE="$HOME/.cache/muser/base-wallpaper"
COLORS="$HOME/.local/state/quickshell/user/generated/colors.json"
SHELL_CONFIG="$HOME/.config/illogical-impulse/config.json"

if [ -f "$BASE_COLORS" ]; then
    cp "$BASE_COLORS" "$COLORS"
    rm -f "$BASE_COLORS"
fi

if [ -f "$BASE_WALL_FILE" ] && [ -f "$SHELL_CONFIG" ]; then
    base_wall=$(cat "$BASE_WALL_FILE")
    if jq --arg p "$base_wall" '.background.wallpaperPath = $p' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp"; then
        mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"
    else
        rm -f "$SHELL_CONFIG.tmp"
    fi
    rm -f "$BASE_WALL_FILE"
fi
