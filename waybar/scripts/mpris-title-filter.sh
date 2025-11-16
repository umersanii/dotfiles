#!/usr/bin/env bash
# Disable globbing to avoid shells trying to expand bracketed tokens
set -f
# Log any stderr from playerctl or other commands for debugging
exec 2>>/tmp/mpris-title-filter-stderr.log
# Outputs the currently playing track title, removing web-player suffixes like " - Youtube Music".
# Relies on playerctl being installed and accessible.

# Try to get the title from any player (prefer active). Fall back to first available.
title="$(playerctl metadata --format '{{title}}' 2>/dev/null || true)"

# Determine player id/name to pick an icon and check playing status
player_id="$(playerctl -l 2>/dev/null | head -n1 || true)"
player_identity=""
if [ -n "$player_id" ]; then
  # Try to get a printable identity string
  player_identity="$(playerctl --player="$player_id" metadata --format '{{mpris:identity}}' 2>/dev/null || true)"
fi

# Playback status (Playing/Paused/Stopped) from any active player
status="$(playerctl status 2>/dev/null || true)"

# If paused or stopped, use the paused status icon; otherwise pick a player icon
status_lc="$(echo "$status" | tr '[:upper:]' '[:lower:]')"
if echo "$status_lc" | grep -qi "paused\|stopped"; then
  icon="󰏤"
else
  # Simple icon mapping based on player identity (case-insensitive)
  icon="󰐊"
  pi_lc="$(echo "$player_identity" | tr '[:upper:]' '[:lower:]')"
  if echo "$pi_lc" | grep -q "spotify"; then
    icon="󰓞"
  elif echo "$pi_lc" | grep -q "vlc"; then
    icon="󰕾"
  elif echo "$pi_lc" | grep -q "mpv"; then
    icon="󰎈"
  elif echo "$pi_lc" | grep -q "cmus"; then
    icon="󰮝"
  fi
fi

# If empty, try listing players and getting metadata from the first one
if [ -z "$title" ]; then
  first_player=$(playerctl -l 2>/dev/null | head -n1)
  if [ -n "$first_player" ]; then
    title="$(playerctl --player="$first_player" metadata --format '{{title}}' 2>/dev/null || true)"
  fi
fi

# Normalize and strip common Youtube Music variants (case-insensitive)
# Also strip trailing separators like " - ", " — ", or ": " followed by the site name
# Remove common Youtube Music variants (case-insensitive) after a separator
cleaned="$(echo "$title" | sed -E 's/\s*[-—:|]\s*([Yy]ou[Tt]ube[[:space:]]*[Mm]usic|youtube music|youtube)$//')"

# Remove anything after opening parenthesis (including the parenthesis itself)
cleaned="$(echo "$cleaned" | sed -E 's/\s*\(.*$//')"

# Trim whitespace
cleaned="$(echo "$cleaned" | sed -E 's/^\s+|\s+$//g')"

CACHE_FILE="/tmp/waybar_mpris_last"

# Print cleaned title (or fallback to cached last non-empty output)
if [ -n "$cleaned" ]; then
  # Prepend icon and a space
  output="${icon} ${cleaned}"
  # Save to cache atomically
  printf "%s" "$output" > "$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE" 2>/dev/null || true
  printf "%s" "$output"
else
  # Fallback: if cache exists, print last known value; otherwise print empty
  if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
  else
    printf ""
  fi
fi
