#!/bin/bash
# monitor-scale.sh — Increase/decrease the focused monitor's scale on the fly
# Usage: monitor-scale.sh [up|down] [step]
set -euo pipefail

DIRECTION="${1:-up}"
STEP="${2:-0.05}"

MON_JSON=$(hyprctl monitors -j | jq -c '.[] | select(.focused==true)')
NAME=$(jq -r '.name' <<<"$MON_JSON")
SCALE=$(jq -r '.scale' <<<"$MON_JSON")
WIDTH=$(jq -r '.width' <<<"$MON_JSON")
HEIGHT=$(jq -r '.height' <<<"$MON_JSON")
REFRESH=$(jq -r '.refreshRate' <<<"$MON_JSON")
X=$(jq -r '.x' <<<"$MON_JSON")
Y=$(jq -r '.y' <<<"$MON_JSON")

if [ "$DIRECTION" = "up" ]; then
    NEW_SCALE=$(awk -v s="$SCALE" -v st="$STEP" 'BEGIN { printf "%.2f", s + st }')
else
    NEW_SCALE=$(awk -v s="$SCALE" -v st="$STEP" 'BEGIN { v = s - st; if (v < 0.1) v = 0.1; printf "%.2f", v }')
fi

hyprctl keyword monitor "$NAME, ${WIDTH}x${HEIGHT}@${REFRESH}, ${X}x${Y}, ${NEW_SCALE}"
notify-send -t 1000 -r 91190 "Monitor Scale" "$NAME: $NEW_SCALE"
