# Subtly tints the kitty pane background when cwd is under a watched
# directory, so I can tell sessions apart at a glance. Note: apps that do a
# terminal reset on startup (e.g. claude code) will clear this back to the
# configured default background until they exit.
function __kitty_dir_tint --on-variable PWD
    if test -z "$KITTY_WINDOW_ID"
        return
    end

    switch $PWD
        case "/home/sani/Work/edgevision_mobile" "/home/sani/Work/edgevision_mobile/*"
            kitty @ set-colors background=#08100d >/dev/null 2>&1
        case "/home/sani/Work" "/home/sani/Work/*"
            kitty @ set-colors background=#0d0808 >/dev/null 2>&1
        case "*"
            kitty @ set-colors background=#000000 >/dev/null 2>&1
    end
end

__kitty_dir_tint
