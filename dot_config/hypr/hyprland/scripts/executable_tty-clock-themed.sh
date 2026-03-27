#!/bin/bash
# Launches tty-clock with color synced to the current album art.
# Uses OSC 4 escape to redefine terminal color index 2 live —
# tty-clock updates without restarting.

CAVA_CONFIG="$HOME/.config/cava/config"

get_key_hex() {
    # Use the middle gradient stop as the key color
    grep -m1 "gradient_color_5" "$CAVA_CONFIG" 2>/dev/null \
        | grep -oP "(?<='#)[0-9a-fA-F]{6}"
}

apply_color() {
    local hex="$1"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    # Redefine color index 2 ("green") in the terminal palette
    printf '\033]4;2;rgb:%02x/%02x/%02x\033\\' "$r" "$g" "$b"
}

# Apply current color before launching so first frame is correct
hex=$(get_key_hex)
[ -n "$hex" ] && apply_color "$hex"

# Launch tty-clock: centered, color 2, date visible, date format, no quit on keypress
tty-clock -c -C 2 -f "%Y-%m-%d" -n &
CLOCK_PID=$!

last_hex="$hex"

while kill -0 "$CLOCK_PID" 2>/dev/null; do
    sleep 2
    hex=$(get_key_hex)
    if [ -n "$hex" ] && [ "$hex" != "$last_hex" ]; then
        last_hex="$hex"
        apply_color "$hex"
    fi
done
