#!/usr/bin/env python3
"""
Copy all terminal session (excluding fastfetch) to clipboard
"""
import subprocess
import sys
import os

def main():
    try:
        # Use kitty's remote control to get text from active window
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
        
        # Filter out fastfetch output
        lines = scrollback.split('\n')
        filtered_lines = []
        skip_section = False
        
        for line in lines:
            # Mark fastfetch section to skip
            if 'fastfetch' in line.lower():
                skip_section = True
                continue
            
            # Stop skipping when we find a shell prompt after fastfetch
            if skip_section and (line.strip().startswith('$') or line.strip().startswith('#') or line.strip().startswith('›')):
                skip_section = False
            
            if not skip_section:
                filtered_lines.append(line)
        
        content = '\n'.join(filtered_lines).strip()
        
        if not content:
            print("No content to copy", file=sys.stderr)
            return 1
        
        # Copy to clipboard using wl-copy
        subprocess.run(
            ['wl-copy'],
            input=content,
            text=True
        )
        
        print("✓ Copied terminal session to clipboard")
        return 0
        
    except subprocess.TimeoutExpired:
        print("Error: Scrollback retrieval timed out", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())


if __name__ == '__main__':
    sys.exit(main(sys.argv))
