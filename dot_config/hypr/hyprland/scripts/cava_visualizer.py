"""
Reads cava's raw/ascii fifo output and broadcasts bar-height frames over a
Flask-SocketIO connection, for the music dashboard's visualizer card.

cava must be configured (see ~/.config/cava/config) with:
    [output]
    method = raw
    raw_target = /tmp/cava-dashboard.fifo
    data_format = ascii
    ascii_max_range = 100
so each line on the fifo is N semicolon-separated integers (0-100), one per bar.
"""
import subprocess
import threading
import time

FIFO_PATH = "/tmp/cava-dashboard.fifo"

# cava reads raw system audio, so it reacts to whatever's making sound
# (Spotify, a game, a video call...). Gate the broadcast on YouTube Music
# actually being the active MPRIS player, same rule as cava-colors.py /
# lyrics_service.py, so the dashboard bars only move for YouTube Music.
PLAYERS = "firefox,edge,chromium,chrome"
MUSIC_URL = "music.youtube.com"

_yt_music_active = False


def _run(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        return None


def _watch_active_player(poll_interval=1.0):
    global _yt_music_active
    while True:
        status = _run(["playerctl", f"--player={PLAYERS}", "status"])
        track_url = _run(["playerctl", f"--player={PLAYERS}", "metadata", "xesam:url"])
        _yt_music_active = bool(
            status == "Playing" and track_url and MUSIC_URL in track_url
        )
        time.sleep(poll_interval)


def _read_loop(socketio, fifo_path, event_name):
    while True:
        try:
            with open(fifo_path, "r") as fifo:
                for line in fifo:
                    line = line.strip().rstrip(";")
                    if not line:
                        continue
                    try:
                        bars = [int(v) for v in line.split(";") if v]
                    except ValueError:
                        continue
                    if not _yt_music_active:
                        bars = [0] * len(bars)
                    socketio.emit(event_name, {"bars": bars})
        except FileNotFoundError:
            # cava hasn't created the fifo yet (not running / not started up)
            time.sleep(0.5)
        except OSError:
            time.sleep(0.5)


def start_visualizer_broadcast(socketio, fifo_path=FIFO_PATH, event_name="visualizer_frame"):
    """Spawn background threads that watch for an active YouTube Music player
    and read cava's fifo, emitting bar frames over socketio only while it's
    playing (zeroed frames otherwise, so bars go idle for any other audio)."""
    threading.Thread(target=_watch_active_player, daemon=True).start()
    thread = threading.Thread(
        target=_read_loop, args=(socketio, fifo_path, event_name), daemon=True
    )
    thread.start()
    return thread
