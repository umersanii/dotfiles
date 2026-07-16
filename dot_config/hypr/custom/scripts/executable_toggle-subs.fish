#!/usr/bin/fish
# Toggle live subtitle overlay window

if hyprctl clients -j | jq -e '.[] | select(.title == "whisper-subs")' > /dev/null 2>&1
    hyprctl dispatch closewindow title:whisper-subs
else
    kitty \
        --title whisper-subs \
        -o background=#0a0a0a \
        -o background_opacity=0.82 \
        -o font_size=17 \
        -o window_padding_width=12 \
        -o confirm_os_window_close=0 \
        -e fish -c subs &
end
