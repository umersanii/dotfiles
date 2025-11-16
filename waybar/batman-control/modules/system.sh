#!/bin/bash
# System info module

get_system_data() {
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
    local mem=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    local mem_used=$(free -h | grep Mem | awk '{print $3}')
    local mem_total=$(free -h | grep Mem | awk '{print $2}')
    local uptime=$(uptime -p | sed 's/up //')
    local disk=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    
    echo "$cpu|$mem|$mem_used|$mem_total|$uptime|$disk"
}

render_system() {
    local data=$(get_system_data)
    local cpu=$(echo "$data" | cut -d'|' -f1)
    local mem=$(echo "$data" | cut -d'|' -f2)
    local mem_used=$(echo "$data" | cut -d'|' -f3)
    local mem_total=$(echo "$data" | cut -d'|' -f4)
    local uptime=$(echo "$data" | cut -d'|' -f5)
    local disk=$(echo "$data" | cut -d'|' -f6)
    
    # Color coding for values
    local cpu_color="#9ece6a"
    [ "$cpu" -gt 70 ] && cpu_color="#e0af68"
    [ "$cpu" -gt 90 ] && cpu_color="#f7768e"
    
    local mem_color="#9ece6a"
    [ "$mem" -gt 70 ] && mem_color="#e0af68"
    [ "$mem" -gt 90 ] && mem_color="#f7768e"
    
    cat <<EOF
<div class="module-card">
  <div class="module-header">💻 System</div>
  <div class="module-content">
    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
      
      <div style="background: #1a1b26; padding: 12px; border-radius: 8px;">
        <div style="color: #565f89; font-size: 10px; text-transform: uppercase; margin-bottom: 4px;">CPU Usage</div>
        <div style="font-size: 20px; font-weight: bold; color: $cpu_color;">$cpu%</div>
      </div>
      
      <div style="background: #1a1b26; padding: 12px; border-radius: 8px;">
        <div style="color: #565f89; font-size: 10px; text-transform: uppercase; margin-bottom: 4px;">Memory</div>
        <div style="font-size: 20px; font-weight: bold; color: $mem_color;">$mem%</div>
        <div style="color: #565f89; font-size: 9px; margin-top: 2px;">$mem_used / $mem_total</div>
      </div>
      
    </div>
    
    <div style="margin-top: 12px; padding-top: 12px; border-top: 1px solid #414868;">
      <div style="display: flex; justify-content: space-between; margin-bottom: 6px;">
        <span style="color: #565f89; font-size: 11px;">Disk Usage</span>
        <span style="color: #7aa2f7; font-size: 11px; font-weight: bold;">$disk%</span>
      </div>
      <div style="display: flex; justify-content: space-between;">
        <span style="color: #565f89; font-size: 11px;">Uptime</span>
        <span style="color: #7aa2f7; font-size: 11px;">$uptime</span>
      </div>
    </div>
  </div>
</div>
EOF
}

render_system
