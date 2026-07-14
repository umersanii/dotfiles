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

# Hyprland snaps arbitrary scale requests to its own "nice" scale for the
# resolution, so a naive fixed step can silently no-op (request lands on the
# same snapped value). Keep nudging further in the requested direction until
# the applied scale actually changes.
ATTEMPT=0
REQUEST_SCALE="$SCALE"
APPLIED_SCALE="$SCALE"
while [ "$ATTEMPT" -lt 10 ]; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ "$DIRECTION" = "up" ]; then
        REQUEST_SCALE=$(awk -v s="$REQUEST_SCALE" -v st="$STEP" 'BEGIN { printf "%.4f", s + st }')
    else
        REQUEST_SCALE=$(awk -v s="$REQUEST_SCALE" -v st="$STEP" 'BEGIN { v = s - st; if (v < 0.1) v = 0.1; printf "%.4f", v }')
    fi

    hyprctl keyword monitor "$NAME, ${WIDTH}x${HEIGHT}@${REFRESH}, ${X}x${Y}, ${REQUEST_SCALE}" >/dev/null
    sleep 0.05
    APPLIED_SCALE=$(hyprctl monitors -j | jq -r --arg n "$NAME" '.[] | select(.name==$n) | .scale')

    if [ "$APPLIED_SCALE" != "$SCALE" ]; then
        break
    fi
done

notify-send -t 1000 -r 91190 "Monitor Scale" "$NAME: $APPLIED_SCALE"
