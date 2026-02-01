# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a project launcher for quickly opening code projects in VS Code, Claude Code (terminal), or GitHub. It supports:
- **macOS**: Alfred workflow with keywords `vs`, `cc`, `gh`
- **Linux**: Rofi-based launcher with similar functionality

## Build Commands

This project uses [Task](https://taskfile.dev/) for build automation:

```bash
# Build the Alfred workflow package (.alfredworkflow)
task build-alfred

# Build and install the Alfred workflow (opens to install)
task install-alfred

# Install the rofi launcher integration (Linux only)
task install-rofi
```

Manual build without Task:
```bash
cd workflow && zip -r ../Claude-Code-Launcher.alfredworkflow .
```

## Architecture

### Alfred Workflow (macOS)
- `workflow/info.plist` - Workflow configuration defining triggers, connections, and actions
- `workflow/list_projects.py` - Python script filter that enumerates project directories and outputs Alfred JSON format
- `workflow/icon.png` - Workflow icon

The workflow uses the `project_dirs` workflow variable (colon-separated paths) to find projects.

### Rofi Integration (Linux)
- `rofi/claude-launcher` - Main bash script handling actions (vs/cc/gh/fm)
- `rofi/list_projects.py` - Python script that outputs project paths for rofi
- `rofi/projects.sh` - Rofi script mode integration for combi mode
- `rofi/claude-launcher-config` - Configuration helper
- `rofi/install.sh` - Installation script

Configuration stored in: `~/.config/claude-launcher/config.json`

### Releases
GitHub Actions workflow (`.github/workflows/release.yml`) automatically creates releases on push to main using CalVer tags (YYYY.MM.DD format with incrementing suffix for same-day releases).
