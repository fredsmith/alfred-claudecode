#!/bin/bash
# Rofi script mode for project launcher
# This integrates with rofi -show and combi mode

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If no ROFI_RETV, we're being called to list entries
if [ -z "$ROFI_RETV" ] || [ "$ROFI_RETV" = "0" ]; then
    # List all projects with action prefix
    python3 << 'PYEOF'
import json
import os
import sys
from pathlib import Path

def get_config_file():
    config_dir = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return os.path.join(config_dir, "claude-launcher", "config.json")

def get_project_dirs():
    config_file = get_config_file()
    if not os.path.exists(config_file):
        return []
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
            project_dirs_str = config.get("project_dirs", "")
    except (json.JSONDecodeError, IOError):
        return []

    valid = []
    for path in project_dirs_str.split(":"):
        path = path.strip()
        if path:
            expanded = os.path.expanduser(path)
            if os.path.isdir(expanded):
                valid.append(expanded)
    return valid

def list_projects(base_dirs):
    projects = []
    for base_dir in base_dirs:
        base_path = Path(base_dir)
        try:
            for item in base_path.iterdir():
                if item.is_dir() and not item.name.startswith("."):
                    projects.append({
                        "name": item.name,
                        "path": str(item)
                    })
        except PermissionError:
            continue
    projects.sort(key=lambda x: x["name"].lower())
    return projects

project_dirs = get_project_dirs()
projects = list_projects(project_dirs)

for project in projects:
    # Output format for rofi: display_text\0info\x1fmetadata
    print(f"{project['name']} (VS Code)\0info\x1fvs:{project['path']}")
    print(f"{project['name']} (Claude)\0info\x1fcc:{project['path']}")
    print(f"{project['name']} (GitHub)\0info\x1fgh:{project['path']}")
PYEOF
    exit 0
fi

# If ROFI_RETV is 1, user selected an entry
if [ "$ROFI_RETV" = "1" ]; then
    # Parse the info field which contains "action:path"
    ACTION=$(echo "$ROFI_INFO" | cut -d: -f1)
    PROJECT_PATH=$(echo "$ROFI_INFO" | cut -d: -f2-)

    # Execute the appropriate action
    case "$ACTION" in
        vs)
            if command -v code &> /dev/null; then
                nohup code "$PROJECT_PATH" >/dev/null 2>&1 &
                disown
            else
                notify-send "Error" "VS Code not found"
            fi
            ;;
        cc)
            # Find claude in common locations
            CLAUDE_CMD=""
            if command -v claude &> /dev/null; then
                CLAUDE_CMD="claude"
            elif [ -x "$HOME/.local/bin/claude" ]; then
                CLAUDE_CMD="$HOME/.local/bin/claude"
            elif [ -x "/usr/local/bin/claude" ]; then
                CLAUDE_CMD="/usr/local/bin/claude"
            fi

            if [ -n "$CLAUDE_CMD" ]; then
                # Detect user's default shell (prefer fish, fallback to bash)
                USER_SHELL="${SHELL:-/bin/bash}"

                # Detect terminal and launch with login shell to get full environment
                # Use nohup and redirect output to properly detach from rofi
                if [ -n "$TERMINAL" ]; then
                    nohup $TERMINAL -e "$USER_SHELL" -l -c "cd '$PROJECT_PATH' && $CLAUDE_CMD" >/dev/null 2>&1 &
                elif command -v ghostty &> /dev/null; then
                    nohup ghostty -e "$USER_SHELL" -l -c "cd '$PROJECT_PATH' && $CLAUDE_CMD" >/dev/null 2>&1 &
                elif command -v x-terminal-emulator &> /dev/null; then
                    nohup x-terminal-emulator -e "$USER_SHELL" -l -c "cd '$PROJECT_PATH' && $CLAUDE_CMD" >/dev/null 2>&1 &
                elif command -v gnome-terminal &> /dev/null; then
                    nohup gnome-terminal -- "$USER_SHELL" -l -c "cd '$PROJECT_PATH' && $CLAUDE_CMD" >/dev/null 2>&1 &
                elif command -v konsole &> /dev/null; then
                    nohup konsole -e "$USER_SHELL" -l -c "cd '$PROJECT_PATH' && $CLAUDE_CMD" >/dev/null 2>&1 &
                elif command -v xfce4-terminal &> /dev/null; then
                    nohup xfce4-terminal -e "$USER_SHELL -l -c 'cd \"$PROJECT_PATH\" && $CLAUDE_CMD'" >/dev/null 2>&1 &
                elif command -v alacritty &> /dev/null; then
                    nohup alacritty -e "$USER_SHELL" -l -c "cd '$PROJECT_PATH' && $CLAUDE_CMD" >/dev/null 2>&1 &
                elif command -v kitty &> /dev/null; then
                    nohup kitty "$USER_SHELL" -l -c "cd '$PROJECT_PATH' && $CLAUDE_CMD" >/dev/null 2>&1 &
                elif command -v wezterm &> /dev/null; then
                    nohup wezterm start --cwd "$PROJECT_PATH" -- "$USER_SHELL" -l -c "$CLAUDE_CMD" >/dev/null 2>&1 &
                fi
                disown
            else
                notify-send "Error" "Claude Code not found. Tried: claude, ~/.local/bin/claude, /usr/local/bin/claude"
            fi
            ;;
        gh)
            cd "$PROJECT_PATH" || exit 1
            URL=$(git remote get-url origin 2>/dev/null | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')
            if [ -n "$URL" ]; then
                nohup xdg-open "$URL" >/dev/null 2>&1 &
                disown
            else
                notify-send "Error" "No git remote found"
            fi
            ;;
    esac

    exit 0
fi
