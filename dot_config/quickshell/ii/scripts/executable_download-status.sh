#!/bin/bash
# Download progress via aria2 JSON-RPC (primary) or Chromium History DB (fallback).

shopt -s nullglob

# ---- aria2 RPC: real progress for any download aria2 handles ----
aria2_check() {
    local response
    response=$(curl -s --connect-timeout 1 \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"aria2.tellActive","id":"qs","params":[["gid","totalLength","completedLength","files"]]}' \
        'http://localhost:6800/jsonrpc' 2>/dev/null) || return 1
    [ -z "$response" ] && return 1

    echo "$response" | python3 - << 'EOF'
import sys, json, os
try:
    data = json.load(sys.stdin)
    results = data.get('result', [])
    if not results:
        sys.exit(1)
    dl = results[0]
    total = int(dl.get('totalLength', 0))
    completed = int(dl.get('completedLength', 0))
    if total <= 0:
        sys.exit(1)
    path = (dl.get('files') or [{}])[0].get('path', '')
    name = os.path.basename(path)
    print(f'{{"active":true,"name":"{name}","progress":{completed/total:.4f},"downloaded":{completed},"total":{total}}}')
except:
    sys.exit(1)
EOF
}

result=$(aria2_check) && echo "$result" && exit 0

# ---- Chromium-based browsers: SQLite History DB (fallback) ----
query_chromium_db() {
    local db="$1"
    [ -f "$db" ] || return 1
    command -v sqlite3 >/dev/null || return 1
    local tmp
    tmp=$(mktemp /tmp/dl_hist_XXXXXX)
    cp "$db" "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
    cp "${db}-wal" "${tmp}-wal" 2>/dev/null
    cp "${db}-shm" "${tmp}-shm" 2>/dev/null
    local row
    row=$(sqlite3 "$tmp" \
        "SELECT target_path, received_bytes, total_bytes
         FROM downloads
         WHERE total_bytes > 0 AND received_bytes > 0 AND received_bytes < total_bytes
         ORDER BY start_time DESC LIMIT 1;" 2>/dev/null)
    rm -f "$tmp" "${tmp}-wal" "${tmp}-shm"
    [ -z "$row" ] && return 1
    local path received total name progress
    path=$(cut -d'|' -f1 <<< "$row")
    received=$(cut -d'|' -f2 <<< "$row")
    total=$(cut -d'|' -f3 <<< "$row")
    [ "$total" -le 0 ] && return 1
    name=$(basename "$path")
    progress=$(awk "BEGIN {printf \"%.4f\", $received/$total}")
    printf '{"active":true,"name":"%s","progress":%s,"downloaded":%d,"total":%d}\n' \
        "$name" "$progress" "$received" "$total"
}

for db in \
    "$HOME/.config/microsoft-edge/Default/History" \
    "$HOME/.config/microsoft-edge/Profile 1/History" \
    "$HOME/.config/google-chrome/Default/History" \
    "$HOME/.config/chromium/Default/History" \
    "$HOME/.config/thorium/Default/History" \
    "$HOME/.config/BraveSoftware/Brave-Browser/Default/History"; do
    result=$(query_chromium_db "$db") && echo "$result" && exit 0
done

echo '{"active":false}'
