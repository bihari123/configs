#!/bin/bash

set -e  # Exit on error

echo "=================================="
echo "Shell Tools Installation Script"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

# Update package lists
echo -e "${YELLOW}Updating package lists...${NC}"
sudo apt update

# Install basic tools via apt
echo ""
echo -e "${YELLOW}Installing basic tools via apt...${NC}"

# Build essentials
if ! command_exists gcc; then
    sudo apt install -y build-essential
    print_status "build-essential installed"
else
    echo -e "${GREEN}✓${NC} build-essential already installed"
fi

# curl and wget
if ! command_exists curl; then
    sudo apt install -y curl
    print_status "curl installed"
else
    echo -e "${GREEN}✓${NC} curl already installed"
fi

# git
if ! command_exists git; then
    sudo apt install -y git
    print_status "git installed"
else
    echo -e "${GREEN}✓${NC} git already installed"
fi

# Install fd (fd-find)
echo ""
echo -e "${YELLOW}Installing fd...${NC}"
if ! command_exists fd && ! command_exists fdfind; then
    sudo apt install -y fd-find
    # Create symlink if fd doesn't exist
    if ! command_exists fd && command_exists fdfind; then
        mkdir -p ~/.local/bin
        ln -sf $(which fdfind) ~/.local/bin/fd
    fi
    print_status "fd installed"
else
    echo -e "${GREEN}✓${NC} fd already installed"
fi

# Install ripgrep
echo ""
echo -e "${YELLOW}Installing ripgrep...${NC}"
if ! command_exists rg; then
    sudo apt install -y ripgrep
    print_status "ripgrep installed"
else
    echo -e "${GREEN}✓${NC} ripgrep already installed"
fi

# Install bat
echo ""
echo -e "${YELLOW}Installing bat...${NC}"
if ! command_exists bat && ! command_exists batcat; then
    sudo apt install -y bat
    # Create symlink if bat doesn't exist
    if ! command_exists bat && command_exists batcat; then
        mkdir -p ~/.local/bin
        ln -sf $(which batcat) ~/.local/bin/bat
    fi
    print_status "bat installed"
else
    echo -e "${GREEN}✓${NC} bat already installed"
fi

# Install fzf
echo ""
echo -e "${YELLOW}Installing fzf...${NC}"
if ! command_exists fzf; then
    sudo apt install -y fzf
    print_status "fzf installed"
else
    echo -e "${GREEN}✓${NC} fzf already installed"
fi

# Install eza (modern ls replacement)
echo ""
echo -e "${YELLOW}Installing eza...${NC}"
if ! command_exists eza; then
    # eza is not in default repos, need to install from GitHub
    if ! command_exists cargo; then
        echo -e "${YELLOW}  Installing via cargo (will install rust first if needed)${NC}"
        # Will be installed with rust below
    else
        cargo install eza
        print_status "eza installed via cargo"
    fi
else
    echo -e "${GREEN}✓${NC} eza already installed"
fi

# Install zoxide
echo ""
echo -e "${YELLOW}Installing zoxide...${NC}"
if ! command_exists zoxide; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    print_status "zoxide installed"
else
    echo -e "${GREEN}✓${NC} zoxide already installed"
fi

# Install Rust (for cargo)
echo ""
echo -e "${YELLOW}Installing Rust...${NC}"
if ! command_exists cargo; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    print_status "Rust installed"

    # Now install eza if it wasn't installed
    if ! command_exists eza; then
        cargo install eza
        print_status "eza installed via cargo"
    fi
else
    echo -e "${GREEN}✓${NC} Rust already installed"
fi

# Install NVM (Node Version Manager)
echo ""
echo -e "${YELLOW}Installing NVM...${NC}"
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    print_status "NVM installed"
else
    echo -e "${GREEN}✓${NC} NVM already installed"
fi

# Install Neovim
echo ""
echo -e "${YELLOW}Installing Neovim...${NC}"
if ! command_exists nvim; then
    sudo apt install -y neovim
    print_status "Neovim installed"
else
    echo -e "${GREEN}✓${NC} Neovim already installed"
fi

# Install Oh My Posh
echo ""
echo -e "${YELLOW}Installing Oh My Posh...${NC}"
if ! command_exists oh-my-posh; then
    curl -s https://ohmyposh.dev/install.sh | bash -s
    print_status "Oh My Posh installed"

    # Download the theme if it doesn't exist
    if [ ! -f ~/.config/oh-my-posh-dark-colorblind.omp.json ]; then
        echo -e "${YELLOW}  Downloading dark colorblind theme...${NC}"
        mkdir -p ~/.config
        curl -s https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json \
            -o ~/.config/oh-my-posh-dark-colorblind.omp.json
        print_status "Oh My Posh theme downloaded"
    fi
else
    echo -e "${GREEN}✓${NC} Oh My Posh already installed"
fi

# Install Go (if not present)
echo ""
echo -e "${YELLOW}Checking Go installation...${NC}"
if ! command_exists go; then
    echo -e "${YELLOW}  Go not found. Download from: https://go.dev/dl/${NC}"
    echo -e "${YELLOW}  Or run: wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz${NC}"
    echo -e "${YELLOW}  Then: sudo tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz${NC}"
else
    echo -e "${GREEN}✓${NC} Go already installed ($(go version))"
fi

# Create ripgrep config if it doesn't exist
echo ""
echo -e "${YELLOW}Setting up ripgrep config...${NC}"
if [ ! -f ~/.ripgreprc ]; then
    cat > ~/.ripgreprc << 'EOF'
# Default options for ripgrep
--smart-case
--hidden
--glob=!.git/*
--glob=!node_modules/*
--glob=!target/*
--glob=!.cache/*
EOF
    print_status "ripgrep config created"
else
    echo -e "${GREEN}✓${NC} ripgrep config already exists"
fi

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Run: source ~/.bashrc"
echo "2. Restart your terminal"
echo ""
echo "Installed tools:"
echo "  - fd (fast find alternative)"
echo "  - ripgrep (fast grep alternative)"
echo "  - bat (cat with syntax highlighting)"
echo "  - fzf (fuzzy finder)"
echo "  - eza (modern ls)"
echo "  - zoxide (smart cd)"
echo "  - neovim (modern vim)"
echo "  - oh-my-posh (prompt theme)"
echo "  - rust/cargo"
echo "  - nvm (node version manager)"
echo ""
