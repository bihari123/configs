#!/bin/bash

# Config Setup Script
# This script sets up all configurations from this repository

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up configurations...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Setup tmux configuration
echo -e "${YELLOW}Setting up tmux configuration...${NC}"
if [ -f "$HOME/.tmux.conf" ]; then
    echo "Backing up existing .tmux.conf to .tmux.conf.bak"
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
fi
ln -sf "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
echo -e "${GREEN}✓ Tmux configuration linked${NC}"

# Setup alacritty configuration
echo -e "${YELLOW}Setting up alacritty configuration...${NC}"
mkdir -p "$HOME/.config/alacritty"
if [ -f "$HOME/.config/alacritty/alacritty.toml" ]; then
    echo "Backing up existing alacritty.toml to alacritty.toml.bak"
    cp "$HOME/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml.bak"
fi
ln -sf "$SCRIPT_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
echo -e "${GREEN}✓ Alacritty configuration linked${NC}"

# Setup bin directory and scripts
echo -e "${YELLOW}Setting up scripts...${NC}"
mkdir -p "$HOME/bin"

# Copy pomodoro script
cp "$SCRIPT_DIR/bin/pomodoro" "$HOME/bin/"
chmod +x "$HOME/bin/pomodoro"
echo -e "${GREEN}✓ Pomodoro timer installed${NC}"

# Add ~/bin to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/bin"; then
    echo -e "${YELLOW}Adding ~/bin to PATH...${NC}"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    echo -e "${GREEN}✓ PATH updated (reload shell or run 'source ~/.bashrc')${NC}"
fi

# Install tmux plugin manager if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "${YELLOW}Installing tmux plugin manager...${NC}"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    echo -e "${GREEN}✓ TPM installed${NC}"
    echo -e "${YELLOW}Remember to press 'prefix + I' in tmux to install plugins${NC}"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Reload your shell: source ~/.bashrc"
echo "2. Start tmux and press 'prefix + I' to install plugins"
echo "3. Run 'pomodoro' to start the timer"