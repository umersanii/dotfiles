#!/usr/bin/env python3
"""
cava-colors: Watch playerctl for track changes, extract the dominant color
from album art, and live-update cava's gradient. Resets to default on exit.
"""

import subprocess, re, colorsys, os, sys, time, signal, shutil, urllib.request

CAVA_CONFIG    = os.path.expanduser("~/.config/cava/config")
PLAYERS        = "firefox,edge,chromium,chrome"
ART_CACHE      = os.path.expanduser("~/.cache/cava-colors/art")
KEY_COLOR_FILE = "/tmp/cava-key-color"
DEFAULT        = ["#3a3a3a", "#4d4d4d", "#606060", "#747474", "#888888", "#9b9b9b", "#aeaeae", "#c2c2c2", "#ffffff"]
DEFAULT_KEY    = "888888"

os.makedirs(os.path.dirname(ART_CACHE), exist_ok=True)


# ── helpers ──────────────────────────────────────────────────────────────────

def run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        return None


def get_title():
    return run(["playerctl", f"--player={PLAYERS}", "metadata", "xesam:title"])


def get_art_url():
    return run(["playerctl", f"--player={PLAYERS}", "metadata", "mpris:artUrl"])


def fetch_art(url):
    if not url:
        return None
    try:
        if url.startswith("file://"):
            src = url[7:]
            if os.path.exists(src):
                shutil.copy2(src, ART_CACHE)
                return ART_CACHE
        else:
            urllib.request.urlretrieve(url, ART_CACHE)
            return ART_CACHE
    except Exception:
        return None


def extract_colors(path, n=8):
    """Return list of (h, s, v) for the n dominant colors via ImageMagick."""
    try:
        raw = subprocess.check_output(
            ["magick", path, "-resize", "150x150", "-colors", str(n),
             "-unique-colors", "txt:-"],
            stderr=subprocess.DEVNULL
        ).decode()
    except Exception:
        return []

    result = []
    for line in raw.splitlines()[1:]:          # skip ImageMagick header
        m = re.search(r"#([0-9A-Fa-f]{6})", line)
        if m:
            h6 = m.group(1)
            r, g, b = (int(h6[i:i+2], 16) / 255 for i in (0, 2, 4))
            result.append(colorsys.rgb_to_hsv(r, g, b))
    return result


def pick_key(colors):
    """Pick most vibrant color. Returns None for grayscale art so caller uses default."""
    if not colors:
        return None
    # Only consider colors with genuine saturation — filters out JPEG artifacts
    saturated = [c for c in colors if c[1] > 0.30]
    if not saturated:
        return None     # grayscale/monochrome art → caller will use default gradient
    return max(saturated, key=lambda c: c[1] * c[2])


def build_gradient(h, s, v, steps=8):
    """Smooth dark-to-bright gradient preserving the key hue."""
    out = []
    for i in range(steps):
        t  = i / (steps - 1)
        vi = 0.48 + t * 0.30          # brightness 0.48 → 0.78  (narrow range = subtle)
        si = s * (0.75 + t * 0.20)   # saturation 75% → 95% of key  (stays consistent)
        r, g, b = colorsys.hsv_to_rgb(h, min(si, 1.0), min(vi, 1.0))
        out.append("#{:02x}{:02x}{:02x}".format(int(r*255), int(g*255), int(b*255)))
    return out


def apply_gradient(colors):
    with open(CAVA_CONFIG) as f:
        cfg = f.read()
    # Remove any existing gradient_color lines
    cfg = re.sub(r"gradient_color_\d+ = '#[0-9a-fA-F]{6}'\n", "", cfg)
    # Insert new ones before [smoothing]
    new_lines = "\n".join(f"gradient_color_{i} = '{c}'" for i, c in enumerate(colors, 1))
    cfg = cfg.replace("[smoothing]", new_lines + "\n\n[smoothing]")
    with open(CAVA_CONFIG, "w") as f:
        f.write(cfg)


# ── lifecycle ─────────────────────────────────────────────────────────────────

def write_key_color(hex6):
    """Write the key color hex (no #) to shared file for other processes."""
    try:
        with open(KEY_COLOR_FILE, "w") as f:
            f.write(hex6)
    except Exception:
        pass


def cleanup(*_):
    apply_gradient(DEFAULT)
    write_key_color(DEFAULT_KEY)
    sys.exit(0)

signal.signal(signal.SIGTERM, cleanup)
signal.signal(signal.SIGINT,  cleanup)


def main():
    last_title = object()   # sentinel so first iteration always fires

    while True:
        title = get_title()

        if title != last_title:
            last_title = title

            if not title:
                apply_gradient(DEFAULT)
                write_key_color(DEFAULT_KEY)
            else:
                art = fetch_art(get_art_url())
                if art:
                    key = pick_key(extract_colors(art))
                    if key:
                        h, s, v = key
                        gradient = build_gradient(h, s, v)
                        gradient.append("#ffffff")
                        apply_gradient(gradient)
                        # Write middle stop as key color for other processes
                        mid = gradient[len(gradient) // 2].lstrip("#")
                        write_key_color(mid)
                    else:
                        apply_gradient(DEFAULT)
                        write_key_color(DEFAULT_KEY)
                else:
                    apply_gradient(DEFAULT)
                    write_key_color(DEFAULT_KEY)

        time.sleep(2)


if __name__ == "__main__":
    main()
