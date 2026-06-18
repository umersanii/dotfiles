#!/bin/bash
# Music dashboard: muser (top-left) + cava (bottom-left) + sptlrx-scaled (right)
# Window rules in rules.conf handle float + position + size.
# Press shortcut again to close everything.

DBG=/tmp/music-dashboard-debug.log
echo "$(date '+%H:%M:%S') === Script started ===" >> "$DBG"

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
    echo "$(date '+%H:%M:%S') Dashboard is running, closing" >> "$DBG"
    close_all
    rm -f /tmp/music-visual-mode
    notify-send -a "Music Dashboard" -i audio-headphones "Closed" -t 2000
    exit 0
fi

echo "$(date '+%H:%M:%S') Dashboard not running, opening" >> "$DBG"

# Kill any stale processes
close_all
pkill -x cava 2>/dev/null
pkill -f sptlrx-scaled 2>/dev/null
# Kill existing muser if already open (avoid duplicate)
if hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
sys.exit(0 if any('Music Player' in c['title'] for c in json.load(sys.stdin)) else 1)
" 2>/dev/null; then
    echo "$(date '+%H:%M:%S') Found stale muser window, killing" >> "$DBG"
    pkill -f "standalone_app.py" 2>/dev/null
    sleep 0.3
fi

sleep 0.3

notify-send -a "Music Dashboard" -i audio-headphones "Opening..." -t 2000

echo "$(date '+%H:%M:%S') Launching cava-colors..." >> "$DBG"
python3 ~/.config/hypr/hyprland/scripts/cava-colors.py &
echo "$(date '+%H:%M:%S') Launching muser..." >> "$DBG"
muser &
MUSER_PID=$!
echo "$(date '+%H:%M:%S') muser launcher PID=$MUSER_PID" >> "$DBG"
sleep 0.6
echo "$(date '+%H:%M:%S') Launching kitty cava..." >> "$DBG"
kitty --class music-cava -e cava &
sleep 0.3
echo "$(date '+%H:%M:%S') Launching kitty sptlrx..." >> "$DBG"
kitty --class music-sptlrx -e "$HOME/.local/bin/sptlrx-scaled" &
sleep 0.3
echo "$(date '+%H:%M:%S') Launching kitty clock..." >> "$DBG"
kitty --class music-clock -e ~/.config/hypr/hyprland/scripts/tty-clock-themed.sh &
echo "$(date '+%H:%M:%S') All launched, checking muser process..." >> "$DBG"
sleep 1
if ps -p "$MUSER_PID" > /dev/null 2>&1; then
    echo "$(date '+%H:%M:%S') muser launcher still running" >> "$DBG"
else
    wait "$MUSER_PID" 2>/dev/null
    echo "$(date '+%H:%M:%S') muser launcher exited with code=$?" >> "$DBG"
fi
# Check if standalone_app.py is actually running
if pgrep -f "[s]tandalone_app.py" > /dev/null 2>&1; then
    echo "$(date '+%H:%M:%S') standalone_app.py IS running" >> "$DBG"
else
    echo "$(date '+%H:%M:%S') standalone_app.py NOT running!" >> "$DBG"
fi
echo "$(date '+%H:%M:%S') === Script done ===" >> "$DBG"
