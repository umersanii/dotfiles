#!/bin/bash

# Batman Control Center - Information Dashboard
# Quick glance at notifications, tasks, and system status

CONTROL_DIR="$HOME/.config/waybar/batman-control"
MODULES_DIR="$CONTROL_DIR/modules"
SCRIPT_DIR="$HOME/.config/waybar/scripts"
TODO_FILE="$HOME/.config/waybar/batman-todos.txt"

# Initialize
mkdir -p "$MODULES_DIR"
[ ! -f "$TODO_FILE" ] && touch "$TODO_FILE"

# Get recent notifications for glance view
get_notifications() {
    local count=$(swaync-client -c 2>/dev/null || echo "0")
    
    echo "<span size='x-large' weight='bold'>🔔</span> <span size='large' weight='bold'>Notifications</span>"
    echo ""
    
    if [ "$count" -gt 0 ]; then
        echo "<span foreground='#7aa2f7' size='xx-large' weight='heavy'>$count</span>"
        echo "<span foreground='#565f89' size='small'>unread notifications</span>"
        echo ""
        
        # Get recent notification titles if available
        local notifications=$(swaync-client -j 2>/dev/null | jq -r '.[] | .summary' 2>/dev/null | head -3)
        if [ -n "$notifications" ]; then
            echo "<span foreground='#565f89' size='small'>Recent:</span>"
            while IFS= read -r notif; do
                [ -n "$notif" ] && echo "<span foreground='#a9b1d6' size='small'>• $(echo "$notif" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | head -c 40)...</span>"
            done <<< "$notifications"
        fi
    else
        echo ""
        echo "<span foreground='#9ece6a' size='large'>✓</span>"
        echo "<span foreground='#9ece6a'>All caught up!</span>"
        echo "<span foreground='#565f89' size='small'>No new notifications</span>"
    fi
}

# Get todos for glance view
get_todos() {
    local count=$([ -s "$TODO_FILE" ] && wc -l < "$TODO_FILE" || echo "0")
    
    echo ""
    echo ""
    echo "<span size='x-large' weight='bold'>📝</span> <span size='large' weight='bold'>Tasks</span>"
    echo ""
    
    if [ "$count" -gt 0 ]; then
        echo "<span foreground='#bb9af7' size='xx-large' weight='heavy'>$count</span>"
        echo "<span foreground='#565f89' size='small'>pending tasks</span>"
        echo ""
        
        # Show first 3 todos
        local line_num=0
        while IFS= read -r todo && [ $line_num -lt 3 ]; do
            line_num=$((line_num + 1))
            local escaped=$(echo "$todo" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | head -c 50)
            echo "<span foreground='#7aa2f7' size='small'>•</span> <span foreground='#a9b1d6' size='small'>$escaped</span>"
        done < "$TODO_FILE"
        
        if [ "$count" -gt 3 ]; then
            echo "<span foreground='#565f89' size='x-small'>+$((count - 3)) more tasks</span>"
        fi
    else
        echo ""
        echo "<span foreground='#9ece6a' size='large'>🎉</span>"
        echo "<span foreground='#9ece6a'>All done!</span>"
        echo "<span foreground='#565f89' size='small'>No pending tasks</span>"
    fi
}

# Get system info for glance view
get_system() {
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
    local mem=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local mem_used=$(free -h | grep Mem | awk '{print $3}')
    local mem_total=$(free -h | grep Mem | awk '{print $2}')
    local uptime=$(uptime -p | sed 's/up //')
    local disk=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    
    local cpu_color="#9ece6a"
    [ "$cpu" -gt 70 ] && cpu_color="#e0af68"
    [ "$cpu" -gt 90 ] && cpu_color="#f7768e"
    
    local mem_color="#9ece6a"
    [ "$mem" -gt 70 ] && mem_color="#e0af68"
    [ "$mem" -gt 90 ] && mem_color="#f7768e"
    
    local disk_color="#9ece6a"
    [ "$disk" -gt 70 ] && disk_color="#e0af68"
    [ "$disk" -gt 90 ] && disk_color="#f7768e"
    
    echo ""
    echo ""
    echo "<span size='x-large' weight='bold'>💻</span> <span size='large' weight='bold'>System</span>"
    echo ""
    echo "<span foreground='#565f89' size='small'>CPU</span>     <span foreground='$cpu_color' size='large' weight='bold'>${cpu}%</span>"
    echo "<span foreground='#565f89' size='small'>Memory</span>  <span foreground='$mem_color' size='large' weight='bold'>${mem}%</span>  <span foreground='#565f89' size='x-small'>$mem_used / $mem_total</span>"
    echo "<span foreground='#565f89' size='small'>Disk</span>    <span foreground='$disk_color' size='large' weight='bold'>${disk}%</span>"
    echo ""
    echo "<span foreground='#565f89' size='x-small'>uptime: $uptime</span>"
}

# Build the dashboard
build_dashboard() {
    get_notifications
    echo ""
    echo "<span foreground='#414868'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>"
    get_todos
    echo ""
    echo "<span foreground='#414868'>━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━</span>"
    get_system
}

# Show dashboard (read-only, press ESC to close)
build_dashboard | rofi \
    -dmenu \
    -i \
    -markup-rows \
    -p "🦇" \
    -mesg "<span size='small' foreground='#565f89'>Press ESC to close</span>" \
    -no-custom \
    -theme-str 'window {
        width: 480px;
        location: center;
        anchor: center;
        background-color: #1a1b26;
        border: 2px;
        border-color: #7aa2f7;
        border-radius: 16px;
        padding: 0;
    }' \
    -theme-str 'mainbox {
        padding: 24px;
        background-color: #1a1b26;
        spacing: 8px;
    }' \
    -theme-str 'inputbar {
        enabled: false;
    }' \
    -theme-str 'message {
        padding: 8px;
        background-color: transparent;
        border: 0;
        text-color: #565f89;
    }' \
    -theme-str 'textbox {
        text-color: inherit;
        background-color: transparent;
    }' \
    -theme-str 'listview {
        lines: 25;
        spacing: 2px;
        background-color: transparent;
        scrollbar: false;
        fixed-height: false;
    }' \
    -theme-str 'element {
        padding: 2px 0px;
        background-color: transparent;
        enabled: false;
    }' \
    -theme-str 'element-text {
        background-color: transparent;
        text-color: #a9b1d6;
    }'
