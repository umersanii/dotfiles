---
paths:
  - "hypr/hyprland/scripts/cava-colors.py"
  - "hypr/hyprland/scripts/lyrics_service.py"
  - "hypr/hyprland/scripts/music-dashboard.sh"
---
# muser dashboard scripts
- These scripts are the dashboard half of muser; the player is `~/c0d3/muser` (its `CLAUDE.local.md` has the full notes, `ROADMAP.md` the plans)
- YouTube Music only: `MUSIC_URL` here must stay in sync with `url_filter` in `~/c0d3/muser/config.json`
- `cava-colors.py` writes the accent to `/tmp/cava-key-color`, which muser's `/api/status` reads
- MPRIS updates title before track URL on song change — key on video ID, not title
