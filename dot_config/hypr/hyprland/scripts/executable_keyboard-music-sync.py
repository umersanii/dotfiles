#!/usr/bin/env python3
"""
keyboard-music-sync: Reads /tmp/cava-key-color (written by cava-colors.py)
and applies a 4-zone symmetric gradient to the Lenovo Legion keyboard via OpenRGB.
Left/Right edges are darker; Left-Center/Right-Center are brightest.

On startup:  saves legion_rgb.sh state, writes /tmp/music-keyboard-mode lock.
On exit:     restores pre-music keyboard state, removes lock.
"""

import subprocess, colorsys, os, sys, time, signal

KEY_COLOR_FILE   = "/tmp/cava-key-color"
LOCK_FILE        = "/tmp/music-keyboard-mode"
LEGION_RGB       = os.path.expanduser("~/.config/hypr/hyprland/scripts/legion_rgb.sh")
STATE_FILE       = os.path.expanduser("~/.local/state/legion-rgb/state")
DEFAULT_COLOR    = "888888"
DEVICE_IDX       = 0

# Must mirror the arrays in legion_rgb.sh exactly
PALETTE = [
    "FFFFFF", "FF0000", "00FF00", "0000FF", "FFFF00",
    "00FFFF", "FF00FF", "FF5500", "55FF00", "00FF55",
    "0055FF", "5500FF", "FF0055",
]
EFFECTS = ["Direct", "Breathing", "Rainbow Wave", "Spectrum Cycle"]


# ── legion_rgb state ──────────────────────────────────────────────────────────

def read_legion_state():
    """Return (color_idx, effect_idx) from legion-rgb's state file."""
    try:
        vals = {}
        for line in open(STATE_FILE):
            k, _, v = line.strip().partition("=")
            vals[k.strip()] = v.strip()
        ci = int(vals.get("COLOR_INDEX", 0)) % len(PALETTE)
        ei = int(vals.get("EFFECT_INDEX", 0)) % len(EFFECTS)
        return ci, ei
    except Exception:
        return 0, 0     # fallback: White / Direct


def restore_legion_state(color_idx, effect_idx):
    """Hand control back to legion_rgb.sh using the saved indices."""
    effect = EFFECTS[effect_idx]
    if effect == "Direct":
        subprocess.run([LEGION_RGB, "color", PALETTE[color_idx]],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        cmd_map = {
            "Breathing":      ["white-breathing"],
            "Rainbow Wave":   ["effect", "Rainbow Wave"],
            "Spectrum Cycle": ["effect", "Spectrum Cycle"],
        }
        subprocess.run([LEGION_RGB] + cmd_map.get(effect, ["white-breathing"]),
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# ── lock ──────────────────────────────────────────────────────────────────────

def acquire_lock():
    with open(LOCK_FILE, "w") as f:
        f.write(str(os.getpid()))


def release_lock():
    try:
        os.unlink(LOCK_FILE)
    except Exception:
        pass


# ── keyboard color ────────────────────────────────────────────────────────────

def hex_to_hsv(hex6):
    r = int(hex6[0:2], 16) / 255
    g = int(hex6[2:4], 16) / 255
    b = int(hex6[4:6], 16) / 255
    return colorsys.rgb_to_hsv(r, g, b)


def hsv_to_hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h, min(s, 1.0), min(v, 1.0))
    return "{:02x}{:02x}{:02x}".format(int(r * 255), int(g * 255), int(b * 255))


def build_zones(hex6):
    """Return 4 hex strings (no #) for: Left, Left-Center, Right-Center, Right."""
    h, s, v = hex_to_hsv(hex6)
    if s < 0.10:                        # grayscale art → neutral
        return [DEFAULT_COLOR] * 4
    return [
        hsv_to_hex(h, s * 0.65, v * 0.45),   # Left side   — dim
        hsv_to_hex(h, s * 0.90, v * 0.85),   # Left center — bright
        hsv_to_hex(h, s * 0.90, v * 0.85),   # Right center — bright
        hsv_to_hex(h, s * 0.65, v * 0.45),   # Right side  — dim
    ]


def apply_keyboard(hex6):
    zones = build_zones(hex6)
    subprocess.run(
        ["openrgb", "-d", str(DEVICE_IDX), "-m", "Direct", "-c", ",".join(zones)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )


def read_key_color():
    try:
        val = open(KEY_COLOR_FILE).read().strip()
        if len(val) == 6 and all(c in "0123456789abcdefABCDEF" for c in val):
            return val
    except Exception:
        pass
    return None


# ── lifecycle ─────────────────────────────────────────────────────────────────

_saved_state = (0, 0)


def shutdown(*_):
    release_lock()
    restore_legion_state(*_saved_state)
    sys.exit(0)


signal.signal(signal.SIGTERM, shutdown)
signal.signal(signal.SIGINT,  shutdown)


def main():
    global _saved_state
    _saved_state = read_legion_state()
    acquire_lock()

    last = None
    while True:
        color = read_key_color()
        if color != last:
            last = color
            apply_keyboard(color or DEFAULT_COLOR)
        time.sleep(2)


if __name__ == "__main__":
    main()
