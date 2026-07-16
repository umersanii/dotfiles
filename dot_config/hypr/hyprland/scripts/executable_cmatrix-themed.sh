#!/bin/bash
# cmatrix themed to album art color via /tmp/cava-key-color
KEY_COLOR_FILE="/tmp/cava-key-color"

set_color() {
    local hex="${1:-b4b4b4}"
    hex="${hex#\#}"
    printf "\033]4;2;rgb:%02x/%02x/%02x\033\\" $((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))
}

[ -f "$KEY_COLOR_FILE" ] && set_color "$(cat "$KEY_COLOR_FILE")"

# Update color in background while cmatrix runs
(while true; do
    [ -f "$KEY_COLOR_FILE" ] && set_color "$(cat "$KEY_COLOR_FILE")"
    sleep 1.5
done) &
BG_PID=$!

cmatrix -b -u 4

kill "$BG_PID" 2>/dev/null
