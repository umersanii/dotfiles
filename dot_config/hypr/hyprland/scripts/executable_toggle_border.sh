#!/bin/bash
# Toggle Hyprland active/inactive window border on/off

STATE_FILE="/tmp/hypr_border_off"

if [[ -f "$STATE_FILE" ]]; then
    # Currently OFF — restore border
    hyprctl keyword general:border_size 1
    rm -f "$STATE_FILE"
else
    # Currently ON — disable border
    hyprctl keyword general:border_size 0
    touch "$STATE_FILE"
fi
