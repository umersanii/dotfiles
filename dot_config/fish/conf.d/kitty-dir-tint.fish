# Tints the kitty tab bar (not the pane background — apps like claude code
# reset that via terminal-reset escape codes) when cwd is under a watched
# directory, so I can tell sessions apart at a glance.
function __kitty_dir_tint --on-variable PWD
    if test -z "$KITTY_WINDOW_ID"
        return
    end

    switch $PWD
        case "/home/sani/Work" "/home/sani/Work/*"
            kitty @ set-tab-color active_bg=#7a1010 inactive_bg=#3a0a0a active_fg=#ffffff inactive_fg=#dddddd >/dev/null 2>&1
        case "*"
            kitty @ set-tab-color active_bg=NONE inactive_bg=NONE active_fg=NONE inactive_fg=NONE >/dev/null 2>&1
    end
end

__kitty_dir_tint
