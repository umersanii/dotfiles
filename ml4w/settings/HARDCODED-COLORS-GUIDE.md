# Hardcoded Waybar Accent Colors Guide

## How to Use Custom Colors for Specific Wallpapers

### 1. Edit the Configuration File
Open: `~/.config/ml4w/settings/wallpaper-colors.conf`

### 2. Add Your Wallpaper Mappings
Format: `wallpaper_filename|primary_color|secondary_color`

Example:
```
fall-echo-tries.png|#1e88e5|#42a5f5
sunset.jpg|#ff5722|#ff9800
anime-wallpaper.png|#9c27b0|#ba68c8
```

### 3. Color Selection Tips
- **Primary color**: Main accent (used for active workspace, borders on hover)
- **Secondary color**: Border color for modules

You can use:
- Hex colors: `#1e88e5`
- Material Design Color Palette: https://m2.material.io/design/color/
- Color picker from your wallpaper

### 4. Test Your Colors
After adding entries, change to that wallpaper:
```bash
~/.config/hypr/scripts/wallpaper.sh
```

Or manually apply colors:
```bash
~/.config/ml4w/scripts/apply-custom-colors.sh "#1e88e5" "#42a5f5"
~/.config/waybar/launch.sh
```

### 5. Behavior
- If wallpaper is listed in config → Uses your custom colors
- If wallpaper is NOT listed → Uses matugen (automatic color extraction)

### 6. Finding Wallpaper Filename
Your current wallpaper:
```bash
cat ~/.cache/ml4w/hyprland-dotfiles/current_wallpaper
```

Just use the filename (not the full path) in the config.

### 7. Good Color Combinations
Some aesthetically pleasing combinations:

**Blue Accent:**
- Primary: `#1976d2` Secondary: `#42a5f5`

**Purple Accent:**
- Primary: `#7b1fa2` Secondary: `#9c27b0`

**Red/Pink Accent:**
- Primary: `#c2185b` Secondary: `#e91e63`

**Orange Accent:**
- Primary: `#f57c00` Secondary: `#ff9800`

**Green Accent:**
- Primary: `#388e3c` Secondary: `#66bb6a`

**Cyan/Teal Accent:**
- Primary: `#0097a7` Secondary: `#00bcd4`
