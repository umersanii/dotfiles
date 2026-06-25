#!/bin/bash
# Music dashboard: single kitty window with internal splits.
# Toggle: running → close; closed → open.

DBG=/tmp/music-dashboard-debug.log
SCRIPTS="$HOME/.config/hypr/hyprland/scripts"
echo "$(date '+%H:%M:%S') === Started ===" >> "$DBG"

is_running() {
    hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
sys.exit(0 if any(c['class'] == 'music-dashboard' for c in json.load(sys.stdin)) else 1)
" 2>/dev/null
}

close_all() {
    hyprctl dispatch closewindow "class:music-dashboard" 2>/dev/null
    pkill -f "cava-colors.py" 2>/dev/null
    pkill -f "keyboard-music-sync.py" 2>/dev/null
    rm -f /tmp/music-dashboard-kitty-socket /tmp/music-visual-mode
}

if is_running; then
    echo "$(date '+%H:%M:%S') Closing" >> "$DBG"
    close_all
    notify-send -a "Music Dashboard" -i audio-headphones "Closed" -t 2000
    exit 0
fi

echo "$(date '+%H:%M:%S') Opening" >> "$DBG"
close_all

notify-send -a "Music Dashboard" -i audio-headphones "Opening..." -t 2000

python3 "$SCRIPTS/cava-colors.py" &
python3 "$SCRIPTS/keyboard-music-sync.py" &

kitty --class music-dashboard -e "$SCRIPTS/music-dashboard-init.sh" &

echo "$(date '+%H:%M:%S') === Done ===" >> "$DBG"
