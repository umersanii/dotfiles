#!/bin/bash
# music-theme-sync: mirror the muser/cava accent color onto the whole desktop
# theme via switchwall.sh (matugen -> Hyprland/GTK/Quickshell/KDE/fuzzel).
#
# Follows /tmp/cava-key-color (written by cava-colors.py). Before the first
# takeover the current accentColor from the shell config is snapshotted to
# ~/.cache/muser/base-accent; it is restored when this script is killed
# (dashboard close) or when cava-colors falls back to its default gray key
# (playback stopped / grayscale art). A leftover snapshot from a crashed run
# is kept as-is so the true base is never overwritten by a music color.

KEY_FILE=/tmp/cava-key-color
BASE_FILE="$HOME/.cache/muser/base-accent"
SWITCHWALL="$HOME/.config/quickshell/ii/scripts/colors/switchwall.sh"
SHELL_CONFIG="$HOME/.config/illogical-impulse/config.json"
GEN_DIR="$HOME/.local/state/quickshell/user/generated"
DEFAULT_KEY=888888

# switchwall sources the quickshell venv; make sure the var exists even when
# launched outside a full Hyprland env
export ILLOGICAL_IMPULSE_VIRTUAL_ENV="${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-$HOME/.local/state/quickshell/.venv}"

mkdir -p "$(dirname "$BASE_FILE")"

# The quickshell bar reads colors.json, whose matugen template is hardcoded
# to the white base theme. matugen also renders colors-live.json (real
# placeholders), so for music colors we swap that in; restoring the base
# accent regenerates the hardcoded white colors.json on its own.
apply_music() {
    "$SWITCHWALL" --noswitch --color "$1" >/dev/null 2>&1
    if [ -s "$GEN_DIR/colors-live.json" ]; then
        cp "$GEN_DIR/colors-live.json" "$GEN_DIR/colors.json"
    fi
}

apply_base() {
    "$SWITCHWALL" --noswitch --color "$1" >/dev/null 2>&1
}

save_base() {
    [ -f "$BASE_FILE" ] && return
    local cur
    cur=$(jq -r '.appearance.palette.accentColor // empty' "$SHELL_CONFIG" 2>/dev/null)
    if [[ "$cur" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        echo "$cur" > "$BASE_FILE"
    else
        # no accent set: base theme comes from the wallpaper
        echo "clear" > "$BASE_FILE"
    fi
}

restore_base() {
    [ -f "$BASE_FILE" ] || return
    apply_base "$(cat "$BASE_FILE")"
    rm -f "$BASE_FILE"
}

on_exit() {
    trap - TERM INT EXIT
    restore_base
    exit 0
}
trap on_exit TERM INT EXIT

start=$(date +%s)
last=""
while true; do
    # Ignore a key color left over from a previous session; cava-colors
    # rewrites the file within seconds of starting.
    mtime=$(stat -c %Y "$KEY_FILE" 2>/dev/null || echo 0)
    if [ "$mtime" -ge "$start" ]; then
        color=$(tr -cd '0-9a-fA-F' < "$KEY_FILE" 2>/dev/null)
        if [[ ${#color} -eq 6 && "$color" != "$last" ]]; then
            last="$color"
            if [[ "${color,,}" == "$DEFAULT_KEY" ]]; then
                restore_base
            else
                save_base
                apply_music "#$color"
            fi
        fi
    fi
    sleep 2
done
