#!/usr/bin/env python3
"""
Rofi Script Filter to list project directories.
Reads project_dirs from config file and enumerates subdirectories.
"""

import json
import os
import sys
from pathlib import Path


def get_config_file():
    """Get config file path from XDG or fallback to ~/.config."""
    config_dir = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    return os.path.join(config_dir, "claude-launcher", "config.json")


def get_project_dirs():
    """Get configured project directories from config file."""
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
    """List all project subdirectories from base directories."""
    projects = []

    for base_dir in base_dirs:
        base_path = Path(base_dir)
        try:
            for item in base_path.iterdir():
                if item.is_dir() and not item.name.startswith("."):
                    projects.append({
                        "name": item.name,
                        "path": str(item),
                        "parent": base_dir
                    })
        except PermissionError:
            continue

    projects.sort(key=lambda x: x["name"].lower())
    return projects


def filter_projects(projects, query):
    """Filter projects by query string (case-insensitive substring match)."""
    if not query:
        return projects

    query_lower = query.lower()
    return [p for p in projects if query_lower in p["name"].lower()]


def format_rofi_output(projects):
    """Format projects as rofi menu items with metadata."""
    if not projects:
        print("No projects found")
        return

    for project in projects:
        # Format: display_name\0icon\x1finfo\x1fpath
        # The path is stored in meta for retrieval later
        print(f"{project['name']}\0info\x1f{project['path']}")


def main():
    if len(sys.argv) > 1:
        query = sys.argv[1]
    else:
        query = ""

    project_dirs = get_project_dirs()

    if not project_dirs:
        print("No project directories configured")
        print("Run: claude-launcher-config")
        sys.exit(1)

    projects = list_projects(project_dirs)
    filtered = filter_projects(projects, query)

    format_rofi_output(filtered)


if __name__ == "__main__":
    main()
