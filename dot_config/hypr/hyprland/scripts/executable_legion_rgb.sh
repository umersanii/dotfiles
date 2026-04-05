#!/usr/bin/env bash
# test comment for chezmoi auto-sync

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/legion-rgb"
STATE_FILE="$STATE_DIR/state"

PALETTE=(
    FFFFFF # White
    FF0000 # Red
    00FF00 # Green
    0000FF # Blue
    FFFF00 # Yellow
    00FFFF # Cyan
    FF00FF # Magenta
    FF5500 # Orange
    55FF00 # Lime
    00FF55 # Spring Green
    0055FF # Azure
    5500FF # Violet
    FF0055 # Rose
)

EFFECTS=(
    "Direct"
    "Breathing"
    "Rainbow Wave"
    "Spectrum Cycle"
)


DEVICE_INDEX=""
BREATHING_SPEED=15

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Legion Keyboard RGB" "$1"
    fi
}

require_openrgb() {
    if ! command -v openrgb >/dev/null 2>&1; then
        notify "openrgb is not installed. Install it first (e.g. yay -S openrgb)."
        echo "Error: openrgb command not found" >&2
        exit 1
    fi
}

resolve_device_index() {
    if [[ -n "$DEVICE_INDEX" ]]; then
        return
    fi

    local idx
    idx="$(openrgb --list-devices 2>/dev/null | awk '
        /^[0-9]+:/ {
            current=$1
            sub(":", "", current)
        }
        /Type:[[:space:]]+Laptop/ {
            print current
            exit
        }
    ')"

    DEVICE_INDEX="$idx"
}

openrgb_apply() {
    if [[ -n "$DEVICE_INDEX" ]]; then
        openrgb -d "$DEVICE_INDEX" "$@" >/dev/null
    else
        openrgb "$@" >/dev/null
    fi
}

ensure_state_file() {
    mkdir -p "$STATE_DIR"

    if [[ ! -f "$STATE_FILE" ]]; then
        cat > "$STATE_FILE" <<EOF
COLOR_INDEX=0
EFFECT_INDEX=0
EOF
    fi

    # shellcheck source=/dev/null
    source "$STATE_FILE"
    COLOR_INDEX="${COLOR_INDEX:-0}"
    EFFECT_INDEX="${EFFECT_INDEX:-0}"
}

save_state() {
    cat > "$STATE_FILE" <<EOF
COLOR_INDEX=$COLOR_INDEX
EFFECT_INDEX=$EFFECT_INDEX
EOF
}

set_static_color() {
    local hex="$1"
    require_openrgb
    resolve_device_index
    openrgb_apply --mode "Direct" --color "$hex"
    notify "Color set to #$hex"
}

set_effect() {
    local mode="$1"
    require_openrgb
    resolve_device_index

    if [[ "$mode" == "Breathing" ]]; then
        openrgb_apply --mode "$mode" --color "FFFFFF" --speed "$BREATHING_SPEED"
    else
        openrgb_apply --mode "$mode"
    fi

    notify "Effect set to $mode"
}

cycle_color() {
    ensure_state_file
    COLOR_INDEX=$(( (COLOR_INDEX + 1) % ${#PALETTE[@]} ))
    save_state
    set_static_color "${PALETTE[$COLOR_INDEX]}"
}

cycle_effect() {
    ensure_state_file
    EFFECT_INDEX=$(( (EFFECT_INDEX + 1) % ${#EFFECTS[@]} ))
    save_state
    set_effect "${EFFECTS[$EFFECT_INDEX]}"
}

usage() {
    cat <<'EOF'
Usage:
  legion_rgb.sh cycle-color
  legion_rgb.sh cycle-effect
  legion_rgb.sh color <HEX>     # Example: legion_rgb.sh color FF00AA
    legion_rgb.sh effect <MODE>   # Direct | Breathing | Rainbow Wave | Spectrum Cycle
    legion_rgb.sh white-breathing # Sets Breathing mode with white color
    legion_rgb.sh off             # Sets Direct mode with black color

Requires: openrgb
EOF
}

main() {
    local cmd="${1:-}"

    case "$cmd" in
        cycle-color)
            cycle_color
            ;;
        cycle-effect)
            cycle_effect
            ;;
        white-breathing)
            ensure_state_file
            # Find Breathing index
            for i in "${!EFFECTS[@]}"; do
                if [[ "${EFFECTS[$i]}" == "Breathing" ]]; then
                    EFFECT_INDEX=$i
                    break
                fi
            done
            save_state
            set_effect "Breathing"
            ;;
        color)
            local hex="${2:-}"
            if [[ -z "$hex" || ! "$hex" =~ ^[0-9A-Fa-f]{6}$ ]]; then
                echo "Error: color must be a 6-digit hex value (e.g. FF00AA)" >&2
                exit 1
            fi
            set_static_color "${hex^^}"
            ;;
        effect)
            local mode="${2:-}"
            if [[ -z "$mode" ]]; then
                echo "Error: missing effect mode" >&2
                exit 1
            fi
            case "${mode,,}" in
                direct)
                    set_effect "Direct"
                    ;;
                breathing)
                    set_effect "Breathing"
                    ;;
                rainbow-wave|rainbow_wave|rainbowwave)
                    set_effect "Rainbow Wave"
                    ;;
                spectrum-cycle|spectrum_cycle|spectrumcycle)
                    set_effect "Spectrum Cycle"
                    ;;
                *)
                    set_effect "$mode"
                    ;;
            esac
            ;;
        off)
            require_openrgb
            resolve_device_index
            openrgb_apply --mode "Direct" --color "000000"
            notify "Keyboard backlight turned off"
            ;;
        -h|--help|help|"")
            usage
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
