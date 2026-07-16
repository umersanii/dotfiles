"""
Lyrics data feed for the music dashboard's lyrics card.

Ported from ~/.local/bin/sptlrx-scaled: the lrclib.net fetching, slowed-song
detection, and LRC timestamp-rescaling logic are unchanged (still pure
functions operating on strings/timestamps). What's dropped is everything
sptlrx-scaled did to render itself as a terminal UI (ANSI colors, cmatrix/nms
fallback animations) — the dashboard renders lyric lines and the matrix-mode
effect itself, client-side, from the {lines, active_line_index} this module
broadcasts over socketio.
"""
import re
import subprocess
import threading
import time
from pathlib import Path

import requests

PLAYERS = ["firefox", "edge", "chromium", "chrome"]
MUSIC_URL = "music.youtube.com"   # only respond to YouTube Music
SCALED_LYRICS_DIR = Path.home() / ".cache" / "sptlrx-scaled"

SLOWED_PATTERNS = [
    r'\((super\s*)?slowed\s*[\+&]?\s*reverb\)',
    r'\((super\s*)?slowed\)',
    r'\[(super\s*)?slowed\s*[\+&]?\s*reverb\]',
    r'\[(super\s*)?slowed\]',
    r'~\s*(super\s*)?slowed',
    r'-\s*(super\s*)?slowed',
    r'(super\s*)?slowed\s*(and|\+|&)?\s*reverb',
    r'(super\s*)?slowed\s*version',
    r'☆\s*deluxe',
    r'sped\s*down',
    r'pitched\s*down',
]

# Sped-up variants: searched with cleaned title and timestamps rescaled, but the
# slowed-specific duration window in lrclib search doesn't apply
SPED_PATTERNS = [
    r'(sped|speed)\s*up',
    r'nightcore',
    r'pitched\s*up',
]


# ── playerctl helpers ────────────────────────────────────────────────────────

def _run_playerctl(*args):
    try:
        cmd = ["playerctl", f"--player={','.join(PLAYERS)}"] + list(args)
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
    except subprocess.CalledProcessError:
        return None


def get_metadata():
    """Get current song metadata, or None if nothing (relevant) is playing."""
    title = _run_playerctl("metadata", "xesam:title")
    artist = _run_playerctl("metadata", "xesam:artist")
    length = _run_playerctl("metadata", "mpris:length")
    url = _run_playerctl("metadata", "xesam:url")

    if not title:
        return None

    # A plain YouTube tab exposes the same MPRIS player, so gate on the URL
    if url and MUSIC_URL not in url:
        return None

    return {
        "title": title,
        "artist": artist or "",
        "length_sec": int(length) / 1_000_000 if length else None,
    }


def get_position_ms():
    """Get current playback position in milliseconds, or None if not playing."""
    status = _run_playerctl("status")
    if status != "Playing":
        return None
    pos = _run_playerctl("position")
    if pos is None:
        return None
    try:
        return int(float(pos) * 1000)
    except ValueError:
        return None


# ── title parsing / slowed-song detection (ported verbatim) ─────────────────

def is_slowed_song(title):
    title_lower = title.lower()
    return any(re.search(p, title_lower) for p in SLOWED_PATTERNS)


def is_sped_song(title):
    title_lower = title.lower()
    return any(re.search(p, title_lower) for p in SPED_PATTERNS)


def parse_title(raw_title):
    """Parse 'Artist - Song' / 'Song - Artist' titles; caller tries both orderings."""
    title = raw_title
    fullwidth_to_ascii = str.maketrans(
        'ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ０１２３４５６７８９　',
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 '
    )
    title = title.translate(fullwidth_to_ascii)
    title = re.sub(r'\s*-\s*YouTube Music$', '', title)
    title = re.sub(r'\s*\([^)]*\)', '', title)
    title = re.sub(r'\s*\[[^\]]*\]', '', title)
    title = re.sub(r'\s*\{[^}]*\}', '', title)
    title = re.sub(r'\s*「[^」]*」', '', title)
    title = re.sub(r'\s*『[^』]*』', '', title)
    title = re.sub(r'\s*~\s*(super\s*)?slowed.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*-\s*(super\s*)?slowed.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*(super\s*)?slowed\s*(and|\+|&)?\s*reverb.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*(super\s*)?slowed\s*version.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*(sped|pitched)\s*down.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*[-~]?\s*(sped|speed|pitched)\s*up.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'\s*[-~]?\s*nightcore.*$', '', title, flags=re.IGNORECASE)
    title = re.sub(r'[^\x00-\x7FÀ-ɏ]+', '', title)
    title = re.sub(r'\s*[~\-|／/]\s*$', '', title)
    title = re.sub(r'\s+', ' ', title).strip()

    part1 = None
    part2 = title
    for sep in [' - ', ' － ', ' ~ ', ' | ', '- ', ' -', '－', ' / ', '／']:
        if sep in title:
            parts = title.split(sep, 1)
            if len(parts) == 2 and parts[0].strip() and parts[1].strip():
                part1 = parts[0].strip()
                part2 = parts[1].strip()
                break
    return part1, part2


# ── lrclib.net fetching (ported verbatim) ────────────────────────────────────

def fetch_lyrics_lrclib(song, artist=None, expected_duration=None):
    song_lower = song.lower().strip()
    artist_lower = artist.lower().strip() if artist else None

    if artist:
        try:
            resp = requests.get("https://lrclib.net/api/search",
                                 params={"track_name": song, "artist_name": artist},
                                 timeout=15)
            if resp.status_code == 200:
                for r in resp.json():
                    if not r.get("syncedLyrics"):
                        continue
                    track = r.get("trackName", "").lower().strip()
                    result_artist = r.get("artistName", "").lower().strip()
                    track_matches = (track == song_lower or
                                     track.replace(" ", "") == song_lower.replace(" ", ""))
                    artist_matches = (result_artist == artist_lower or
                                      result_artist.replace(" ", "") == artist_lower.replace(" ", "") or
                                      artist_lower in result_artist or
                                      result_artist in artist_lower)
                    if track_matches and artist_matches:
                        return {
                            "lyrics": r["syncedLyrics"],
                            "duration": r.get("duration"),
                            "title": r.get("trackName"),
                            "artist": r.get("artistName"),
                        }
        except requests.exceptions.Timeout:
            pass
        except Exception:
            pass
        return None

    try:
        resp = requests.get("https://lrclib.net/api/search", params={"track_name": song}, timeout=15)
        if resp.status_code != 200:
            return None
        results = resp.json()
    except Exception:
        return None

    candidates = []
    for r in results:
        if not r.get("syncedLyrics"):
            continue
        track = r.get("trackName", "").lower().strip()
        if track == song_lower or track.replace(" ", "") == song_lower.replace(" ", ""):
            candidates.append(r)

    if not candidates:
        return None

    by_artist = {}
    for c in candidates:
        by_artist.setdefault(c.get("artistName", "Unknown"), []).append(c)

    if len(by_artist) == 1:
        best = candidates[0]
        return {
            "lyrics": best["syncedLyrics"],
            "duration": best.get("duration"),
            "title": best.get("trackName"),
            "artist": best.get("artistName"),
        }

    if expected_duration:
        min_dur = expected_duration / 1.8
        max_dur = expected_duration / 1.05
        matches = [(c, abs(c.get("duration", 0) - expected_duration / 1.3))
                   for c in candidates
                   if c.get("duration") and min_dur <= c.get("duration") <= max_dur]
        if matches:
            matches.sort(key=lambda x: x[1])
            best = matches[0][0]
            return {
                "lyrics": best["syncedLyrics"],
                "duration": best.get("duration"),
                "title": best.get("trackName"),
                "artist": best.get("artistName"),
            }

    best = candidates[0]
    return {
        "lyrics": best["syncedLyrics"],
        "duration": best.get("duration"),
        "title": best.get("trackName"),
        "artist": best.get("artistName"),
    }


# ── LRC timestamp parsing / scaling (ported verbatim) ────────────────────────

def parse_lrc_timestamp(timestamp):
    match = re.match(r'\[(\d+):(\d+)\.(\d+)\]', timestamp)
    if not match:
        return None
    mins, secs, ms_str = int(match.group(1)), int(match.group(2)), match.group(3)
    if len(ms_str) == 2:
        ms = int(ms_str) * 10
    elif len(ms_str) == 3:
        ms = int(ms_str)
    else:
        ms = int(ms_str[:3])
    return mins * 60 * 1000 + secs * 1000 + ms


def format_lrc_timestamp(ms):
    total_secs = ms / 1000
    mins = int(total_secs // 60)
    secs = total_secs % 60
    return f"[{mins:02d}:{secs:05.2f}]"


def scale_lyrics(lyrics_text, scale_factor):
    scaled_lines = []
    for line in lyrics_text.split('\n'):
        match = re.match(r'(\[\d+:\d+\.\d+\])(.*)', line)
        if not match:
            scaled_lines.append(line)
            continue
        ms = parse_lrc_timestamp(match.group(1))
        if ms is None:
            scaled_lines.append(line)
            continue
        scaled_lines.append(f"{format_lrc_timestamp(int(ms * scale_factor))}{match.group(2)}")
    return '\n'.join(scaled_lines)


def parse_lrc_text(lyrics_text):
    """Parse LRC text into a list of (timestamp_ms, text) tuples."""
    lines = []
    for line in lyrics_text.split('\n'):
        line = line.strip()
        match = re.match(r'\[(\d+):(\d+)\.(\d+)\](.*)', line)
        if not match:
            continue
        mins, secs, ms_str, text = int(match.group(1)), int(match.group(2)), match.group(3), match.group(4)
        if len(ms_str) == 2:
            ms = int(ms_str) * 10
        elif len(ms_str) == 3:
            ms = int(ms_str)
        else:
            ms = int(ms_str[:3])
        lines.append((mins * 60 * 1000 + secs * 1000 + ms, text.strip()))
    return lines


def find_current_line(lyrics, position_ms):
    current_idx = -1
    for i, (timestamp, _) in enumerate(lyrics):
        if timestamp <= position_ms:
            current_idx = i
        else:
            break
    return current_idx


def get_safe_filename(title):
    safe_name = re.sub(r'[^\w\s-]', '', title)
    safe_name = re.sub(r'\s+', ' ', safe_name).strip()
    return safe_name[:100]


def save_scaled_lyrics(lyrics_text, raw_title):
    SCALED_LYRICS_DIR.mkdir(parents=True, exist_ok=True)
    filepath = SCALED_LYRICS_DIR / f"{get_safe_filename(raw_title)}.lrc"
    filepath.write_text(lyrics_text)
    return filepath


def clear_cache():
    if SCALED_LYRICS_DIR.exists():
        for f in SCALED_LYRICS_DIR.glob("*.lrc"):
            f.unlink()


def _search_attempts(raw_title, metadata_artist, is_slowed):
    part1, part2 = parse_title(raw_title)
    attempts = []
    if is_slowed:
        if part1:
            attempts += [(part1, part2), (part2, part1)]
        if metadata_artist:
            attempts += [(part1, metadata_artist), (part2, metadata_artist)] if part1 else [(part2, metadata_artist)]
        if part1:
            attempts.append((part1, None))
        attempts.append((part2, None))
    else:
        if metadata_artist:
            attempts += [(part1, metadata_artist), (part2, metadata_artist)] if part1 else [(part2, metadata_artist)]
        if part1:
            attempts += [(part1, part2), (part2, part1)]
        if part1:
            attempts.append((part1, None))
        attempts.append((part2, None))

    seen = set()
    unique = []
    for a in attempts:
        if a not in seen:
            seen.add(a)
            unique.append(a)
    return unique


def fetch_lines_for(raw_title, metadata_artist, duration_sec):
    """Fetch (and speed-scale) lyrics for a track. Returns a list of (ms, text), or []."""
    is_slowed = is_slowed_song(raw_title)
    is_scaled = is_slowed or is_sped_song(raw_title)
    lyrics_data = None
    for song, artist in _search_attempts(raw_title, metadata_artist, is_scaled):
        lyrics_data = fetch_lyrics_lrclib(song, artist, expected_duration=duration_sec if is_slowed else None)
        if lyrics_data:
            break

    if not lyrics_data:
        return []

    lyrics_text = lyrics_data['lyrics']
    original_duration = lyrics_data.get('duration')
    if is_scaled and original_duration and duration_sec:
        ratio = duration_sec / original_duration
        # Rescale timestamps for slowed (ratio > 1) and sped-up (ratio < 1) edits
        if 0.4 <= ratio <= 2.5:
            lyrics_text = scale_lyrics(lyrics_text, ratio)

    clear_cache()
    save_scaled_lyrics(lyrics_text, raw_title)
    return parse_lrc_text(lyrics_text)


# ── live service: polls playback, pushes {lines, active_line_index} ─────────

class LyricsService:
    def __init__(self, socketio, event_name="lyrics_update"):
        self.socketio = socketio
        self.event_name = event_name
        self._lines = []
        self._last_idx = -2
        self._last_title = None
        self._retries_left = 0
        self._next_retry_at = 0.0
        self._fetching = False

    def start(self):
        threading.Thread(target=self._loop, daemon=True).start()
        return self

    def emit_state(self):
        """Re-send the current state, e.g. to a client that just (re)connected."""
        self._emit()

    def _emit(self):
        self.socketio.emit(self.event_name, {
            "lines": [text for _, text in self._lines],
            "times": [ms for ms, _ in self._lines],
            "active_line_index": self._last_idx,
            "fetching": self._fetching,
            "no_lyrics": not self._lines and not self._fetching,
        })

    def _loop(self):
        while True:
            metadata = get_metadata()
            if not metadata or metadata['title'].lower() in ("youtube music", "youtube", ""):
                if self._last_title is not None:
                    self._lines = []
                    self._last_idx = -1
                    self._last_title = None
                    self._emit()
                time.sleep(1)
                continue

            title = metadata['title']
            if title != self._last_title:
                self._last_title = title
                self._last_idx = -1
                self._lines = []
                self._fetching = True
                self._emit()   # client shows the fetching spinner
                self._lines = fetch_lines_for(title, metadata.get('artist') or None, metadata.get('length_sec'))
                self._fetching = False
                # A miss may be a transient network/lrclib failure — retry a few times
                self._retries_left = 3 if not self._lines else 0
                self._next_retry_at = time.time() + 10
                self._emit()
            elif not self._lines and self._retries_left > 0 and time.time() >= self._next_retry_at:
                self._retries_left -= 1
                self._next_retry_at = time.time() + 10
                self._fetching = True
                self._emit()
                self._lines = fetch_lines_for(title, metadata.get('artist') or None, metadata.get('length_sec'))
                self._fetching = False
                if self._lines:
                    self._last_idx = -1
                self._emit()

            if self._lines:
                position = get_position_ms()
                if position is not None:
                    idx = find_current_line(self._lines, position)
                    if idx != self._last_idx:
                        self._last_idx = idx
                        self._emit()

            time.sleep(0.15)


def start_lyrics_service(socketio, event_name="lyrics_update"):
    return LyricsService(socketio, event_name).start()
