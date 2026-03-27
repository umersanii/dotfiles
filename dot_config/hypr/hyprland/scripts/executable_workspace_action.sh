#!/usr/bin/env bash

# Get current workspace ID and monitor name
curr_workspace="$(hyprctl activeworkspace -j | jq -r ".id")"
curr_monitor="$(hyprctl activeworkspace -j | jq -r ".monitor")"

# Validate input
dispatcher="$1"
target="$2"

if [[ -z "${dispatcher}" || "${dispatcher}" == "--help" || "${dispatcher}" == "-h" || -z "${target}" ]]; then
  echo "Usage: $0 <dispatcher> <target>"
  exit 1
fi

# Determine workspace range based on active monitor
# eDP-1  → 1-10   (offset 0)
# HDMI-A-1 → 11-20 (offset 10)
if [[ "${curr_monitor}" == "HDMI-A-1" ]]; then
    ws_min=11
    ws_max=20
    ws_offset=10
else
    ws_min=1
    ws_max=10
    ws_offset=0
fi

# Function to cap workspace within the active monitor's range
cap_workspace() {
    local ws=$1
    if [ "$ws" -gt "$ws_max" ]; then echo "$ws_max";
    elif [ "$ws" -lt "$ws_min" ]; then echo "$ws_min";
    else echo "$ws"; fi
}

# Handle special workspaces first (non-numeric, non-relative)
if [[ ! "${target}" =~ ^[0-9]+$ ]] && [[ ! "${target}" =~ ^[rm]?[\+\-][0-9]+$ ]]; then
    hyprctl dispatch "${dispatcher}" "${target}"
    exit 0
fi

# Calculate target workspace ID
if [[ "${target}" =~ ^[rm]?[\+\-][0-9]+$ ]]; then
    # Relative target: +1, -1, r+1, m+1, etc.
    offset=$(echo "${target}" | grep -oP '[\+\-][0-9]+')
    new_ws=$((curr_workspace + offset))
    target_workspace=$(cap_workspace "$new_ws")
elif [[ "${target}" =~ ^[0-9]+$ ]]; then
    # Direct number target (1-10) — remap to monitor's range
    raw=$((target))
    if [ "$raw" -ge 1 ] && [ "$raw" -le 10 ]; then
        # Treat as a "slot" key (1=first, 10=last) on this monitor
        remapped=$((ws_offset + raw))
        target_workspace=$(cap_workspace "$remapped")
    else
        target_workspace=$(cap_workspace "$raw")
    fi
else
    # Fallback
    target_workspace="${target}"
fi

# Dispatch the command
hyprctl dispatch "${dispatcher}" "${target_workspace}"
