#!/usr/bin/env python3
"""
Copy the last command and its output to clipboard
"""
import subprocess
import sys
import re
import os

def main():
    try:
        # Get the terminal text from kitty
        result = subprocess.run(
            ['kitty', '@', 'get-text'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            print(f"Error: Kitty remote control failed", file=sys.stderr)
            print(result.stderr, file=sys.stderr)
            return 1
        
        scrollback = result.stdout
        lines = scrollback.split('\n')
        
        # Find the last occurrence of the wrapper script in the scrollback
        wrapper_line_idx = -1
        for i in range(len(lines) - 1, -1, -1):
            if 'copy_last_wrapper.sh' in lines[i]:
                wrapper_line_idx = i
                break
        
        # If we found the wrapper, look backwards from there to find the actual command
        search_start = wrapper_line_idx if wrapper_line_idx >= 0 else len(lines) - 1
        
        # Look backwards to find a line that looks like a command
        # (not empty, not the wrapper itself, contains actual text)
        command_idx = -1
        for i in range(search_start - 1, -1, -1):
            line = lines[i].strip()
            # Skip empty lines and wrapper lines
            if line and 'wrapper' not in line and 'copy_' not in line:
                command_idx = i
                break
        
        if command_idx < 0:
            print("No command found", file=sys.stderr)
            return 1
        
        # Now collect from this line onwards, until we find the next prompt or wrapper call
        result_lines = [lines[command_idx]]
        
        for i in range(command_idx + 1, len(lines)):
            # Stop if we hit the wrapper script line again
            if 'wrapper' in lines[i]:
                break
            result_lines.append(lines[i])
        
        # Remove trailing empty lines
        while result_lines and not result_lines[-1].strip():
            result_lines.pop()
        
        content = '\n'.join(result_lines).strip()
        
        if not content:
            print("No content to copy", file=sys.stderr)
            return 1
        
        # Copy to clipboard
        subprocess.run(['wl-copy'], input=content, text=True)
        print(f"✓ Copied command and output")
        return 0
        
    except subprocess.TimeoutExpired:
        print("Error: Scrollback retrieval timed out", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
