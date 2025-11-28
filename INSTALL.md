# Installation Guide

## Quick Install

This script installs **all** tools and dependencies your workflow requires with the **latest stable versions**.

### What Gets Installed

#### Modern CLI Tools
- **bat** - cat replacement with syntax highlighting (latest)
- **eza** - modern ls replacement with git integration (latest)
- **ripgrep (rg)** - fast recursive search (latest)
- **fd** - fast find replacement (latest)
- **fzf** - fuzzy finder (latest)
- **lazygit** - terminal UI for git (latest)
- **btop** - system monitor (latest)
- **dust** - disk usage analyzer (latest)
- **duf** - disk usage/free utility (latest)

#### Shell Enhancements
- **zoxide** - smart directory jumper (latest)
- **oh-my-posh** - beautiful prompt (latest)
- **ble.sh** - bash auto-suggestions and syntax highlighting (latest)
- **sesh** - tmux session manager (latest)

#### Terminal & Display
- **tmux** - terminal multiplexer (latest from repos)
- **alacritty** - GPU-accelerated terminal (latest)
- **FiraCode Nerd Font** - font with icons (latest)
- **Tmux Plugin Manager (TPM)** - for tmux plugins (latest)

#### Programming Languages
- **Rust** - latest stable via rustup
- **Go (Golang)** - latest stable
- **Node.js** - latest LTS via NVM
- **Python 3** - system version + pyenv + poetry

#### Version Managers
- **NVM** - Node Version Manager (latest)
- **pyenv** - Python version manager (latest)
- **rustup** - Rust toolchain manager (latest)

#### Git Tools
- **git** - version control (system version)
- **lazygit** - git TUI (latest)
- **git-delta** - better git diffs (latest)

#### Container Tools
- **Docker** - container runtime (latest stable)
- **Docker Compose** - multi-container orchestration (latest)
- **lazydocker** - Docker TUI (latest)

#### Kubernetes Tools
- **kubectl** - Kubernetes CLI (latest stable)
- **helm** - Kubernetes package manager (latest)
- **minikube** - local Kubernetes (latest)
- **kind** - Kubernetes in Docker (latest)
- **k9s** - Kubernetes TUI (latest)

#### Configurations
All your dotfiles will be symlinked:
- `.bashrc` - enhanced bash configuration
- `.bash_aliases` - 95+ aliases and functions
- `.inputrc` - readline configuration
- `.gitconfig` - git configuration
- `.ripgreprc` - ripgrep defaults
- `tmux.conf` - tmux configuration with plugins
- `alacritty.toml` - terminal configuration
- `oh-my-posh` theme - prompt theme
- `k9s` config - Kubernetes UI config
- `lazydocker` config - Docker UI config
- All scripts in `bin/` directory

---

## Installation

### Prerequisites

- Ubuntu/Debian, Arch/Manjaro, or RHEL/Fedora/CentOS
- Internet connection
- sudo access

### Run the Installation

```bash
cd ~/configs
sudo bash install-everything.sh
```

### What Happens

1. **Detects your Linux distribution** - Automatically configures the right package manager
2. **Installs base packages** - build-essential, git, curl, wget, etc.
3. **Installs Rust** - via rustup (latest stable)
4. **Installs modern CLI tools** - all the latest versions from GitHub releases
5. **Installs programming languages** - Go, Node.js (LTS), Python tools
6. **Installs terminal tools** - Alacritty, tmux, fonts
7. **Installs container tools** - Docker, lazydocker
8. **Installs Kubernetes tools** - kubectl, helm, minikube, kind, k9s
9. **Sets up all configurations** - Symlinks your dotfiles
10. **Updates your bashrc** - Ensures all paths are configured

### Installation Time

- **Minimal system**: ~10-15 minutes
- **Full install**: ~20-30 minutes (depending on internet speed)

---

## After Installation

### 1. Reload Your Shell

```bash
exec bash
```

### 2. Install Tmux Plugins

Start tmux and install plugins:

```bash
tmux
# Press Ctrl+g then Shift+I (capital i)
```

### 3. Configure Git

Set your git user info:

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### 4. Docker Group (Important!)

If you installed Docker, **logout and login** for the docker group to take effect.

```bash
# Check if you're in docker group
groups | grep docker

# If not, logout and login again
```

### 5. Test Your Installation

Try these commands:

```bash
# Modern CLI tools
ll              # eza with icons
bat --version   # syntax highlighting cat
btop            # system monitor
frg "search"    # search with preview

# Git
lg              # lazygit TUI

# Docker (after logout/login)
docker ps       # list containers
lzd             # lazydocker TUI

# Kubernetes (if you set up a cluster)
k9s             # Kubernetes TUI

# Directory jumping
cd /some/path
cd ~
cd -            # go back (zoxide smart cd)
zi              # interactive directory jump

# Tmux session manager
tmux            # start tmux
```

---

## Version Information

All tools are installed with their **latest stable versions** as of the installation date:

- Tools from GitHub Releases: **Latest version** via GitHub API
- System packages: **Latest available** in your distribution's repos
- Rust tools: **Latest stable** via cargo
- Go: **Latest stable** from go.dev
- Node.js: **Latest LTS** via NVM

### Checking Versions

```bash
# CLI Tools
bat --version
eza --version
rg --version
fd --version
fzf --version

# Languages
rustc --version
go version
node --version
python3 --version

# Container/K8s
docker --version
kubectl version --client
helm version
k9s version
```

---

## Troubleshooting

### Script Fails

If the script fails partway through, you can safely run it again. It checks if tools are already installed and skips them.

### Permission Issues

Make sure you run with `sudo`:

```bash
sudo bash install-everything.sh
```

### Docker Group

If docker commands fail after installation:

```bash
# Logout and login again, or run:
newgrp docker
```

### Tmux Plugins Not Installing

```bash
# Make sure TPM is installed
ls ~/.tmux/plugins/tpm

# Start tmux and press Ctrl+g + Shift+I
```

### Fonts Not Showing Icons

Make sure your terminal uses **FiraCode Nerd Font**:

- Alacritty: Already configured in `alacritty.toml`
- Other terminals: Set font to "FiraCode Nerd Font" in settings

### Bashrc Not Updated

Reload your shell:

```bash
exec bash
# or
source ~/.bashrc
```

---

## Uninstallation

To revert to your previous configuration:

1. Your old configs are backed up in `~/.config-backup-TIMESTAMP/`
2. Remove symlinks and restore backups:

```bash
# Find your backup
ls -la ~/ | grep config-backup

# Restore (example)
cp ~/.config-backup-20250128-143022/.bashrc ~/.bashrc
```

3. Remove installed tools (optional):

```bash
# System packages via package manager
# Language version managers
rm -rf ~/.cargo
rm -rf ~/.nvm
rm -rf ~/.pyenv

# Rust tools
cargo uninstall <tool-name>

# Docker
sudo apt remove docker-ce docker-ce-cli containerd.io  # Ubuntu/Debian
```

---

## Customization

All configuration files are symlinked from `~/configs/`, so you can edit them:

```bash
# Edit bashrc
nvim ~/configs/bashrc

# Edit aliases
nvim ~/configs/.bash_aliases

# Edit tmux config
nvim ~/configs/tmux/tmux.conf

# Changes take effect immediately (for symlinked files)
```

---

## Updates

To update tools in the future:

```bash
# Rust
rustup update

# Cargo tools
cargo install-update -a  # requires cargo-update

# Go
# Download new version from go.dev

# Node.js
nvm install --lts
nvm use --lts

# System packages
sudo apt update && sudo apt upgrade  # Ubuntu/Debian
sudo pacman -Syu                     # Arch
sudo dnf upgrade                     # Fedora

# Update GitHub release tools
# Re-run the install script or manually update
```

---

## Support

For issues with:
- **This script**: Check the script logs during installation
- **Individual tools**: Refer to their official documentation
- **Configuration**: Edit files in `~/configs/`

---

**Installation script version**: 1.0
**Last updated**: 2025-01-28
**Tested on**: Ubuntu 22.04, Arch Linux, Fedora 39
