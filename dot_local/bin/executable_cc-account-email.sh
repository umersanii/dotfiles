#!/usr/bin/env bash
# Prints the email of the Claude account Claude Code is logged in as.
#
# Used as a ccstatusline custom-command widget. ~/.claude.json is ~300KB and
# rewritten constantly, so a single grep (~1ms) beats a full JSON parse.
# The value is also mirrored to ~/.claude/current_account.txt (only when it
# changes) so the quickshell Claude popup can watch a tiny file instead of
# re-parsing ~/.claude.json on every write.
#
# Empty output makes ccstatusline hide the widget entirely.
cat >/dev/null  # drain the status payload ccstatusline pipes in

email=$(grep -m1 -o '"emailAddress": *"[^"]*"' ~/.claude.json 2>/dev/null)
email=${email%\"}
email=${email##*\"}

out=~/.claude/current_account.txt
if [ "$(cat "$out" 2>/dev/null)" != "$email" ]; then
  printf '%s' "$email" > "$out"
fi

printf '%s' "$email"
