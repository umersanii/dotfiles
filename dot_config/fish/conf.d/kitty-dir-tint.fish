# Tints the kitty window background when cwd is under a watched directory,
# so I can tell sessions apart at a glance (e.g. multiple claude sessions).
function __kitty_dir_tint --on-variable PWD
    if test -z "$KITTY_WINDOW_ID"
        return
    end

    switch $PWD
        case "/home/sani/Work" "/home/sani/Work/*"
            kitty @ set-colors background=#200a0a >/dev/null 2>&1
        case "*"
            kitty @ set-colors background=#000000 >/dev/null 2>&1
    end
end

__kitty_dir_tint
