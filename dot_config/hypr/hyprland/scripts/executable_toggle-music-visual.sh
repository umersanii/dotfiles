#!/bin/bash
# Toggle music-sptlrx panel between sptlrx-scaled (lyrics) and cmatrix (matrix)
MODE_FILE="/tmp/music-visual-mode"

# Only operate when dashboard is open
if ! hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
sys.exit(0 if any(c['class'] in ('music-cava', 'music-sptlrx') for c in json.load(sys.stdin)) else 1)
" 2>/dev/null; then
    exit 0
fi

current=$(cat "$MODE_FILE" 2>/dev/null || echo "lyrics")

hyprctl dispatch closewindow "class:music-sptlrx" 2>/dev/null
sleep 0.15

if [ "$current" = "lyrics" ]; then
    pkill -f sptlrx-scaled 2>/dev/null
    kitty --class music-sptlrx -e ~/.config/hypr/hyprland/scripts/cmatrix-themed.sh &
    echo "matrix" > "$MODE_FILE"
    notify-send -a "Music Dashboard" -i audio-headphones "Visual: Matrix" -t 1200
else
    pkill -x cmatrix 2>/dev/null
    kitty --class music-sptlrx -e "$HOME/.local/bin/sptlrx-scaled" &
    echo "lyrics" > "$MODE_FILE"
    notify-send -a "Music Dashboard" -i audio-headphones "Visual: Lyrics" -t 1200
fi
