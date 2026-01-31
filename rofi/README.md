# Claude Launcher - Rofi Integration

A rofi-based project launcher for Linux that provides quick access to your projects via VS Code, Claude Code (terminal), GitHub, or file manager.

## Features

- **VS Code launcher**: Quickly open projects in VS Code
- **Claude Code launcher**: Open projects in Claude Code via terminal
- **GitHub launcher**: Open projects on GitHub in your browser
- **File manager**: Open projects in your default file manager
- **Fuzzy search**: Filter projects by typing
- **Configurable directories**: Set multiple directories to search
- **Combi mode integration**: Add projects to your existing rofi app launcher
- **Keyboard shortcuts**: Can be bound to any key combination in your window manager

## Requirements

- `rofi` - Application launcher
- `python3` - For project listing script
- `code` (optional) - VS Code CLI for VS Code integration
- `claude` (optional) - Claude Code CLI for Claude integration
- `git` (optional) - For GitHub integration
- A terminal emulator (automatically detected)

### Installing Dependencies

**Debian/Ubuntu:**
```bash
sudo apt install rofi python3 git
```

**Arch Linux:**
```bash
sudo pacman -S rofi python git
```

**Fedora:**
```bash
sudo dnf install rofi python3 git
```

## Installation

1. Run the installation script:
```bash
cd rofi
./install.sh
```

2. Follow the prompts to configure your project directories

3. Ensure `~/.local/bin` is in your PATH (add to `~/.bashrc` or `~/.zshrc`):
```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Configuration

Edit your project directories:
```bash
claude-launcher-config
```

Enter directories separated by colons, for example:
```
~/projects:~/src/github.com/username:~/work
```

The configuration is stored in: `~/.config/claude-launcher/config.json`

## Usage

### Method 1: Combi Mode Integration (Recommended)

This integrates your projects directly into your existing rofi launcher, so pressing Meta+D shows both apps and projects together.

#### Setup for KDE Plasma / General

1. Create or edit `~/.config/rofi/config.rasi`:

```rasi
configuration {
    modi: "combi,drun,window,run";
    combi-modi: "drun,run,window,script:~/.local/bin/projects.sh";
    show: "combi";
}
```

**Note**: On Wayland (especially KDE Plasma), the `window` mode may not work due to protocol limitations. You can remove it from the config if you see warnings.

2. Your existing Meta+D keybinding (`rofi -show combi`) will now show:
   - Applications (drun)
   - Open windows (window)
   - Projects with actions: "ProjectName (VS Code)", "ProjectName (Claude)", "ProjectName (GitHub)"

#### How It Works

When you type in rofi, you'll see all your projects with action suffixes:
- `my-project (VS Code)` - Opens in VS Code
- `my-project (Claude)` - Opens in Claude Code terminal
- `my-project (GitHub)` - Opens GitHub repo in browser

Just type to filter by project name, then select the action you want!

### Method 2: Standalone Command Line

```bash
# Open in VS Code
claude-launcher vs

# Open in Claude Code (terminal)
claude-launcher cc

# Open on GitHub
claude-launcher gh

# Open in file manager
claude-launcher fm
```

### Method 3: Separate Keyboard Shortcuts

If you prefer dedicated shortcuts instead of combi mode, you can bind these commands to keyboard shortcuts in your window manager or desktop environment.

#### i3 / Sway

Add to your `~/.config/i3/config` or `~/.config/sway/config`:

```
# Launch VS Code project
bindsym $mod+p exec claude-launcher vs

# Launch Claude Code project
bindsym $mod+Shift+p exec claude-launcher cc

# Open GitHub repo
bindsym $mod+Ctrl+p exec claude-launcher gh

# Open in file manager
bindsym $mod+Mod1+p exec claude-launcher fm
```

#### KDE Plasma

1. Open System Settings → Shortcuts → Custom Shortcuts
2. Click "Edit" → "New" → "Global Shortcut" → "Command/URL"
3. Set your desired trigger and add the command (e.g., `claude-launcher vs`)

#### GNOME

Install the "Custom Keyboard Shortcuts" extension or use:
```bash
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Launch VS Code Project"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "claude-launcher vs"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Super>p"
```

#### XFCE

1. Open Settings → Keyboard → Application Shortcuts
2. Click "Add" and enter the command (e.g., `claude-launcher vs`)
3. Press your desired key combination

## Terminal Emulator and Shell Detection

### Terminal Detection

The script automatically detects your terminal emulator in this order:

1. `$TERMINAL` environment variable
2. `ghostty`
3. `x-terminal-emulator`
4. `gnome-terminal`
5. `konsole`
6. `xfce4-terminal`
7. `alacritty`
8. `kitty`
9. `wezterm`

To use a specific terminal, set the `TERMINAL` environment variable:
```bash
export TERMINAL=ghostty
```

### Shell Detection

The script automatically uses your default shell (`$SHELL` environment variable) when launching Claude Code. This ensures your PATH and environment variables are loaded correctly, whether you use bash, fish, zsh, or another shell.

## Comparison with Alfred Workflow

This rofi integration provides the same core functionality as the Alfred workflow for macOS:

| Feature | Alfred (macOS) | Rofi (Linux) |
|---------|---------------|--------------|
| VS Code launcher | `vs` keyword | `claude-launcher vs` |
| Claude Code launcher | `cc` keyword | `claude-launcher cc` |
| GitHub launcher | `gh` keyword | `claude-launcher gh` |
| File manager | Cmd+Enter modifier | `claude-launcher fm` |
| Configuration | Alfred workflow variables | `claude-launcher-config` |
| Fuzzy search | ✓ | ✓ |
| Keyboard shortcuts | ✓ | ✓ (via WM) |

## Troubleshooting

### No projects showing up

1. Run `claude-launcher-config` to verify your directories
2. Check that the directories exist and contain subdirectories
3. Ensure subdirectories don't start with `.` (hidden folders are excluded)

### Terminal doesn't open

1. Set the `TERMINAL` environment variable to your preferred terminal
2. Or install one of the auto-detected terminals

### VS Code/Claude Code not found

1. Ensure the `code` or `claude` command is in your PATH
2. Check installation with: `which code` or `which claude`

## License

MIT
