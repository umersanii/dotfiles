#!/bin/bash
# Notifications module

get_notification_data() {
    local count=$(swaync-client -c 2>/dev/null || echo "0")
    local dnd_status=$(swaync-client -D 2>/dev/null)
    
    cat <<EOF
{
  "count": $count,
  "dnd": "$dnd_status",
  "status": "$([ "$count" -gt 0 ] && echo "active" || echo "clear")"
}
EOF
}

render_notifications() {
    local data=$(get_notification_data)
    local count=$(echo "$data" | jq -r '.count')
    local status=$(echo "$data" | jq -r '.status')
    
    if [ "$count" -gt 0 ]; then
        cat <<EOF
<div class="module-card" onclick="swaync-client -t">
  <div class="module-header">🔔 Notifications</div>
  <div class="module-content">
    <div style="text-align: center; padding: 12px 0;">
      <span style="font-size: 24px; color: #7aa2f7; font-weight: bold;">$count</span>
      <div style="color: #565f89; font-size: 11px; margin-top: 4px;">unread notifications</div>
    </div>
    <div style="text-align: center; color: #7aa2f7; font-size: 11px;">
      Click to open notification center
    </div>
  </div>
</div>
EOF
    else
        cat <<EOF
<div class="module-card" onclick="swaync-client -t">
  <div class="module-header">🔔 Notifications</div>
  <div class="module-content">
    <div style="text-align: center; padding: 12px 0;">
      <span style="font-size: 18px; color: #9ece6a;">✓ All caught up!</span>
      <div style="color: #565f89; font-size: 11px; margin-top: 4px;">No new notifications</div>
    </div>
  </div>
</div>
EOF
    fi
}

render_notifications
