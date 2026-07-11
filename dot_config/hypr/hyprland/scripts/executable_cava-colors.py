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
DEFAULT        = ["#ffffff", "#c2c2c2", "#aeaeae", "#9b9b9b", "#888888", "#747474", "#606060", "#4d4d4d"]
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


def get_track_url():
    return run(["playerctl", f"--player={PLAYERS}", "metadata", "xesam:url"])


_YT_ID_PATTERNS = [
    re.compile(r'(?:youtube\.com|music\.youtube\.com)/watch\?.*?v=([\w-]{11})'),
    re.compile(r'youtu\.be/([\w-]{11})'),
    re.compile(r'youtube\.com/(?:shorts|embed)/([\w-]{11})'),
    re.compile(r'ytimg\.com/vi(?:_webp)?/([\w-]{11})/'),
]

def extract_youtube_id(*urls):
    for url in urls:
        if not url:
            continue
        for pattern in _YT_ID_PATTERNS:
            m = pattern.search(url)
            if m:
                return m.group(1)
    return None


def fetch_youtube_thumbnail(video_id):
    """Download the best available ytimg thumbnail; returns path or None."""
    for quality in ("maxresdefault", "sddefault", "hqdefault"):
        try:
            url = f"https://i.ytimg.com/vi/{video_id}/{quality}.jpg"
            urllib.request.urlretrieve(url, ART_CACHE)
            # missing sizes come back as a tiny placeholder image
            if os.path.getsize(ART_CACHE) > 2000:
                return ART_CACHE
        except Exception:
            continue
    return None


def fetch_art(url):
    # YouTube thumbnail is the canonical art source across muser
    video_id = extract_youtube_id(get_track_url(), url)
    if video_id:
        art = fetch_youtube_thumbnail(video_id)
        if art:
            return art
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


def extract_colors(path, n=12):
    """Return list of (pixel_count, (h, s, v)) for the n dominant colors via ImageMagick."""
    try:
        raw = subprocess.check_output(
            ["magick", path, "-resize", "150x150", "-colors", str(n),
             "-format", "%c", "histogram:info:-"],
            stderr=subprocess.DEVNULL
        ).decode()
    except Exception:
        return []

    result = []
    for line in raw.splitlines():
        m = re.search(r"(\d+):.*?#([0-9A-Fa-f]{6})", line)
        if m:
            count = int(m.group(1))
            h6 = m.group(2)
            r, g, b = (int(h6[i:i+2], 16) / 255 for i in (0, 2, 4))
            result.append((count, colorsys.rgb_to_hsv(r, g, b)))
    return result


def pick_key(colors):
    """Pick the dominant vibrant color, weighting coverage (pixel count) as well as
    vibrance so a tiny saturated fleck can't outvote the art's actual color.
    Returns None for grayscale art so caller uses default."""
    if not colors:
        return None
    # Only consider colors with genuine saturation and brightness — filters out
    # JPEG artifacts, letterbox bars, and near-black backgrounds
    saturated = [(cnt, c) for cnt, c in colors if c[1] > 0.30 and c[2] > 0.20]
    if not saturated:
        return None     # grayscale/monochrome art → caller will use default gradient
    return max(saturated, key=lambda e: e[0] * e[1][1] * e[1][2])[1]


def build_gradient(h, s, v, steps=8):
    """Gradient from white (bottom, gradient_color_1) to the key color (top, last stop)."""
    out = []
    for i in range(steps):
        t  = i / (steps - 1)          # 0 = bottom (white) -> 1 = top (key color)
        si = s * t                    # saturation: 0 (white) -> s (full key color)
        vi = 1.0 - t * (1.0 - v)      # brightness: 1.0 (white) -> v (key color)
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
                        apply_gradient(gradient)
                        # Write the actual key color (top stop) for other processes
                        write_key_color(gradient[-1].lstrip("#"))
                    else:
                        apply_gradient(DEFAULT)
                        write_key_color(DEFAULT_KEY)
                else:
                    apply_gradient(DEFAULT)
                    write_key_color(DEFAULT_KEY)

        time.sleep(2)


if __name__ == "__main__":
    main()
