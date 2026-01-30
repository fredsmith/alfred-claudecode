#!/usr/bin/env python3
"""
Alfred Script Filter to list project directories.
Reads project_dirs workflow variable and enumerates subdirectories.
"""

import json
import os
import sys
from pathlib import Path


def get_project_dirs():
    """Get configured project directories from workflow variable."""
    project_dirs_str = os.environ.get("project_dirs", "")
    if not project_dirs_str:
        return [], []

    configured = []
    valid = []
    for path in project_dirs_str.split(":"):
        path = path.strip()
        if path:
            configured.append(path)
            expanded = os.path.expanduser(path)
            if os.path.isdir(expanded):
                valid.append(expanded)
    return configured, valid


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


def format_alfred_items(projects, action, base_dirs_configured, base_dirs_found):
    """Format projects as Alfred JSON items."""
    items = []

    for project in projects:
        if action == "vscode":
            subtitle = f"Open in VS Code: {project['path']}"
        elif action == "github":
            subtitle = f"Open on GitHub: {project['path']}"
        else:
            subtitle = f"Open in Claude Code: {project['path']}"

        items.append({
            "uid": project["path"],
            "title": project["name"],
            "subtitle": subtitle,
            "arg": project["path"],
            "autocomplete": project["name"],
            "icon": {
                "path": "icon.png"
            },
            "mods": {
                "cmd": {
                    "subtitle": f"Reveal in Finder: {project['path']}",
                    "arg": project["path"],
                    "variables": {
                        "action": "finder"
                    }
                }
            }
        })

    if not items:
        if not base_dirs_configured:
            items.append({
                "title": "No project directories configured",
                "subtitle": "Open workflow settings [x] and set Project Directories",
                "valid": False
            })
        elif not base_dirs_found:
            items.append({
                "title": "Configured directories not found",
                "subtitle": "Check that your configured paths exist",
                "valid": False
            })
        else:
            items.append({
                "title": "No projects found",
                "subtitle": "No subdirectories in configured paths",
                "valid": False
            })

    return {"items": items}


def main():
    action = os.environ.get("action", "vscode")
    query = sys.argv[1] if len(sys.argv) > 1 else ""

    configured_dirs, valid_dirs = get_project_dirs()
    projects = list_projects(valid_dirs)
    filtered = filter_projects(projects, query)

    result = format_alfred_items(
        filtered,
        action,
        base_dirs_configured=len(configured_dirs) > 0,
        base_dirs_found=len(valid_dirs) > 0
    )
    print(json.dumps(result))


if __name__ == "__main__":
    main()
