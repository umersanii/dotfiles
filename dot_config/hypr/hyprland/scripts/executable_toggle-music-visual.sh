#!/bin/bash
# Toggle the dashboard's lyrics card between lyrics and matrix (digital-rain) mode.
# The card itself renders both modes client-side; this just pings the running
# dashboard's API, which flips the mode and broadcasts it over the websocket.

# Only operate when the dashboard is open
if ! pgrep -f "standalone_app.py" > /dev/null 2>&1; then
    exit 0
fi

port=$(cat /tmp/muser-port 2>/dev/null)
if [ -z "$port" ]; then
    exit 0
fi

response=$(curl -s -X POST "http://127.0.0.1:${port}/api/toggle-visual")
mode=$(echo "$response" | python3 -c "import json,sys; print(json.load(sys.stdin).get('mode','lyrics'))" 2>/dev/null)

if [ "$mode" = "matrix" ]; then
    notify-send -a "Music Dashboard" -i audio-headphones "Visual: Matrix" -t 1200
else
    notify-send -a "Music Dashboard" -i audio-headphones "Visual: Lyrics" -t 1200
fi
