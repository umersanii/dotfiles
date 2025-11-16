#!/usr/bin/env bash

STATE_FILE="/tmp/waybar_mpris_state"
LOG_FILE="/tmp/mpris-toggle.log"

# Get the first available player
player="$(playerctl -l 2>/dev/null | head -n1)"

echo "$(date): Player: $player" >> "$LOG_FILE"

# Read our own tracked state (fallback to playerctl status if not exists)
if [ -f "$STATE_FILE" ]; then
    tracked_status="$(cat "$STATE_FILE")"
else
    tracked_status="$(playerctl --player="$player" status 2>/dev/null)"
fi

echo "$(date): Tracked status: $tracked_status" >> "$LOG_FILE"

# Send appropriate command based on tracked state
if [ "$tracked_status" = "Playing" ]; then
    playerctl --player="$player" pause
    new_status="Paused"
    echo "$(date): Sent pause" >> "$LOG_FILE"
else
    playerctl --player="$player" play
    new_status="Playing"
    echo "$(date): Sent play" >> "$LOG_FILE"
fi

# Save the new state
echo "$new_status" > "$STATE_FILE"
echo "$(date): New tracked status: $new_status" >> "$LOG_FILE"
