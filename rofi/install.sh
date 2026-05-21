#!/bin/bash
# Installation script for claude-launcher rofi integration

set -e

echo "Claude Launcher - Rofi Installation"
echo "===================================="
echo ""

# Check for rofi
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed."
    echo "Please install rofi first:"
    echo "  Debian/Ubuntu: sudo apt install rofi"
    echo "  Arch: sudo pacman -S rofi"
    echo "  Fedora: sudo dnf install rofi"
    exit 1
fi

# Determine installation directory
INSTALL_DIR="${HOME}/.local/bin"

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy scripts
echo "Installing scripts to $INSTALL_DIR..."
cp "$SCRIPT_DIR/list_projects.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/claude-launcher" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/claude-launcher-config" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/projects.sh" "$INSTALL_DIR/"

# Make scripts executable
chmod +x "$INSTALL_DIR/list_projects.py"
chmod +x "$INSTALL_DIR/claude-launcher"
chmod +x "$INSTALL_DIR/claude-launcher-config"
chmod +x "$INSTALL_DIR/projects.sh"

echo "✓ Scripts installed"
echo ""

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Warning: $INSTALL_DIR is not in your PATH"
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Run configuration
echo "Running configuration..."
"$INSTALL_DIR/claude-launcher-config"

echo ""
echo "=== Rofi Combi Mode Setup ==="

ROFI_CONFIG_DIR="${HOME}/.config/rofi"
ROFI_CONFIG_FILE="${ROFI_CONFIG_DIR}/config.rasi"

if [ ! -d "$ROFI_CONFIG_DIR" ]; then
    echo "Creating rofi config directory: $ROFI_CONFIG_DIR"
    mkdir -p "$ROFI_CONFIG_DIR"
fi

if [ ! -f "$ROFI_CONFIG_FILE" ]; then
    echo "No rofi config found. Would you like to create one with projects integration? (y/n)"
    read -r response
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        cat > "$ROFI_CONFIG_FILE" << 'EOF'
configuration {
    modi: "combi,drun,window,run";
    combi-modi: "drun,run,window,script:~/.local/bin/projects.sh";
    show: "combi";
}
EOF
        echo "✓ Created $ROFI_CONFIG_FILE with projects integration"
        echo "  Your existing Meta+D keybinding will now show apps AND projects!"
    else
        echo "Skipped rofi config creation"
    fi
else
    echo "Existing rofi config found at: $ROFI_CONFIG_FILE"
    echo ""
    echo "To enable combi mode integration, add this to your config:"
    echo ""
    echo "configuration {"
    echo "    modi: \"combi,drun,window,run\";"
    echo "    combi-modi: \"drun,run,window,script:$INSTALL_DIR/projects.sh\";"
    echo "    show: \"combi\";"
    echo "}"
fi

echo ""
echo "Installation complete!"
echo ""
echo "=== Usage ==="
echo ""
echo "Standalone commands:"
echo "  claude-launcher vs                      - Open project in VS Code"
echo "  claude-launcher cc                      - Open project in Claude Code"
echo "  claude-launcher gh                      - Open project on GitHub"
echo "  claude-launcher fm                      - Open project in file manager"
echo "  claude-launcher review <pr-url> [prompt] - Check out a GitHub PR and launch Claude"
echo ""
echo "Alternative: Separate Keybindings"
echo "Example i3/sway keybindings:"
echo "  bindsym \$mod+p exec claude-launcher vs"
echo "  bindsym \$mod+Shift+p exec claude-launcher cc"
echo "  bindsym \$mod+Ctrl+p exec claude-launcher gh"
echo "  bindsym \$mod+Ctrl+r exec claude-launcher review"
