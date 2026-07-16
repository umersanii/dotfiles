#!/usr/bin/env python3
"""
Real-time subtitle streamer using Vosk.
Two-line display:
  line1 = previous completed utterance (stable)
  line2 = current partial (grows word by word)
When utterance completes: line1 ← final, line2 resets for next utterance.
"""
import json, os, subprocess, time
os.environ["VOSK_LOG_LEVEL"] = "-1"
from vosk import Model, KaldiRecognizer

MONITOR     = "easyeffects_sink.monitor"
MODEL_DIR   = "/home/sani/.local/share/vosk/vosk-model-small-en-us-0.15"
RATE        = 16000
OUT         = "/tmp/subs_current.txt"
CLEAR_AFTER = 5.0

model = Model(MODEL_DIR)
rec   = KaldiRecognizer(model, RATE)

proc = subprocess.Popen([
    "ffmpeg", "-f", "pulse", "-i", MONITOR,
    "-ac", "1", "-ar", str(RATE), "-f", "s16le", "-"
], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

chunk = RATE // 10 * 2  # 100ms of s16le mono

def write(content: str):
    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        f.write(content)
    os.replace(tmp, OUT)

line1 = ""   # previous utterance — stable, shown on top
line2 = ""   # current partial   — grows word by word, shown below
last_write  = 0.0
last_display = ""

while True:
    data = proc.stdout.read(chunk)
    if not data:
        break

    if rec.AcceptWaveform(data):
        final = json.loads(rec.Result()).get("text", "").strip()
        if final:
            line1 = final  # shift: completed utterance → top line
            line2 = ""     # bottom line starts fresh for next utterance
    else:
        line2 = json.loads(rec.PartialResult()).get("partial", "").strip()

    now = time.monotonic()

    parts   = [l for l in [line1, line2] if l]
    display = "\n".join(parts)

    if display:
        last_write = now
        if display != last_display:
            last_display = display
            write(display)
    elif last_write and (now - last_write) > CLEAR_AFTER:
        last_write = 0.0
        last_display = ""
        line1 = ""
        line2 = ""
        write("")
