# Claude Code Launcher

A project launcher for quickly opening your projects in VS Code, Claude Code (terminal), or GitHub. Supports both **macOS** (Alfred) and **Linux** (rofi).

## Features

- **VS Code launcher**: Search and open projects in VS Code
- **Claude Code launcher**: Open projects in Claude Code via terminal
- **GitHub launcher**: Open projects on GitHub in your browser
- **File manager**: Reveal projects in Finder (macOS) or file manager (Linux)
- **Fuzzy search**: Filter projects by typing part of the name
- **Configurable directories**: Set multiple directories to search

| Feature | Alfred (macOS) | Rofi (Linux) |
|---------|---------------|--------------|
| VS Code launcher | `vs` keyword | `claude-launcher vs` |
| Claude Code launcher | `cc` keyword | `claude-launcher cc` |
| GitHub launcher | `gh` keyword | `claude-launcher gh` |
| PR review launcher | `review` keyword | `claude-launcher review` |
| Issue implementation launcher | `implement-issue` keyword | — |
| File manager | Cmd+Enter modifier | `claude-launcher fm` |
| Configuration | Alfred workflow variables | `claude-launcher-config` |
| Fuzzy search | ✓ | ✓ |
| Keyboard shortcuts | ✓ | ✓ (via WM) |

---

## Alfred (macOS)

### Requirements

- [Alfred](https://www.alfredapp.com/) with Powerpack
- [VS Code](https://code.visualstudio.com/) (for `vs` keyword)
- [Claude Code CLI](https://claude.ai/code) (for `cc`, `review`, and `implement-issue` keywords)
- [GitHub CLI](https://cli.github.com/) (`gh`, for `review` and `implement-issue` keywords)
- Python 3 (included with macOS)

### Installation

#### Option 1: Download Release

Download the latest `.alfredworkflow` file from the [Releases](https://github.com/fredsmith/alfred-claudecode/releases) page and double-click to install.

#### Option 2: Manual Installation

1. Clone this repository
2. Create the workflow package:

   ```bash
   cd workflow
   zip -r ../Claude-Code-Launcher.alfredworkflow .
   ```

3. Double-click `Claude-Code-Launcher.alfredworkflow` to install

### Configuration

After installing, configure your project directories:

1. Open Alfred Preferences
2. Go to Workflows → Claude Code Launcher
3. Click the `[x]` button in the top-right to open workflow configuration
4. Set **Project Directories** to a colon-separated list of paths

Example:

```text
~/src/github.com/fredsmith:~/claude-working:~/projects
```

### Usage

#### Open in VS Code

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `vs` followed by a space
3. Start typing to filter projects
4. Press Enter to open in VS Code

#### Open in Claude Code

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `cc` followed by a space
3. Start typing to filter projects
4. Press Enter to open in Terminal with Claude Code

#### Open on GitHub

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `gh` followed by a space
3. Either start typing to filter projects (Enter opens the repo root), or
   type `<project>#<n>` to jump straight to issue/PR `<n>` (GitHub
   redirects issue numbers to the PR view if the number is a PR)

Example:

```text
gh wayfinder#171
```

Matches an exact project directory name in your configured `project_dirs`.
Ambiguous names (e.g. two checkouts of the same repo under different
parents) surface an error rather than guessing.

#### Review a GitHub PR

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `review` followed by a space
3. Provide either:
   - a full PR URL (e.g. `https://github.com/wanderu/infrastructure-as-code/pull/193`), or
   - a `<project>#<n>` shorthand (e.g. `infrastructure-as-code#193`) that
     resolves against your configured `project_dirs`
4. Optionally add a prompt after the locator — it will be passed to
   Claude Code as the initial prompt
5. Press Enter

The action expects the repo cloned at `~/src/github.com/<owner>/<repo>`
(for the URL form) or under one of your `project_dirs` (for the
shorthand). It creates a `.worktrees/<branch>` git worktree inside the
local clone, runs `gh pr checkout <number>` there, then launches
`claude` with your prompt — your main checkout is left untouched.

Examples:

```text
review https://github.com/wanderu/infrastructure-as-code/pull/193 is this going to cause the database to be deleted and recreated?
review infrastructure-as-code#193 is this going to cause the database to be deleted and recreated?
```

#### Implement a GitHub issue

1. Invoke Alfred (Cmd+Space or your hotkey)
2. Type `implement-issue` followed by a space
3. Provide either:
   - a full issue URL (e.g. `https://github.com/wanderu/actions/issues/357`), or
   - a `[<owner>/]<project>#<n>` shorthand (e.g. `actions#357`) that
     resolves against your configured `project_dirs`
4. Optionally add a prompt after the locator — it is appended to the
   initial prompt
5. Press Enter

The action expects the repo cloned at `~/src/github.com/<owner>/<repo>`
(for the URL form) or under one of your `project_dirs` (for the
shorthand). It fetches from origin, switches the clone to the repo's
default branch and fast-forwards it, reads the issue title and body with
`gh`, then launches `claude` with a prompt telling it to branch into a
worktree, push a draft PR, run `/code-review`, and address the findings.

Examples:

```text
implement-issue https://github.com/wanderu/actions/issues/357
implement-issue actions#357 keep the change scoped to the composite action
```

#### Modifiers

- **Cmd+Enter**: Reveal the selected project in Finder

### Customization

#### VS Code Command Path

If `code` is not in `/usr/local/bin/`, edit the workflow:

1. Open Alfred Preferences → Workflows
2. Double-click the "Open VS Code" action
3. Update the path to your `code` command

#### Terminal App

The workflow uses Ghostty if installed, otherwise falls back to the default Terminal app. To use a different terminal (like iTerm), edit the "Open Claude Code" action's script.

---

## Rofi (Linux)

### Requirements

- [rofi](https://github.com/davatorium/rofi) - Application launcher
- `python3` - For project listing script
- `code` (optional) - VS Code CLI
- `claude` (optional) - Claude Code CLI
- `git` (optional) - For GitHub integration

### Installation

Run the installation script (or use `task install-rofi`):

```bash
./rofi/install.sh
```

This will:
1. Install scripts to `~/.local/bin`
2. Configure your project directories
3. Automatically update `~/.config/rofi/config.rasi` to add project integration

Ensure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Configuration

Edit your project directories anytime:
```bash
claude-launcher-config
```

Enter directories separated by colons (e.g., `~/projects:~/src/github.com/username`).

Configuration is stored in `~/.config/claude-launcher/config.json`.

### Usage

Projects appear in rofi combi mode with action suffixes:
- `my-project (VS Code)` - Opens in VS Code
- `my-project (Claude)` - Opens in Claude Code terminal
- `my-project (GitHub)` - Opens GitHub repo in browser

Or use standalone commands:

```bash
claude-launcher vs   # Open in VS Code
claude-launcher cc   # Open in Claude Code (terminal)
claude-launcher gh   # Open on GitHub
claude-launcher fm   # Open in file manager
```

### Terminal Detection

The script auto-detects your terminal (ghostty, gnome-terminal, konsole, alacritty, kitty, wezterm, etc.) or uses the `$TERMINAL` environment variable.

---

## License

MIT
