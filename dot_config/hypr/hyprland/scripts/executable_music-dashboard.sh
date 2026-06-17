#!/bin/bash
# Music dashboard: muser (top-left) + cava (bottom-left) + sptlrx-scaled (right)
# Window rules in rules.conf handle float + position + size.
# Press shortcut again to close everything.

is_running() {
    hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
sys.exit(0 if any(c['class'] in ('music-cava', 'music-sptlrx') for c in json.load(sys.stdin)) else 1)
" 2>/dev/null
}

close_all() {
    pkill -f "standalone_app.py" 2>/dev/null
    pkill -f "cava-colors.py" 2>/dev/null
    pkill -f "tty-clock-themed.sh" 2>/dev/null
    pkill -f "tty-clock" 2>/dev/null
    hyprctl dispatch closewindow "class:music-cava" 2>/dev/null
    hyprctl dispatch closewindow "class:music-sptlrx" 2>/dev/null
    hyprctl dispatch closewindow "class:music-clock" 2>/dev/null
}

if is_running; then
    close_all
    rm -f /tmp/music-visual-mode
    notify-send -a "Music Dashboard" -i audio-headphones "Closed" -t 2000
    exit 0
fi

# Kill any stale processes
close_all
pkill -x cava 2>/dev/null
pkill -f sptlrx-scaled 2>/dev/null
# Kill existing muser if already open (avoid duplicate)
if hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
sys.exit(0 if any('Music Player' in c['title'] for c in json.load(sys.stdin)) else 1)
" 2>/dev/null; then
    pkill -f "standalone_app.py" 2>/dev/null
    sleep 0.3
fi

sleep 0.3

notify-send -a "Music Dashboard" -i audio-headphones "Opening..." -t 2000

python3 ~/.config/hypr/hyprland/scripts/cava-colors.py &
muser &
sleep 0.6
kitty --class music-cava -e cava &
sleep 0.3
kitty --class music-sptlrx -e "$HOME/.local/bin/sptlrx-scaled" &
sleep 0.3
kitty --class music-clock -e ~/.config/hypr/hyprland/scripts/tty-clock-themed.sh &
