#!/bin/bash

# Batman Todo Manager
# Manages a simple todo list with add/view/complete/delete operations

TODO_FILE="$HOME/.config/waybar/batman-todos.txt"
SCRIPT_DIR="$HOME/.config/waybar/scripts"

# Initialize todo file
if [ ! -f "$TODO_FILE" ]; then
    touch "$TODO_FILE"
fi

# Function to view todos
view_todos() {
    if [ ! -s "$TODO_FILE" ]; then
        echo "No todos yet!" | rofi -dmenu -p "Todos" \
            -theme-str 'window {width: 600px; location: center; anchor: center;}' \
            -theme-str 'listview {lines: 1;}'
        return
    fi
    
    # Add line numbers to todos
    todos=$(cat "$TODO_FILE" | nl -w2 -s'. ')
    
    echo "$todos" | rofi -dmenu -p "Your Todos" \
        -theme-str 'window {width: 600px; location: center; anchor: center;}' \
        -theme-str 'listview {lines: 10;}' \
        -theme-str 'element {padding: 10px;}' \
        -markup-rows
}

# Function to add a todo
add_todo() {
    new_todo=$(echo "" | rofi -dmenu -p "Add Todo" \
        -theme-str 'window {width: 600px; location: center; anchor: center;}' \
        -theme-str 'listview {lines: 0;}')
    
    if [ -n "$new_todo" ]; then
        echo "$new_todo" >> "$TODO_FILE"
        notify-send "Batman Todo" "✅ Todo added: $new_todo" -i checkbox
    fi
}

# Function to complete/remove a todo
complete_todo() {
    if [ ! -s "$TODO_FILE" ]; then
        echo "No todos to complete!" | rofi -dmenu -p "Complete Todo" \
            -theme-str 'window {width: 600px; location: center; anchor: center;}' \
            -theme-str 'listview {lines: 1;}'
        return
    fi
    
    # Show todos with line numbers
    todos=$(cat "$TODO_FILE" | nl -w2 -s'. ')
    
    selected=$(echo "$todos" | rofi -dmenu -p "Complete Todo" \
        -theme-str 'window {width: 600px; location: center; anchor: center;}' \
        -theme-str 'listview {lines: 10;}' \
        -theme-str 'element {padding: 10px;}')
    
    if [ -n "$selected" ]; then
        # Extract line number
        line_num=$(echo "$selected" | awk '{print $1}' | tr -d '.')
        
        # Get the todo text for notification
        todo_text=$(sed -n "${line_num}p" "$TODO_FILE")
        
        # Remove the selected line
        sed -i "${line_num}d" "$TODO_FILE"
        
        notify-send "Batman Todo" "✅ Completed: $todo_text" -i checkbox-checked
    fi
}

# Function to delete a todo
delete_todo() {
    if [ ! -s "$TODO_FILE" ]; then
        echo "No todos to delete!" | rofi -dmenu -p "Delete Todo" \
            -theme-str 'window {width: 600px; location: center; anchor: center;}' \
            -theme-str 'listview {lines: 1;}'
        return
    fi
    
    # Show todos with line numbers
    todos=$(cat "$TODO_FILE" | nl -w2 -s'. ')
    
    selected=$(echo "$todos" | rofi -dmenu -p "Delete Todo" \
        -theme-str 'window {width: 600px; location: center; anchor: center;}' \
        -theme-str 'listview {lines: 10;}' \
        -theme-str 'element {padding: 10px;}')
    
    if [ -n "$selected" ]; then
        # Extract line number
        line_num=$(echo "$selected" | awk '{print $1}' | tr -d '.')
        
        # Get the todo text for notification
        todo_text=$(sed -n "${line_num}p" "$TODO_FILE")
        
        # Remove the selected line
        sed -i "${line_num}d" "$TODO_FILE"
        
        notify-send "Batman Todo" "🗑️  Deleted: $todo_text" -i user-trash
    fi
}

# Main logic
case "$1" in
    view)
        view_todos
        ;;
    add)
        add_todo
        ;;
    complete)
        complete_todo
        ;;
    delete)
        delete_todo
        ;;
    *)
        echo "Usage: $0 {view|add|complete|delete}"
        exit 1
        ;;
esac
