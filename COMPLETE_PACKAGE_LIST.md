# 📦 Complete Package List - Every Single Thing Installed

## Base System Packages (Required for Building)

### Ubuntu/Debian:
```
build-essential
git
curl
wget
unzip
tar
gzip
make
gcc
g++
pkg-config
libssl-dev
software-properties-common
apt-transport-https
ca-certificates
gnupg
lsb-release
```

### Arch/Manjaro:
```
base-devel
git
curl
wget
unzip
tar
gzip
make
gcc
openssl
pkgconf
```

### RHEL/Fedora/CentOS:
```
@development-tools
git
curl
wget
unzip
tar
gzip
make
gcc
gcc-c++
openssl-devel
pkgconfig
```

---

## 🐳 Docker & Container Tools (3 Tools)

### 1. Docker Engine
- **Version:** Latest stable
- **Location:** `/usr/bin/docker`
- **Includes:** Docker daemon, CLI
- **Service:** `docker.service` (enabled & started)

### 2. Docker Compose
- **Version:** Latest (v2.x as plugin)
- **Ubuntu/Debian:** Installed via get.docker.com (compose plugin)
- **Arch:** Package: `docker-compose`
- **RHEL/Fedora:** Package: `docker-compose-plugin`
- **Command:** `docker compose` (v2) or `docker-compose` (v1)

### 3. lazydocker
- **Version:** Latest from GitHub releases
- **Location:** `~/.local/bin/lazydocker`
- **What:** Terminal UI for Docker
- **Alias:** `lzd`

---

## ☸️ Kubernetes Tools (6 Tools)

### 1. kubectl
- **Version:** Latest stable
- **Location:** `~/.local/bin/kubectl`
- **What:** Kubernetes command-line tool
- **Alias:** `k`

### 2. helm
- **Version:** Helm 3 (latest)
- **Location:** `/usr/local/bin/helm`
- **What:** Kubernetes package manager
- **Installed via:** Official get-helm-3 script

### 3. minikube
- **Version:** Latest
- **Location:** `~/.local/bin/minikube`
- **What:** Local Kubernetes cluster (runs in VM/Docker)
- **Requirements:** Docker or VirtualBox

### 4. kind
- **Version:** Latest from GitHub
- **Location:** `~/.local/bin/kind`
- **What:** Kubernetes in Docker
- **Requirements:** Docker

### 5. k9s
- **Version:** Latest from GitHub
- **Location:** `~/.local/bin/k9s`
- **What:** Kubernetes TUI (Terminal UI)
- **Alias:** `k9`

### 6. kubectx & kubens
- **Version:** Latest from GitHub
- **Location:** `/opt/kubectx/` (source), `/usr/local/bin/` (symlinks)
- **What:**
  - `kubectx` - Switch Kubernetes contexts
  - `kubens` - Switch Kubernetes namespaces

---

## 💻 Programming Languages & Runtimes (4 Systems)

### 1. Golang
- **Version:** Latest stable from go.dev
- **Location:** `/usr/local/go/`
- **Binary:** `/usr/local/go/bin/go`
- **GOPATH:** `$HOME/go`
- **What:** Go programming language compiler & tools
- **Environment:**
  - `PATH=$PATH:/usr/local/go/bin`
  - `PATH=$PATH:$HOME/go/bin`

### 2. Rust + Cargo
- **Version:** Latest stable
- **Location:** `~/.cargo/` and `~/.rustup/`
- **Installed via:** rustup
- **What:**
  - `rustc` - Rust compiler
  - `cargo` - Rust package manager
  - Used to build: bottom, du-dust, and other modern CLI tools
- **Environment:** `source "$HOME/.cargo/env"`

### 3. Node.js (via NVM)
- **NVM Version:** v0.39.7
- **Location:** `~/.nvm/`
- **What:** Node Version Manager
- **Usage:** `nvm install node` to install Node.js
- **Commands:**
  - `nvm` - Version manager
  - `node` - JavaScript runtime (after install)
  - `npm` - Node package manager (after install)

### 4. Python
- **Version:** System Python (3.x)
- **Package:** `python3-pip` (Ubuntu/Debian)
- **Location:** `/usr/bin/python3`
- **What:** Python interpreter + pip
- **Already installed on most systems**

---

## 🖥️ Terminal & Display (3 Components)

### 1. Alacritty
- **Version:** Latest available
- **Ubuntu/Debian:** From PPA or compiled via cargo
- **Arch:** Package: `alacritty`
- **RHEL/Fedora:** Package or cargo
- **Location:** `/usr/bin/alacritty` or `~/.cargo/bin/alacritty`
- **What:** GPU-accelerated terminal emulator
- **Config:** `~/.config/alacritty/alacritty.toml`

### 2. FiraCode Nerd Font
- **Version:** v3.1.1
- **Location:** `~/.local/share/fonts/FiraCode/`
- **What:** Font with programming ligatures and Nerd Font icons
- **Files:** ~50 font files (.ttf)
- **Includes:**
  - FiraCode Nerd Font (Regular, Bold, Italic, etc.)
  - Powerline symbols
  - Font Awesome icons
  - Material Design icons
  - Weather icons
  - And more (3000+ icons)

### 3. Tmux
- **Version:** System package
- **Location:** `/usr/bin/tmux`
- **What:** Terminal multiplexer
- **Config:** `~/.config/tmux/tmux.conf`
- **Plugins:** See "Tmux Plugins" section below

---

## 🛠️ Modern CLI Tools (15+ Tools)

### 1. bat
- **Version:** Latest (v0.24.0 or newer)
- **Ubuntu/Debian:** Binary .deb from GitHub
- **Arch:** Package: `bat`
- **What:** Cat with syntax highlighting
- **Replaces:** `cat`
- **Alias:** `cat='bat --style=auto'`

### 2. eza
- **Version:** Latest
- **Ubuntu/Debian:** From gierens.de repo
- **Arch:** Package: `eza`
- **RHEL/Fedora:** Binary from GitHub
- **What:** Modern ls with icons and git integration
- **Replaces:** `ls`
- **Aliases:**
  - `ls='eza --icons --group-directories-first'`
  - `ll='eza -l --icons --group-directories-first --git'`
  - `la='eza -la --icons --group-directories-first --git'`
  - `lt='eza --tree --level=2 --icons'`

### 3. ripgrep (rg)
- **Version:** Latest from repos
- **Ubuntu/Debian:** Package: `ripgrep`
- **Arch:** Package: `ripgrep`
- **What:** Ultra-fast grep alternative
- **Replaces:** `grep`

### 4. fd
- **Version:** Latest
- **Ubuntu/Debian:** Package: `fd-find`
- **Arch:** Package: `fd`
- **What:** Fast, user-friendly alternative to find
- **Replaces:** `find`

### 5. fzf
- **Version:** Latest from repos
- **All distros:** Package: `fzf`
- **What:** Fuzzy finder for command-line
- **Keybindings:**
  - `Ctrl+R` - History search
  - `Ctrl+T` - File search
  - `Alt+C` - Directory navigation
- **Config:** Custom FZF_DEFAULT_OPTS with GitHub Dark colors

### 6. zoxide
- **Version:** Latest
- **Location:** `~/.local/bin/zoxide`
- **Installed via:** Official install script
- **What:** Smart cd that learns your habits
- **Replaces:** `cd` (via alias)
- **Usage:** `cd <partial-path>` or `zi` (interactive)

### 7. lazygit
- **Version:** Latest from GitHub
- **Location:** `~/.local/bin/lazygit`
- **What:** Terminal UI for git
- **Alias:** `lg`

### 8. btop OR bottom
- **Version:** Latest
- **Arch:** Package: `btop`
- **Others:** `bottom` (btm) via cargo
- **What:** System resource monitor
- **Replaces:** `top`, `htop`
- **Aliases:**
  - `top='btop'`
  - `htop='btop'`

### 9. dust (du-dust)
- **Version:** Latest via cargo
- **Location:** `~/.cargo/bin/dust`
- **What:** Intuitive disk usage analyzer
- **Replaces:** `du`
- **Alias:** `du='dust'`

### 10. duf
- **Version:** Latest from GitHub
- **Location:** `~/.local/bin/duf`
- **What:** Better df alternative (disk free)
- **Replaces:** `df`
- **Alias:** `df='duf'`

### 11. neovim
- **Version:** Latest from repos
- **All distros:** Package: `neovim`
- **Location:** `/usr/bin/nvim`
- **What:** Modern vim fork
- **Replaces:** `vim`
- **Aliases:**
  - `vim='nvim'`
  - `vi='nvim'`
  - `v='nvim'`
- **Config:** `~/.config/nvim/` (AstroNvim)

### 12. git
- **Version:** System git
- **All distros:** Package: `git`
- **What:** Version control system
- **Config:** `~/.gitconfig` with delta pager

### 13. delta
- **Version:** Latest (installed via git config or binary)
- **What:** Syntax-highlighting pager for git
- **Usage:** Automatic with `git diff`

### 14. tmux
- **Already listed in Terminal section**

### 15. Other utilities
- **GNU utilities:** tar, gzip, unzip, wget, curl
- **Location:** System /usr/bin/

---

## 🐚 Shell Enhancements (3 Tools)

### 1. ble.sh
- **Version:** Latest from GitHub
- **Location:** `~/.local/share/blesh/`
- **What:** Bash Line Editor
- **Features:**
  - Auto-suggestions (like zsh-autosuggestions)
  - Syntax highlighting (green=valid, red=invalid)
  - Enhanced completion
  - Better line editing
- **Loaded in:** `~/.bashrc`

### 2. oh-my-posh
- **Version:** Latest
- **Location:** `~/.local/bin/oh-my-posh`
- **Installed via:** Official install script
- **What:** Cross-platform prompt theme engine
- **Theme:** `~/.config/oh-my-posh-dark-colorblind.omp.json`
- **Replaces:** Default bash prompt

### 3. zoxide
- **Already listed in Modern CLI Tools**

---

## 🔌 Tmux Plugins (6 Components)

### Tmux Plugin Manager (TPM)
- **Location:** `~/.tmux/plugins/tpm`
- **What:** Plugin manager for tmux
- **Install plugins:** `Ctrl+g` then `Shift+I`

### Plugin 1: tmux-sensible
- **Repo:** `tmux-plugins/tmux-sensible`
- **What:** Basic tmux settings everyone can agree on

### Plugin 2: tmux-yank
- **Repo:** `tmux-plugins/tmux-yank`
- **What:** Copy to system clipboard from tmux

### Plugin 3: tmux-resurrect
- **Repo:** `tmux-plugins/tmux-resurrect`
- **What:** Save and restore tmux sessions
- **Saves:** Panes, windows, processes

### Plugin 4: tmux-continuum
- **Repo:** `tmux-plugins/tmux-continuum`
- **What:** Automatic tmux session save/restore
- **Frequency:** Every 1 minute
- **Auto-restore:** On tmux start

### Plugin 5: tmux-logging
- **Repo:** `tmux-plugins/tmux-logging`
- **What:** Capture pane output to files
- **Features:**
  - Toggle logging: `Alt+Shift+L`
  - Save complete history: `Alt+Shift+H`
  - Screen capture: `Alt+Shift+P`

---

## ⚙️ Configuration Files (Symlinked)

### Shell Configuration (5 files)
1. `~/.bashrc` ← `~/configs/bashrc`
2. `~/.bash_aliases` ← `~/configs/.bash_aliases`
3. `~/.inputrc` ← `~/configs/.inputrc`
4. `~/.profile` (if exists)
5. `~/.bash_profile` (if exists)

### Git Configuration (2 files)
1. `~/.gitconfig` ← `~/configs/.gitconfig`

### Terminal Configuration (2 directories)
1. `~/.config/tmux/tmux.conf` ← `~/configs/tmux/tmux.conf`
2. `~/.config/alacritty/alacritty.toml` ← `~/configs/alacritty/alacritty.toml`

### Editor Configuration (1 directory)
1. `~/.config/nvim/` ← `~/configs/nvim/`

### Tool Configuration (5 files)
1. `~/.config/k9s/config.yaml` ← `~/configs/k9s/config.yaml`
2. `~/.config/k9s/skins/github-dark.yaml` ← `~/configs/k9s/skins/github-dark.yaml`
3. `~/.config/k9s/plugins.yaml` (created)
4. `~/.config/lazydocker/config.yml` ← `~/configs/lazydocker/config.yml`
5. `~/.config/oh-my-posh-dark-colorblind.omp.json` ← `~/configs/oh-my-posh/dark-colorblind.omp.json`

### Custom Scripts (Entire bin/ directory)
- All scripts from `~/configs/bin/` → `~/bin/`
- Examples:
  - `pomodoro`
  - `block-social-media`
  - `tmux-session-menu`
  - `tmux-save-persistent`
  - `tmux-resurrect-filter`
  - `tmux-resurrect-filter-post`
  - `install-docker-k8s-tools.sh`
  - `install-shell-tools.sh`
  - `record-primary.sh`
  - `whisper-hotkey`
  - `mo` (monitor optimizer)

---

## 📝 Bash Aliases (60+ Aliases)

### Navigation (4)
```bash
..='cd ..'
...='cd ../..'
....='cd ../../..'
.....='cd ../../../..'
```

### Modern CLI Replacements (11)
```bash
ls='eza --icons --group-directories-first'
ll='eza -l --icons --group-directories-first --git'
la='eza -la --icons --group-directories-first --git'
lt='eza --tree --level=2 --icons'
tree='eza --tree --icons'
cat='bat --style=auto'
top='btop'
htop='btop'
df='duf'
du='dust'
grep='grep --color=auto'
```

### Git (14)
```bash
lg='lazygit'
gst='git status'
gd='git diff'
ga='git add'
gc='git commit'
gp='git push'
gl='git pull'
gco='git checkout'
gb='git branch'
glog='git log --oneline --graph --decorate'
glast='git log -1 HEAD'
gunstage='git reset HEAD --'
```

### Docker (17)
```bash
d='docker'
dps='docker ps'
dpsa='docker ps -a'
dimg='docker images'
dex='docker exec -it'
dlog='docker logs'
dlogf='docker logs -f'
drm='docker rm'
drmi='docker rmi'
dstop='docker stop'
dstart='docker start'
drestart='docker restart'
dinspect='docker inspect'
dprune='docker system prune -af'
dvol='docker volume ls'
dnet='docker network ls'
lzd='lazydocker'
```

### Docker Compose (13)
```bash
dc='docker-compose'
dcu='docker-compose up'
dcud='docker-compose up -d'
dcd='docker-compose down'
dcl='docker-compose logs'
dclf='docker-compose logs -f'
dcps='docker-compose ps'
dcrestart='docker-compose restart'
dcbuild='docker-compose build'
dcpull='docker-compose pull'
dcstop='docker-compose stop'
dcstart='docker-compose start'
dcexec='docker-compose exec'
```

### Kubernetes (16)
```bash
k='kubectl'
k9='k9s'
kgp='kubectl get pods'
kgs='kubectl get services'
kgd='kubectl get deployments'
kgn='kubectl get nodes'
kga='kubectl get all'
kdp='kubectl describe pod'
kds='kubectl describe service'
kdd='kubectl describe deployment'
kdn='kubectl describe node'
kdel='kubectl delete'
klog='kubectl logs'
klogf='kubectl logs -f'
kexec='kubectl exec -it'
kapply='kubectl apply -f'
kctx='kubectl config current-context'
kns='kubectl config view --minify --output "jsonpath={..namespace}"'
```

### Tmux (4)
```bash
ta='tmux attach'
tl='tmux ls'
tn='tmux new -s'
tk='tmux kill-session -t'
```

### Editor (3)
```bash
vim='nvim'
vi='nvim'
v='nvim'
```

### Utilities (8)
```bash
cls='clear'
c='clear'
h='history'
j='jobs -l'
path='echo -e ${PATH//:/\\n}'
cp='cp -i'
mv='mv -i'
rm='rm -i'
mkdir='mkdir -pv'
wget='wget -c'
diff='diff --color=auto'
```

---

## 🔧 Bash Functions (15+ Functions)

### Docker Functions (4)
```bash
dsh()        # Shell into container (tries bash, falls back to sh)
dcsh()       # Shell into docker-compose service
dclean()     # Clean up all Docker resources
dip()        # Get container IP address
```

### Kubernetes Functions (5)
```bash
kshell()     # Shell into pod
ksetns()     # Set default namespace
kgetns()     # Get current namespace
kwatchpods() # Watch pods with live updates
kport()      # Port forward to pod
```

### FZF Functions (3)
```bash
frg()        # Search with ripgrep + fzf + bat preview, open in nvim
zi()         # Interactive directory jump with zoxide + fzf
fkill()      # Interactive process killer
```

### Utility Functions (5)
```bash
note()       # Quick notes in ~/notes/
extract()    # Universal archive extractor
backup()     # Backup file with timestamp
mkcd()       # Make directory and cd into it
fcd()        # FZF directory jump
```

---

## 📊 Total Installation Count

### Core Systems:
- **Docker Tools:** 3 (Docker, Compose, lazydocker)
- **Kubernetes Tools:** 6 (kubectl, helm, minikube, kind, k9s, kubectx/ns)
- **Languages:** 4 systems (Go, Rust, Node.js, Python)
- **Terminal:** 3 (Alacritty, FiraCode Font, Tmux)
- **Modern CLI:** 15+ tools
- **Shell Enhancements:** 3 (ble.sh, oh-my-posh, zoxide)
- **Tmux Plugins:** 5 plugins + TPM
- **Config Files:** 15+ symlinked
- **Bash Aliases:** 60+
- **Bash Functions:** 15+

### **Grand Total: 100+ Components Installed**

---

## 💾 Disk Space Requirements

### Downloads:
- Docker: ~100 MB
- Kubernetes tools: ~500 MB
- Golang: ~150 MB
- Fonts: ~50 MB
- CLI tools: ~200 MB
- Other: ~200 MB
- **Total Downloads: ~1.2 GB**

### Installed:
- Docker (with common images): ~2 GB
- Kubernetes tools: ~800 MB
- Golang: ~500 MB
- Rust toolchain: ~1 GB
- CLI tools + configs: ~500 MB
- Fonts: ~100 MB
- **Total Installed: ~5 GB**

---

## 🌐 Network Requirements

### One-time Downloads:
- Docker installation script
- Kubernetes binaries (kubectl, helm, minikube, kind, k9s)
- Golang tarball
- Rust toolchain (rustup)
- Git repositories (ble.sh, kubectx, TPM)
- Binary releases (lazydocker, lazygit, duf, etc.)
- Fonts (~50 MB)

### Bandwidth Required: ~1.5-2 GB

---

## ⏱️ Installation Time Estimates

### Fast Connection (100 Mbps+):
- Full installation: **10-15 minutes**
- Minimal installation: **5-8 minutes**

### Moderate Connection (25-50 Mbps):
- Full installation: **15-25 minutes**
- Minimal installation: **8-12 minutes**

### Slow Connection (<10 Mbps):
- Full installation: **30-45 minutes**
- Minimal installation: **15-20 minutes**

---

## 🔐 Permissions & Security

### Requires sudo for:
- Package manager operations (apt/pacman/dnf)
- Docker installation
- Docker service management
- Installing system-wide tools (helm, kubectx)
- Installing Alacritty (if via package manager)

### User-level installations (no sudo):
- NVM
- Rust/Cargo
- Golang binaries to ~/.local/bin
- All dotfiles and configs
- ble.sh
- oh-my-posh
- Fonts to ~/.local/share/fonts

### Security additions:
- User added to `docker` group (allows docker without sudo)
- No modifications to /etc except via package managers
- All custom scripts in user space (~/bin)

---

**Last Updated:** 2025-11-18
**Total Packages:** 100+
**Supported Distributions:** Ubuntu, Debian, Arch, Manjaro, RHEL, Fedora, CentOS, Rocky, AlmaLinux
