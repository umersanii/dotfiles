#!/bin/bash
# Toggle Hyprland transparency (opacity + blur) on/off

STATE_FILE="/tmp/hypr_transparency_off"

if [[ -f "$STATE_FILE" ]]; then
    # Transparency is currently OFF — restore it
    hyprctl keyword decoration:active_opacity 0.85
    hyprctl keyword decoration:inactive_opacity 0.65
    hyprctl keyword decoration:blur:enabled true
    rm -f "$STATE_FILE"
else
    # Transparency is currently ON — disable it
    hyprctl keyword decoration:active_opacity 1.0
    hyprctl keyword decoration:inactive_opacity 1.0
    hyprctl keyword decoration:blur:enabled false
    touch "$STATE_FILE"
fi
