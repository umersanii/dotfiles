#!/bin/bash
# Toggle Hyprland window border, rounding, and gaps on/off

STATE_FILE="/tmp/hypr_border_off"

if [[ -f "$STATE_FILE" ]]; then
    # Currently OFF — restore border, rounding, and gaps
    hyprctl keyword general:border_size 1
    hyprctl keyword decoration:rounding 18
    hyprctl keyword decoration:rounding_power 2.4
    hyprctl keyword general:gaps_in 4
    hyprctl keyword general:gaps_out 5
    rm -f "$STATE_FILE"
else
    # Currently ON — disable border, rounding, and gaps
    hyprctl keyword general:border_size 0
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:rounding_power 2
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    touch "$STATE_FILE"
fi
