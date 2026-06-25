#!/bin/bash
# Toggle the lyrics pane between sptlrx (lyrics) and cmatrix.
# Works by writing the mode file and killing the current process —
# music-lyrics-wrapper.sh restarts automatically with the new mode.

MODE_FILE="/tmp/music-visual-mode"

# Only operate when dashboard is open
if ! hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
sys.exit(0 if any(c['class'] == 'music-dashboard' for c in json.load(sys.stdin)) else 1)
" 2>/dev/null; then
    exit 0
fi

current=$(cat "$MODE_FILE" 2>/dev/null || echo "lyrics")

if [ "$current" = "lyrics" ]; then
    echo "matrix" > "$MODE_FILE"
    pkill -f "sptlrx-scaled" 2>/dev/null
    pkill -x  cmatrix       2>/dev/null
    notify-send -a "Music Dashboard" -i audio-headphones "Visual: Matrix" -t 1200
else
    echo "lyrics" > "$MODE_FILE"
    pkill -f "sptlrx-scaled" 2>/dev/null
    pkill -x  cmatrix       2>/dev/null
    notify-send -a "Music Dashboard" -i audio-headphones "Visual: Lyrics" -t 1200
fi
