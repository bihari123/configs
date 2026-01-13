# 🛠️ My Development Environment Configuration

Personal dotfiles and development environment setup for Linux (Ubuntu, Arch, RHEL).

## ⚡ Quick Setup on New Machine

```bash
git clone <YOUR_REPO_URL> ~/configs
cd ~/configs
./bootstrap.sh
```

**That's it!** The script will:
- ✅ Detect your Linux distribution
- ✅ Install all modern CLI tools
- ✅ Set up Docker & Kubernetes tools
- ✅ Configure shell with auto-suggestions
- ✅ Link all configuration files
- ✅ Install everything you need

**Full documentation:** [BOOTSTRAP.md](./BOOTSTRAP.md)

---

## 📦 What's Included

### Shell & Terminal
- **bash** with auto-suggestions (ble.sh) and syntax highlighting
- **oh-my-posh** dark colorblind-friendly prompt theme
- **tmux** with Zellij-style keybindings and auto-save sessions
- **alacritty** terminal with GitHub Dark theme

### Modern CLI Tools
- **bat** (cat with syntax highlighting)
- **eza** (modern ls with icons and git integration)
- **ripgrep** (fast grep)
- **fd** (fast find)
- **fzf** (fuzzy finder)
- **zoxide** (smart cd)
- **lazygit** (git TUI)
- **btop** (system monitor)
- **dust** (disk usage)
- **duf** (disk free)

### Container & Kubernetes
- **Docker** + **Docker Compose**
- **lazydocker** (Docker TUI)
- **kubectl** (Kubernetes CLI)
- **minikube** (local Kubernetes)
- **k9s** (Kubernetes TUI)

### Development
- **neovim** (with AstroNvim)
- **git** (with delta pager)
- **NVM** (Node Version Manager)

### Custom Scripts
- `bin/pomodoro` - Pomodoro timer with 7-segment display
- `bin/block-social-media` - Social media blocker
- `bin/tmux-session-menu` - Interactive tmux session manager
- `bin/install-docker-k8s-tools.sh` - Docker/K8s tools installer
- `taskquest/` - Gamified task manager TUI (Rust)
- `whisper-voice-to-text/` - Voice-to-text service

---

## 📂 Repository Structure

```
configs/
├── bootstrap.sh                    # Main installation script
├── BOOTSTRAP.md                    # Detailed bootstrap documentation
│
├── bashrc                          # Bash configuration
├── .bash_aliases                   # 60+ modern aliases & functions
├── .gitconfig                      # Git configuration
├── .inputrc                        # Readline configuration
│
├── alacritty/
│   └── alacritty.toml             # Terminal emulator config
│
├── tmux/
│   ├── tmux.conf                  # Tmux configuration
│   └── keyboard-shortcuts.md      # Tmux shortcuts reference
│
├── nvim/                          # Neovim configuration
│   └── lua/plugins/
│
├── oh-my-posh/
│   └── dark-colorblind.omp.json  # Prompt theme
│
├── k9s/
│   ├── config.yaml               # k9s configuration
│   └── skins/
│       └── github-dark.yaml      # k9s theme
│
├── lazydocker/
│   └── config.yml                # lazydocker configuration
│
├── bin/                           # Custom scripts
│   ├── install-docker-k8s-tools.sh
│   ├── pomodoro
│   ├── block-social-media
│   ├── tmux-session-menu
│   └── ...
│
├── taskquest/                     # Gamified task manager
└── whisper-voice-to-text/        # Voice transcription
```

---

## 🚀 Installation Options

### Interactive (Recommended)
```bash
./bootstrap.sh
```
Choose from Full, Minimal, or Custom installation.

### Automated Full Install
```bash
./bootstrap.sh --full
```
Installs everything without prompts.

### Minimal Install
```bash
./bootstrap.sh --minimal
```
CLI tools and configs only (no Docker/K8s).

---

## 🎨 Theme

Everything uses **GitHub Dark** color scheme for consistency:
- Terminal
- Tmux
- Oh-my-posh
- k9s
- lazydocker
- FZF
- Bat

---

## 🔑 Quick Reference

### Most Used Aliases

```bash
# Navigation
..          # cd ..
zi          # Interactive directory jump

# Git
lg          # lazygit
gst         # git status
ga/gc/gp    # add/commit/push

# Docker
lzd         # lazydocker
dps         # docker ps
dcu/dcud    # docker-compose up (detached)
dsh         # Shell into container

# Kubernetes
k9          # k9s
kgp         # kubectl get pods
kshell      # Shell into pod

# Files
frg         # Search with preview
ll/la/lt    # eza variations
cat         # bat (with highlighting)

# System
btop        # System monitor
```

### Tmux (Prefix: Ctrl+g)

```bash
# Panes
Alt+h/j/k/l     # Navigate panes
Alt+n/d         # Split panes
Alt+x           # Close pane

# Windows
Alt+t           # New window
Alt+w           # Close window
Alt+[/]         # Previous/Next window
Alt+1-9         # Jump to window

# Sessions
Alt+s           # Session selector
Ctrl+g, Ctrl+s  # Save session
```

Full reference: [tmux/keyboard-shortcuts.md](./tmux/keyboard-shortcuts.md)

---

## 📚 Documentation

- **Bootstrap Guide**: [BOOTSTRAP.md](./BOOTSTRAP.md) - Detailed installation guide
- **Tmux Shortcuts**: [tmux/keyboard-shortcuts.md](./tmux/keyboard-shortcuts.md)
- **TaskQuest**: [taskquest/README.md](./taskquest/README.md)

---

## 🐛 Troubleshooting

**Command not found after install:**
```bash
source ~/.bashrc
```

**Docker permission denied:**
```bash
newgrp docker  # OR logout/login
```

**k9s plugin errors:**
Normal if no Kubernetes cluster configured. Install kubectl and minikube.

**Missing icons:**
Install a Nerd Font (FiraCode Nerd Font recommended).

More troubleshooting: [BOOTSTRAP.md#troubleshooting](./BOOTSTRAP.md#troubleshooting)

---

## 🔄 Updating

```bash
cd ~/configs
git pull
./bootstrap.sh --full  # Re-run to apply updates
```

---

## 💡 Philosophy

This configuration prioritizes:
- **Terminal-first workflow** - Everything accessible from the command line
- **Modern tools** - Rust/Go-based replacements for legacy Unix tools
- **Consistent theming** - GitHub Dark everywhere
- **Productivity** - FZF integration, smart navigation, auto-suggestions
- **Portability** - One script works on Ubuntu, Arch, and RHEL
- **Gamification** - TaskQuest for motivation

---

## 🤝 Contributing

Contributions welcome! Feel free to:
- Report issues
- Suggest improvements
- Add support for more distributions
- Share your customizations

---

## 📄 License

MIT License - Use freely!

---

**Made with ❤️ for terminal enthusiasts**

```
 ╔═══════════════════════════════════════╗
 ║  "The command line is where the      ║
 ║   magic happens"                     ║
 ╚═══════════════════════════════════════╝
```
