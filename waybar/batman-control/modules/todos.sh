#!/bin/bash
# Todos module

TODO_FILE="$HOME/.config/waybar/batman-todos.txt"
MAX_DISPLAY=5

# Initialize todo file
[ ! -f "$TODO_FILE" ] && touch "$TODO_FILE"

render_todos() {
    local count=$([ -s "$TODO_FILE" ] && wc -l < "$TODO_FILE" || echo "0")
    
    cat <<EOF
<div class="module-card">
  <div class="module-header">
    📝 Tasks
    <span style="float: right; font-size: 11px; color: #565f89; font-weight: normal;">$count total</span>
  </div>
  <div class="module-content">
EOF

    if [ "$count" -gt 0 ]; then
        echo "    <div style='max-height: 200px; overflow-y: auto;'>"
        
        local line_num=0
        while IFS= read -r todo; do
            line_num=$((line_num + 1))
            [ $line_num -gt $MAX_DISPLAY ] && break
            
            echo "      <div class='todo-item'>"
            echo "        <span style='color: #7aa2f7; margin-right: 8px;'>•</span>"
            echo "        <span>$(echo "$todo" | sed 's/</\&lt;/g; s/>/\&gt;/g')</span>"
            echo "      </div>"
        done < "$TODO_FILE"
        
        if [ "$count" -gt $MAX_DISPLAY ]; then
            echo "      <div style='text-align: center; color: #565f89; font-size: 11px; margin-top: 8px;'>"
            echo "        ... and $((count - MAX_DISPLAY)) more tasks"
            echo "      </div>"
        fi
        
        echo "    </div>"
        echo "    <div style='margin-top: 12px; padding-top: 12px; border-top: 1px solid #414868;'>"
        echo "      <div style='display: flex; gap: 8px; justify-content: center;'>"
        echo "        <button class='action-button' onclick='add-todo'>➕ Add</button>"
        echo "        <button class='action-button' onclick='complete-todo'>✓ Done</button>"
        echo "        <button class='action-button' onclick='delete-todo'>🗑 Delete</button>"
        echo "      </div>"
        echo "    </div>"
    else
        echo "    <div class='empty-state'>"
        echo "      <div style='font-size: 32px; margin-bottom: 8px;'>🎉</div>"
        echo "      <div>No tasks! You're all done.</div>"
        echo "      <button class='action-button' onclick='add-todo' style='margin-top: 12px;'>➕ Add Task</button>"
        echo "    </div>"
    fi
    
    echo "  </div>"
    echo "</div>"
}

render_todos
