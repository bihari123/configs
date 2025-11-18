# 📦 Complete Installation Manifest

This document lists **exactly** what the bootstrap script installs.

## ✅ YES - The Bootstrap Script DOES Install Docker & Kubernetes!

---

## Full Installation Mode (`./bootstrap.sh --full`)

### 🐳 Container Tools

#### Docker
- **What**: Docker Engine + Docker Compose
- **How**:
  - **Ubuntu/Debian**: Official `get.docker.com` script → installs Docker CE + Compose plugin
  - **Arch/Manjaro**: `pacman -S docker docker-compose`
  - **RHEL/Fedora**: `dnf install docker-ce docker-ce-cli containerd.io docker-compose-plugin`
- **Post-install**:
  - ✅ Service enabled and started (`systemctl enable docker && systemctl start docker`)
  - ✅ User added to `docker` group (logout/login required)
- **Verification**: `docker --version && docker compose version`

#### lazydocker
- **What**: Beautiful TUI for Docker
- **How**: Downloaded from GitHub releases to `~/.local/bin/lazydocker`
- **Verification**: `lazydocker --version`
- **Alias**: `lzd`

---

### ☸️ Kubernetes Tools (ALL Installed!)

#### 1. kubectl
- **What**: Kubernetes command-line tool
- **How**: Downloaded from `dl.k8s.io` (latest stable) to `~/.local/bin/kubectl`
- **Verification**: `kubectl version --client`
- **Alias**: `k`

#### 2. helm
- **What**: Kubernetes package manager
- **How**: Installed via official `get-helm-3` script
- **Verification**: `helm version`

#### 3. minikube
- **What**: Local Kubernetes cluster (runs in VM or Docker)
- **How**: Downloaded from Google Storage to `~/.local/bin/minikube`
- **Verification**: `minikube version`
- **Usage**: `minikube start` to create cluster

#### 4. kind
- **What**: Kubernetes in Docker (lightweight alternative to minikube)
- **How**: Downloaded from GitHub releases to `~/.local/bin/kind`
- **Verification**: `kind version`
- **Usage**: `kind create cluster` to create cluster

#### 5. k9s
- **What**: Beautiful Kubernetes TUI
- **How**: Downloaded from GitHub releases to `~/.local/bin/k9s`
- **Verification**: `k9s version`
- **Alias**: `k9`
- **Config**: `~/.config/k9s/config.yaml` (GitHub Dark theme)

#### 6. kubectx & kubens
- **What**: Tools for switching K8s contexts and namespaces
- **How**: Cloned from GitHub to `/opt/kubectx`, symlinked to `/usr/local/bin/`
- **Verification**: `kubectx --version && kubens --version`
- **Usage**:
  - `kubectx` - List/switch contexts
  - `kubens` - List/switch namespaces

---

### 🛠️ Modern CLI Tools

#### Installed from Package Managers:
- ✅ **bat** - Cat with syntax highlighting (`bat --version`)
- ✅ **eza** - Modern ls with icons (`eza --version`)
- ✅ **ripgrep** - Fast grep (`rg --version`)
- ✅ **fd** - Fast find (`fd --version`)
- ✅ **fzf** - Fuzzy finder (`fzf --version`)
- ✅ **tmux** - Terminal multiplexer (`tmux -V`)
- ✅ **neovim** - Modern vim (`nvim --version`)

#### Installed via Cargo (Rust):
- ✅ **bottom** (btm) - System monitor (`btm --version`)
- ✅ **du-dust** - Disk usage (`dust --version`)

#### Installed as Binaries:
- ✅ **duf** - Disk free utility (`duf --version`)
- ✅ **lazygit** - Git TUI (`lazygit --version`)
- ✅ **zoxide** - Smart cd (`zoxide --version`)

---

### 🐚 Shell Enhancements

#### ble.sh
- **What**: Bash auto-suggestions & syntax highlighting (like zsh)
- **How**: Cloned to `~/.local/share/blesh`, compiled and installed
- **Verification**: Check `~/.bashrc` for ble.sh source
- **Features**:
  - Auto-suggestions from history (gray text, press → to accept)
  - Syntax highlighting (green=valid, red=invalid)
  - Better completion

#### oh-my-posh
- **What**: Beautiful, customizable prompt
- **How**: Installed to `~/.local/bin/oh-my-posh`
- **Verification**: `oh-my-posh --version`
- **Theme**: `~/.config/oh-my-posh-dark-colorblind.omp.json`

#### zoxide
- **What**: Smart cd that learns your habits
- **How**: Installed via official script to `~/.local/bin/zoxide`
- **Verification**: `zoxide --version`
- **Usage**: `cd <partial-path>` or `zi` for interactive

---

### 📦 Development Tools

#### NVM (Node Version Manager)
- **What**: Manage multiple Node.js versions
- **How**: Installed to `~/.nvm`
- **Verification**: `nvm --version`
- **Usage**: `nvm install node` to install latest Node.js

#### Rust & Cargo
- **What**: Rust compiler and package manager
- **How**: Installed via `rustup`
- **Verification**: `cargo --version`

---

### ⚙️ Configuration Files (All Symlinked)

From `~/configs/` to home directory:

#### Shell Configs:
- ✅ `~/.bashrc` → `~/configs/bashrc`
- ✅ `~/.bash_aliases` → `~/configs/.bash_aliases`
- ✅ `~/.inputrc` → `~/configs/.inputrc`

#### Git Config:
- ✅ `~/.gitconfig` → `~/configs/.gitconfig` (with delta pager)
- ✅ `~/.ripgreprc` → `~/configs/.ripgreprc`

#### Terminal & Editors:
- ✅ `~/.config/tmux/tmux.conf` → `~/configs/tmux/tmux.conf`
- ✅ `~/.config/alacritty/alacritty.toml` → `~/configs/alacritty/alacritty.toml`
- ✅ `~/.config/nvim/` → `~/configs/nvim/`

#### Tool Configs:
- ✅ `~/.config/k9s/config.yaml` → `~/configs/k9s/config.yaml`
- ✅ `~/.config/k9s/skins/github-dark.yaml` → `~/configs/k9s/skins/github-dark.yaml`
- ✅ `~/.config/lazydocker/config.yml` → `~/configs/lazydocker/config.yml`
- ✅ `~/.config/oh-my-posh-dark-colorblind.omp.json` → `~/configs/oh-my-posh/dark-colorblind.omp.json`

#### Custom Scripts:
- ✅ All scripts from `~/configs/bin/` → `~/bin/`
  - `pomodoro`, `block-social-media`, `tmux-session-menu`, etc.

---

### 🔧 Tmux Plugins

#### Tmux Plugin Manager (TPM)
- **What**: Plugin manager for tmux
- **How**: Cloned to `~/.tmux/plugins/tpm`
- **Plugins configured** (installed on first Ctrl+g + I):
  - `tmux-sensible` - Sensible defaults
  - `tmux-yank` - Copy to system clipboard
  - `tmux-resurrect` - Save/restore sessions
  - `tmux-continuum` - Auto-save sessions
  - `tmux-logging` - Capture pane output

---

## Minimal Installation Mode (`./bootstrap.sh --minimal`)

Installs everything **EXCEPT**:
- ❌ Docker
- ❌ Kubernetes tools (kubectl, helm, minikube, kind, k9s, kubectx)
- ❌ NVM
- ❌ lazydocker

Still includes:
- ✅ All modern CLI tools (bat, eza, ripgrep, fd, fzf, lazygit, etc.)
- ✅ Shell enhancements (ble.sh, oh-my-posh, zoxide)
- ✅ All configuration files
- ✅ Tmux setup

---

## Custom Installation Mode

Interactive menu to choose:
1. Modern CLI tools
2. Zoxide
3. Oh-my-posh
4. NVM
5. **Docker** ✅
6. **Kubernetes tools** ✅
7. ble.sh
8. **lazydocker + k9s** ✅

---

## Verification Commands

After installation, verify everything is installed:

```bash
# Docker & Compose
docker --version
docker compose version
docker ps

# Kubernetes
kubectl version --client
helm version
minikube version
kind version
k9s version
kubectx
kubens

# TUIs
lazydocker --version
lazygit --version
k9s version

# CLI Tools
bat --version
eza --version
rg --version
fd --version
fzf --version
zoxide --version

# Shell
oh-my-posh --version
bash --version
echo $BLE_VERSION  # ble.sh

# Dev Tools
nvm --version
cargo --version
git --version
tmux -V
nvim --version
```

---

## Installation Locations

### System Packages
- Installed via package manager to system paths
- Examples: `/usr/bin/bat`, `/usr/bin/docker`

### User Binaries
- `~/.local/bin/` - kubectl, helm, minikube, kind, k9s, lazydocker, oh-my-posh, zoxide
- `~/bin/` - Custom scripts from configs repo
- `/usr/local/bin/` - kubectx, kubens (system-wide symlinks)

### Configurations
- `~/.config/` - All modern tool configs (tmux, nvim, k9s, alacritty, etc.)
- `~/` - Shell configs (.bashrc, .bash_aliases, .gitconfig, etc.)

### Data & Plugins
- `~/.tmux/plugins/` - Tmux plugins
- `~/.local/share/blesh/` - ble.sh installation
- `~/.nvm/` - NVM and Node.js versions
- `/opt/kubectx/` - kubectx/kubens source

---

## Summary: What Gets Installed

### ✅ YES - Docker Tools
1. Docker Engine
2. Docker Compose
3. lazydocker (TUI)

### ✅ YES - Kubernetes Tools (6 tools!)
1. kubectl (CLI)
2. helm (package manager)
3. minikube (local cluster)
4. kind (K8s in Docker)
5. k9s (TUI)
6. kubectx & kubens (context switcher)

### ✅ YES - Everything Else
- Modern CLI tools (10+ tools)
- Shell enhancements (3 tools)
- Development tools (tmux, neovim, git, NVM, Rust)
- All custom configurations
- 60+ bash aliases for Docker/K8s
- Custom scripts

---

## Distribution Support

The bootstrap script automatically detects and uses:

### Ubuntu/Debian
- Package manager: `apt`
- Docker: Official get.docker.com script
- All other tools: Binary downloads or cargo

### Arch/Manjaro
- Package manager: `pacman`
- Docker: Official repos + docker-compose package
- Many tools available in official repos

### RHEL/Fedora/CentOS
- Package manager: `dnf` or `yum`
- Docker: Official Docker CE repos
- All other tools: Binary downloads or cargo

---

## Total Installation Size

### Full Installation
- **Download**: ~1-2 GB
- **Installed**: ~3-4 GB (including Docker images)
- **Time**: 5-15 minutes (depending on internet speed)

### Minimal Installation
- **Download**: ~300-500 MB
- **Installed**: ~1 GB
- **Time**: 3-8 minutes

---

**Last Updated**: 2025-11-18
**Bootstrap Script Version**: 1.0
