#!/bin/bash
# music-theme-sync: tint the quickshell bar's ACCENT colors with the muser/cava
# key color while a song plays. Accents only — backgrounds, surfaces, outlines
# and all other apps (GTK/KDE/hyprland/fuzzel/terminals) are never touched.
#
# Follows /tmp/cava-key-color (written by cava-colors.py). matugen renders a
# full Material palette from the key color into colors-live.json (via the
# minimal music.toml config), and only the primary/secondary/tertiary families
# are merged into the colors.json the bar reads. The pristine colors.json is
# snapshotted before the first takeover and restored on dashboard close,
# playback stop, or grayscale art (cava-colors' default gray key). A snapshot
# left by a crashed run is kept as-is so a music tint can never become "base".

KEY_FILE=/tmp/cava-key-color
GEN_DIR="$HOME/.local/state/quickshell/user/generated"
COLORS="$GEN_DIR/colors.json"
LIVE="$GEN_DIR/colors-live.json"
BASE_FILE="$HOME/.cache/muser/base-colors.json"
MUSIC_MATUGEN="$HOME/.config/matugen/music.toml"
DEFAULT_KEY=888888

ACCENT_KEYS='{primary, on_primary, primary_container, on_primary_container,
  primary_fixed, primary_fixed_dim, on_primary_fixed, on_primary_fixed_variant,
  inverse_primary, surface_tint,
  secondary, on_secondary, secondary_container, on_secondary_container,
  secondary_fixed, secondary_fixed_dim, on_secondary_fixed, on_secondary_fixed_variant,
  tertiary, on_tertiary, tertiary_container, on_tertiary_container,
  tertiary_fixed, tertiary_fixed_dim, on_tertiary_fixed, on_tertiary_fixed_variant}'

mkdir -p "$(dirname "$BASE_FILE")"

save_base() {
    [ -f "$BASE_FILE" ] && return
    cp "$COLORS" "$BASE_FILE"
}

restore_base() {
    [ -f "$BASE_FILE" ] || return
    cp "$BASE_FILE" "$COLORS"
    rm -f "$BASE_FILE"
    # Back to the base theme's white active border (custom/colors-override.conf)
    hyprctl keyword general:col.active_border "rgba(FFFFFFFF)" >/dev/null 2>&1
}

apply_music() {
    matugen --config "$MUSIC_MATUGEN" color hex "$1" --mode dark \
        --type scheme-tonal-spot >/dev/null 2>&1
    [ -s "$LIVE" ] || return
    save_base
    # Base palette + accent families from the music palette; atomic swap so
    # quickshell never reads a half-written file
    if jq -s ".[0] + (.[1] | $ACCENT_KEYS)" "$BASE_FILE" "$LIVE" > "$COLORS.tmp"; then
        mv "$COLORS.tmp" "$COLORS"
    else
        rm -f "$COLORS.tmp"
    fi
    # Tint the hyprland active window border with the music accent
    accent=$(jq -r '.primary // empty' "$LIVE" | tr -cd '0-9a-fA-F')
    if [[ ${#accent} -eq 6 ]]; then
        hyprctl keyword general:col.active_border "rgba(${accent}FF)" >/dev/null 2>&1
    fi
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
                apply_music "#$color"
            fi
        fi
    fi
    sleep 2
done
