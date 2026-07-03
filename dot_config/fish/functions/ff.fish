function ff
    clear
    # Play GIF in the background at top-left (Increased size)
    kitty +kitten icat --loop=0 --align=left --place 50x34@0x2 /home/sani/Downloads/touch.jpg

    # Run fastfetch with a "ghost logo" (single space) to force padding
    # --logo " " + --logo-type data-raw makes it think there's a logo
    # --logo-width and --logo-padding-left push the text to the right (Adjusted for larger GIF)
    fastfetch --logo " " --logo-type data-raw --logo-width 50 --logo-height 30 --logo-padding-left 00 --logo-padding-top 0
end
