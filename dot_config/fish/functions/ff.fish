function ff
    clear
    # Play GIF in the background at top-left (Increased size)
    kitty +kitten icat --loop=0 --align=left --place 50x34@0x6 /home/sani/Downloads/touch.jpg
    printf '\033[H'  # reset cursor to top-left before fastfetch
    fastfetch --logo " " --logo-type data-raw --logo-width 50 --logo-height 30 --logo-padding-left 00
end
