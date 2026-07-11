#!/bin/bash
# Music dashboard: single web window (muser: player + visualizer + lyrics + clock cards)
# Window rules in rules.conf handle float + position + size.
# Press shortcut again to close everything.

DBG=/tmp/music-dashboard-debug.log
echo "$(date '+%H:%M:%S') === Script started ===" >> "$DBG"

is_running() {
    hyprctl clients -j 2>/dev/null | python3 -c "
import json, sys
sys.exit(0 if any('Music Player' in c['title'] for c in json.load(sys.stdin)) else 1)
" 2>/dev/null
}

close_all() {
    pkill -f "standalone_app.py" 2>/dev/null
    pkill -x cava 2>/dev/null
    pkill -f "cava-colors.py" 2>/dev/null
    pkill -f "keyboard-music-sync.py" 2>/dev/null
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
sleep 0.3

notify-send -a "Music Dashboard" -i audio-headphones "Opening..." -t 2000

echo "$(date '+%H:%M:%S') Launching cava-colors..." >> "$DBG"
python3 ~/.config/hypr/hyprland/scripts/cava-colors.py &
echo "$(date '+%H:%M:%S') Launching keyboard-music-sync..." >> "$DBG"
python3 ~/.config/hypr/hyprland/scripts/keyboard-music-sync.py &
echo "$(date '+%H:%M:%S') Launching cava (raw output, no terminal)..." >> "$DBG"
rm -f /tmp/cava-dashboard.fifo
cava &
echo "$(date '+%H:%M:%S') Launching muser..." >> "$DBG"
muser &
MUSER_PID=$!
echo "$(date '+%H:%M:%S') muser launcher PID=$MUSER_PID" >> "$DBG"
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

# Fit the window inside the monitor's non-reserved area so it clears whatever
# bar is running (waybar/quickshell reserve space via exclusive zones)
GEOM=$(hyprctl monitors -j | python3 -c "
import json, sys
m = json.load(sys.stdin)[0]
lw, lh = m['width'] / m['scale'], m['height'] / m['scale']
left, top, right, bottom = m['reserved']
margin = 8
print(int(left + margin), int(top + margin),
      int(lw - left - right - 2 * margin), int(lh - top - bottom - 2 * margin))
")
read -r WX WY WW WH <<< "$GEOM"
echo "$(date '+%H:%M:%S') Applying geometry ${WW}x${WH} at ${WX},${WY}" >> "$DBG"
for _ in $(seq 1 50); do
    if hyprctl clients -j 2>/dev/null | grep -q "Music Player"; then
        hyprctl dispatch resizewindowpixel "exact $WW $WH,title:.*Music Player.*" >/dev/null
        hyprctl dispatch movewindowpixel "exact $WX $WY,title:.*Music Player.*" >/dev/null
        break
    fi
    sleep 0.2
done
echo "$(date '+%H:%M:%S') === Script done ===" >> "$DBG"
