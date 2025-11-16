#!/usr/bin/env bash
set -euo pipefail

# Exit if waybar is not installed
command -v waybar >/dev/null 2>&1 || exit 0

# If waybar is already running, do nothing
if pgrep -x "waybar" >/dev/null 2>&1; then
    exit 0
fi

# Start waybar detached so it survives the parent shell
if command -v setsid >/dev/null 2>&1; then
    setsid waybar >/dev/null 2>&1 &
else
    nohup waybar >/dev/null 2>&1 &
fi

exit 0