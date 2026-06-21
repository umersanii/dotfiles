#!/usr/bin/env bash
# battery_rgb.sh — Set keyboard RGB color based on battery level
#
# Colors:
#   >= 80%  → Green  (00FF00)
#   10–79%  → Yellow (FFFF00)
#   < 10%   → Red    (FF0000)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RGB_SCRIPT="$SCRIPT_DIR/legion_rgb.sh"

BATTERY_PATH="/sys/class/power_supply/BAT0"

get_battery_level() {
    cat "$BATTERY_PATH/capacity" 2>/dev/null || echo 50
}

main() {
    # Don't fight music mode — it owns the keyboard while active
    [[ -f "/tmp/music-keyboard-mode" ]] && exit 0

    local level
    level=$(get_battery_level)

    if (( level >= 80 )); then
        "$RGB_SCRIPT" color 00FF00
    elif (( level >= 10 )); then
        "$RGB_SCRIPT" color FFFF00
    else
        "$RGB_SCRIPT" color FF0000
    fi
}

main "$@"
