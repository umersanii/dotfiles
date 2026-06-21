#!/usr/bin/env python3
"""
keyboard-music-sync: Reads /tmp/cava-key-color (written by cava-colors.py)
and applies a 4-zone symmetric gradient to the Lenovo Legion keyboard via OpenRGB.
Left/Right edges are darker; Left-Center/Right-Center are brightest.
"""

import subprocess, colorsys, os, sys, time, signal

KEY_COLOR_FILE = "/tmp/cava-key-color"
DEFAULT_COLOR  = "888888"
DEVICE_IDX     = 0

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
    # Symmetric: inner zones brighter, outer zones dimmer
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

def reset(*_):
    apply_keyboard(DEFAULT_COLOR)
    sys.exit(0)

signal.signal(signal.SIGTERM, reset)
signal.signal(signal.SIGINT,  reset)

def main():
    last = None
    while True:
        color = read_key_color()
        if color != last:
            last = color
            apply_keyboard(color or DEFAULT_COLOR)
        time.sleep(2)

if __name__ == "__main__":
    main()
