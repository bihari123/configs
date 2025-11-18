# 🚀 Universal Linux Bootstrap Script

**One command to set up your entire development environment on any Linux machine.**

Supports: **Ubuntu/Debian**, **Arch/Manjaro**, **RHEL/Fedora/CentOS**

---

## ⚡ Quick Start

### On a Fresh Machine

```bash
# 1. Clone this repository
git clone https://github.com/YOUR_USERNAME/configs.git ~/configs
cd ~/configs

# 2. Run the bootstrap script
./bootstrap.sh
```

That's it! The interactive menu will guide you through the rest.

### Non-Interactive Installation

```bash
# Full installation (everything)
./bootstrap.sh --full

# Minimal installation (CLI tools + configs only)
./bootstrap.sh --minimal
```

---

## 📦 What Gets Installed

### Full Installation Includes:

#### **Modern CLI Tools**
- ✅ **bat** - Cat with syntax highlighting
- ✅ **eza** - Modern ls replacement with git integration
- ✅ **ripgrep** - Ultra-fast grep alternative
- ✅ **fd** - Simple, fast alternative to find
- ✅ **fzf** - Fuzzy finder for command-line
- ✅ **zoxide** - Smart cd that learns your habits
- ✅ **lazygit** - Beautiful git TUI
- ✅ **btop/bottom** - Modern system monitor
- ✅ **dust** - Intuitive du replacement
- ✅ **duf** - Better df alternative

#### **Shell Enhancements**
- ✅ **ble.sh** - Bash auto-suggestions & syntax highlighting (like zsh)
- ✅ **oh-my-posh** - Beautiful, customizable prompt
- ✅ All your custom bash aliases and functions

#### **Development Tools**
- ✅ **tmux** - Terminal multiplexer with custom config
- ✅ **neovim** - Modern vim with your AstroNvim setup
- ✅ **git** - With your custom git config and delta pager
- ✅ **NVM** - Node Version Manager

#### **Containerization & Orchestration**
- ✅ **Docker** - Container runtime
- ✅ **Docker Compose** - Multi-container orchestration
- ✅ **lazydocker** - Beautiful Docker TUI
- ✅ **kubectl** - Kubernetes command-line tool
- ✅ **minikube** - Local Kubernetes cluster
- ✅ **k9s** - Kubernetes TUI

#### **Configuration Files**
- ✅ `.bashrc` - Enhanced bash configuration
- ✅ `.bash_aliases` - 60+ modern aliases & functions
- ✅ `.gitconfig` - Git settings with delta integration
- ✅ `.inputrc` - Better readline behavior
- ✅ `.ripgreprc` - Ripgrep defaults
- ✅ `tmux.conf` - Tmux with Zellij-style keybindings
- ✅ `alacritty.toml` - Terminal emulator config
- ✅ `nvim/` - Neovim configuration
- ✅ `k9s/` - k9s configuration with GitHub Dark theme
- ✅ `lazydocker/` - lazydocker configuration
- ✅ Custom scripts in `bin/`

---

## 🎯 Installation Modes

### 1. **Interactive Mode** (Recommended for first-time setup)
```bash
./bootstrap.sh
```

Choose from:
- **Full Installation** - Everything (recommended)
- **Minimal Installation** - CLI tools + configs only (no Docker/K8s)
- **Custom Installation** - Pick and choose components

### 2. **Automated Full Install**
```bash
./bootstrap.sh --full
```

Installs everything without prompts. Perfect for scripting or CI/CD.

### 3. **Automated Minimal Install**
```bash
./bootstrap.sh --minimal
```

Installs only:
- Modern CLI tools
- Shell enhancements (ble.sh, zoxide, oh-my-posh)
- Configuration files
- Tmux setup

Skips: Docker, Kubernetes, NVM

---

## 📋 Requirements

### Minimum Requirements:
- **Linux** (Ubuntu 20.04+, Arch, RHEL 8+, Fedora 35+, or derivatives)
- **bash** 4.0+
- **git** (for cloning the repo)
- **curl** or **wget**
- **sudo** access (for package installation)
- Internet connection

### Storage Requirements:
- **Minimal**: ~500 MB
- **Full**: ~2-3 GB (includes Docker, K8s tools)

---

## 🔧 What the Script Does

### 1. **Distribution Detection**
Automatically detects your Linux distribution and uses the appropriate package manager:
- **Ubuntu/Debian**: `apt`
- **Arch/Manjaro**: `pacman`
- **RHEL/Fedora/CentOS**: `dnf` or `yum`

### 2. **Package Installation**
- Updates package lists
- Installs build essentials
- Installs tools from official repos when available
- Downloads and installs binaries for tools not in repos

### 3. **Configuration Linking**
- Backs up your existing configs to `~/.config-backup-TIMESTAMP/`
- Creates symlinks from `~/configs/` to your home directory
- Preserves your existing setup (just in case)

### 4. **Tool Setup**
- Installs Rust and Cargo (if needed)
- Sets up NVM for Node.js management
- Configures Docker (adds you to docker group)
- Sets up Tmux Plugin Manager (TPM)
- Creates k9s and lazydocker configurations

### 5. **Path Configuration**
- Ensures `~/.local/bin` is in PATH
- Ensures `~/bin` is in PATH
- Sources bash configuration

---

## 🎨 Customization

### Theme
All tools use the **GitHub Dark** color scheme:
- Terminal (Alacritty)
- Tmux status bar
- Oh-my-posh prompt
- k9s
- lazydocker
- FZF
- Bat syntax highlighting

### Modifying the Bootstrap

Edit `bootstrap.sh` to:
- Skip certain package installations
- Add your own tools
- Change installation directories
- Modify package lists

---

## 🚦 Post-Installation Steps

### 1. **Reload Your Shell**
```bash
source ~/.bashrc
# or
exec bash
```

### 2. **Install Tmux Plugins**
```bash
tmux
# Press: Ctrl+g then Shift+I
```

### 3. **Install a Nerd Font**
For oh-my-posh and eza icons to work properly:

**Ubuntu/Debian:**
```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip
unzip FiraCode.zip
fc-cache -fv
```

**Arch:**
```bash
yay -S ttf-firacode-nerd
```

Then configure your terminal to use "FiraCode Nerd Font"

### 4. **Start Using Docker** (if installed)
```bash
# Logout and login to apply docker group
# OR run: newgrp docker

# Test Docker
docker run hello-world

# Launch lazydocker
lzd
```

### 5. **Setup Kubernetes** (optional)
```bash
# Start minikube cluster
minikube start

# Verify
kubectl get nodes

# Launch k9s
k9s
```

---

## 🔑 Key Aliases & Commands

### Navigation
```bash
..          # cd ..
...         # cd ../..
zi          # Interactive directory jump (zoxide + fzf)
```

### Git
```bash
lg          # lazygit
gst         # git status
ga          # git add
gc          # git commit
gp          # git push
```

### Docker
```bash
lzd         # lazydocker TUI
dps         # docker ps
dcu         # docker-compose up
dcud        # docker-compose up -d
dsh <name>  # Shell into container
dclean      # Clean up all Docker resources
```

### Kubernetes
```bash
k9          # k9s TUI
k           # kubectl
kgp         # kubectl get pods
kshell      # Shell into pod
ksetns      # Set namespace
```

### Files & Search
```bash
frg         # Search with ripgrep + fzf + preview
ll          # eza -l (detailed list)
lt          # eza --tree
cat         # bat (syntax highlighting)
```

### System
```bash
btop        # System monitor
duf         # Disk usage
dust        # Directory size
```

---

## 🐛 Troubleshooting

### "Command not found" after installation
```bash
source ~/.bashrc
# OR
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
```

### Docker permission denied
```bash
# Logout and login again, OR
newgrp docker
```

### k9s "plugins load failed"
This is normal if you don't have a Kubernetes cluster configured. Install kubectl and set up a cluster (minikube).

### ble.sh slows down shell startup
Add to `.bashrc` before ble.sh source:
```bash
bleopt exec_elapsed_mark='hide'
```

### Fonts not showing icons
Install a Nerd Font and configure your terminal emulator to use it.

---

## 📦 Updating

### Update the Repository
```bash
cd ~/configs
git pull
```

### Re-run Bootstrap
```bash
./bootstrap.sh --full
```

The script is idempotent - it won't reinstall existing tools, just update configs.

---

## 🗑️ Uninstalling

### Remove Symlinks
```bash
rm ~/.bashrc ~/.bash_aliases ~/.gitconfig ~/.inputrc ~/.ripgreprc
rm -rf ~/.config/tmux ~/.config/alacritty ~/.config/nvim
rm -rf ~/.config/k9s ~/.config/lazydocker
```

### Restore Backups
```bash
# Find your backup
ls -la ~/.config-backup-*/

# Restore
cp ~/.config-backup-TIMESTAMP/.bashrc ~/
cp ~/.config-backup-TIMESTAMP/.bash_aliases ~/
# ... etc
```

### Remove Installed Tools
Ubuntu/Debian:
```bash
sudo apt remove bat eza ripgrep fd-find fzf tmux neovim
rm -rf ~/.local/bin/{lazydocker,k9s,kubectl,minikube,lazygit}
```

Arch:
```bash
sudo pacman -R bat eza ripgrep fd fzf tmux neovim
```

---

## 🤝 Contributing

Found a bug? Want to add support for another distro?

1. Fork the repo
2. Make your changes
3. Test on a fresh VM
4. Submit a PR

---

## 📄 License

MIT License - Do whatever you want with it!

---

## ⭐ Tips

- Run `./bootstrap.sh --minimal` first to test, then `--full` later
- The script is idempotent - safe to run multiple times
- All configs are symlinked, so updates via `git pull` apply immediately
- Backup your existing configs before running (script does this automatically)
- Use `tmux` immediately after install for best experience

---

## 🎓 Learning Resources

- **Tmux**: `man tmux` or `~/configs/tmux/keyboard-shortcuts.md`
- **k9s**: Press `?` inside k9s for help
- **lazydocker**: Press `?` inside lazydocker for help
- **FZF**: `man fzf` or Ctrl+R for history search
- **Oh-my-posh**: https://ohmyposh.dev/docs

---

**Enjoy your supercharged terminal! 🚀**
