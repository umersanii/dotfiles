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
import threading
import time

FIFO_PATH = "/tmp/cava-dashboard.fifo"


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
                    socketio.emit(event_name, {"bars": bars})
        except FileNotFoundError:
            # cava hasn't created the fifo yet (not running / not started up)
            time.sleep(0.5)
        except OSError:
            time.sleep(0.5)


def start_visualizer_broadcast(socketio, fifo_path=FIFO_PATH, event_name="visualizer_frame"):
    """Spawn a background thread that reads cava's fifo and emits frames over socketio."""
    thread = threading.Thread(
        target=_read_loop, args=(socketio, fifo_path, event_name), daemon=True
    )
    thread.start()
    return thread
