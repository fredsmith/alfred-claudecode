# Alfred Claude Code Launcher

An Alfred workflow to quickly launch VS Code or Claude Code in your project directories.

## Features

- **`vs` keyword**: Search and open projects in VS Code
- **`cc` keyword**: Search and open projects in Claude Code (Terminal)
- **`gh` keyword**: Search and open projects on GitHub in browser
- **Configurable project directories**: Set multiple directories to search
- **Fuzzy search**: Filter projects by typing part of the name
- **Cmd+Enter**: Reveal project in Finder

## Installation

### Option 1: Download Release

Download the latest `.alfredworkflow` file from the [Releases](https://github.com/fredsmith/alfred-claudecode/releases) page and double-click to install.

### Option 2: Manual Installation

1. Clone this repository
2. Create the workflow package:

   ```bash
   cd workflow
   zip -r ../Claude-Code-Launcher.alfredworkflow .
   ```

3. Double-click `Claude-Code-Launcher.alfredworkflow` to install

## Configuration

After installing, configure your project directories:

1. Open Alfred Preferences
2. Go to Workflows → Claude Code Launcher
3. Click the `[x]` button in the top-right to open workflow configuration
4. Set **Project Directories** to a colon-separated list of paths

Example:

```text
~/src/github.com/fredsmith:~/claude-working:~/projects
```

## Usage

### Open in VS Code

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `vs` followed by a space
3. Start typing to filter projects
4. Press Enter to open in VS Code

### Open in Claude Code

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `cc` followed by a space
3. Start typing to filter projects
4. Press Enter to open in Terminal with Claude Code

### Open on GitHub

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `gh` followed by a space
3. Start typing to filter projects
4. Press Enter to open the GitHub repo in your browser

### Modifiers

- **Cmd+Enter**: Reveal the selected project in Finder

## Requirements

- [Alfred](https://www.alfredapp.com/) with Powerpack
- [VS Code](https://code.visualstudio.com/) (for `vs` keyword)
- [Claude Code CLI](https://claude.ai/claude-code) (for `cc` keyword)
- Python 3 (included with macOS)

## Customization

### VS Code Command Path

If `code` is not in `/usr/local/bin/`, edit the workflow:

1. Open Alfred Preferences → Workflows
2. Double-click the "Open VS Code" action
3. Update the path to your `code` command

### Terminal App

The workflow uses the default Terminal app. To use a different terminal (like iTerm), edit the "Open Claude Code" action's AppleScript.

## License

MIT
