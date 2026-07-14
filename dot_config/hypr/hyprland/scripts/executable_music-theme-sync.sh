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

# Wallpaper tint: blend the base wallpaper 15% toward the (lightness-lifted)
# key color and point quickshell's wallpaperPath at the blended copy. The
# source wallpaper file is never modified; quickshell picks up the config
# change live (Config.qml watches it).
SHELL_CONFIG="$HOME/.config/illogical-impulse/config.json"
WALL_CACHE="$HOME/.cache/muser/wall-tint"
BASE_WALL_FILE="$HOME/.cache/muser/base-wallpaper"
WALL_BLEND=15

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

set_wallpaper() {
    [ -f "$SHELL_CONFIG" ] || return
    if jq --arg p "$1" '.background.wallpaperPath = $p' "$SHELL_CONFIG" > "$SHELL_CONFIG.tmp"; then
        mv "$SHELL_CONFIG.tmp" "$SHELL_CONFIG"
    else
        rm -f "$SHELL_CONFIG.tmp"
    fi
}

apply_wall_tint() {
    local key="${1#\#}" current base lifted hash out
    [ -f "$SHELL_CONFIG" ] || return
    current=$(jq -r '.background.wallpaperPath // empty' "$SHELL_CONFIG")
    [ -n "$current" ] || return
    # A path outside the tint cache is a genuine base wallpaper — remember it
    # (covers the user switching wallpapers mid-playback). A cache path means
    # our tint is active; keep the existing snapshot.
    case "$current" in
        "$WALL_CACHE"/*) ;;
        *) printf '%s' "$current" > "$BASE_WALL_FILE" ;;
    esac
    base=$(cat "$BASE_WALL_FILE" 2>/dev/null)
    [ -f "$base" ] || return
    case "${base,,}" in *.mp4|*.webm|*.mkv|*.avi|*.mov) return ;; esac
    # Lift the key color: keep its hue, raise lightness/saturation so the tint
    # still reads on a dark wallpaper (a dark key would just blend to mud)
    lifted=$(python3 -c '
import sys, colorsys
c = sys.argv[1]
r, g, b = (int(c[i:i+2], 16) / 255 for i in (0, 2, 4))
h, l, s = colorsys.rgb_to_hls(r, g, b)
r, g, b = colorsys.hls_to_rgb(h, 0.62, max(s, 0.55))
print("%02x%02x%02x" % (round(r*255), round(g*255), round(b*255)))' "$key") || return
    hash=$(printf '%s:%s:%s' "$base" "$lifted" "$WALL_BLEND" | md5sum | cut -d' ' -f1)
    out="$WALL_CACHE/$hash.jpg"
    if [ ! -s "$out" ]; then
        mkdir -p "$WALL_CACHE"
        if ! magick "$base" \( +clone -fill "#$lifted" -tint 100 \) \
                -define compose:args=$WALL_BLEND -compose blend -composite \
                -quality 92 "$out" 2>/dev/null; then
            rm -f "$out"
            return
        fi
    fi
    [ "$current" = "$out" ] || set_wallpaper "$out"
}

restore_wall() {
    [ -f "$BASE_WALL_FILE" ] || return
    # Only restore if our tint is still the active wallpaper — never stomp a
    # wallpaper the user picked mid-playback
    local current
    current=$(jq -r '.background.wallpaperPath // empty' "$SHELL_CONFIG" 2>/dev/null)
    case "$current" in
        "$WALL_CACHE"/*) set_wallpaper "$(cat "$BASE_WALL_FILE")" ;;
    esac
    rm -f "$BASE_WALL_FILE"
}

restore_base() {
    # Border reset runs even without a snapshot: a previous instance may have
    # tinted the border, then died without restoring it
    hyprctl keyword general:col.active_border "rgba(FFFFFFFF)" >/dev/null 2>&1
    restore_wall
    [ -f "$BASE_FILE" ] || return
    cp "$BASE_FILE" "$COLORS"
    rm -f "$BASE_FILE"
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
    # Tint the wallpaper with the raw key color (truer to the album art than
    # matugen's tonal primary)
    apply_wall_tint "$1"
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
