#!/usr/bin/env bash
# =============================================================================
# Complete Installation Script for Development Environment
# =============================================================================
# This script installs ALL tools and dependencies for the workflow
# Run with: sudo bash install-everything.sh
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the actual user (not root)
if [ "$SUDO_USER" ]; then
    ACTUAL_USER=$SUDO_USER
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    ACTUAL_USER=$(whoami)
    USER_HOME=$HOME
fi

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# =============================================================================
# Helper Functions
# =============================================================================

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

error() {
    echo -e "${RED}[✗]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

step() {
    echo -e "\n${MAGENTA}==>${NC} ${CYAN}$1${NC}\n"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

run_as_user() {
    sudo -u "$ACTUAL_USER" "$@"
}

# =============================================================================
# Detect Linux Distribution
# =============================================================================

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        DISTRO=$DISTRIB_ID
        DISTRO_VERSION=$DISTRIB_RELEASE
    else
        DISTRO=$(uname -s)
        DISTRO_VERSION=$(uname -r)
    fi

    DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')

    case "$DISTRO" in
        ubuntu|debian|pop|linuxmint)
            PKG_MANAGER="apt"
            PKG_UPDATE="apt update"
            PKG_INSTALL="apt install -y"
            ;;
        arch|manjaro|endeavouros)
            PKG_MANAGER="pacman"
            PKG_UPDATE="pacman -Sy"
            PKG_INSTALL="pacman -S --noconfirm"
            ;;
        rhel|centos|fedora|rocky|almalinux)
            if command_exists dnf; then
                PKG_MANAGER="dnf"
                PKG_UPDATE="dnf check-update || true"
                PKG_INSTALL="dnf install -y"
            else
                PKG_MANAGER="yum"
                PKG_UPDATE="yum check-update || true"
                PKG_INSTALL="yum install -y"
            fi
            ;;
        *)
            error "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac

    info "Detected: $DISTRO $DISTRO_VERSION"
    info "Package Manager: $PKG_MANAGER"
}

# =============================================================================
# Install Base Packages
# =============================================================================

install_base_packages() {
    step "Installing base packages and build tools"

    $PKG_UPDATE

    case "$PKG_MANAGER" in
        apt)
            $PKG_INSTALL \
                build-essential \
                git \
                curl \
                wget \
                unzip \
                tar \
                gzip \
                make \
                gcc \
                g++ \
                pkg-config \
                libssl-dev \
                software-properties-common \
                apt-transport-https \
                ca-certificates \
                gnupg \
                lsb-release \
                fontconfig \
                gawk
            ;;
        pacman)
            $PKG_INSTALL \
                base-devel \
                git \
                curl \
                wget \
                unzip \
                tar \
                gzip \
                make \
                gcc \
                openssl \
                pkgconf \
                fontconfig \
                gawk
            ;;
        dnf|yum)
            $PKG_INSTALL \
                @development-tools \
                git \
                curl \
                wget \
                unzip \
                tar \
                gzip \
                make \
                gcc \
                gcc-c++ \
                openssl-devel \
                pkgconfig \
                fontconfig \
                gawk
            ;;
    esac

    success "Base packages installed"
}

# =============================================================================
# Install Rust
# =============================================================================

install_rust() {
    step "Installing Rust (latest stable)"

    if ! run_as_user bash -c 'command -v cargo' &>/dev/null; then
        info "Installing Rust via rustup..."
        run_as_user bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
        run_as_user bash -c 'source "$HOME/.cargo/env"'
        success "Rust installed: $(run_as_user bash -c 'source "$HOME/.cargo/env" && rustc --version')"
    else
        info "Rust already installed, updating..."
        run_as_user bash -c 'source "$HOME/.cargo/env" && rustup update'
        success "Rust updated: $(run_as_user bash -c 'source "$HOME/.cargo/env" && rustc --version')"
    fi
}

# =============================================================================
# Install Modern CLI Tools
# =============================================================================

install_modern_cli_tools() {
    step "Installing modern CLI tools"

    case "$PKG_MANAGER" in
        apt)
            # bat
            if ! command_exists bat && ! command_exists batcat; then
                info "Installing bat..."
                BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
                wget -q "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_amd64.deb" -O /tmp/bat.deb
                dpkg -i /tmp/bat.deb || true
                rm /tmp/bat.deb
                success "bat v${BAT_VERSION} installed"
            fi

            # eza
            if ! command_exists eza; then
                info "Installing eza..."
                mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
                chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                apt update
                apt install -y eza
                success "eza installed"
            fi

            # Install remaining tools
            $PKG_INSTALL ripgrep fd-find fzf tmux neovim python3-pip python3-venv
            ;;
        pacman)
            $PKG_INSTALL \
                bat \
                eza \
                ripgrep \
                fd \
                fzf \
                tmux \
                neovim \
                python-pip
            ;;
        dnf|yum)
            $PKG_INSTALL \
                bat \
                ripgrep \
                fd-find \
                fzf \
                tmux \
                neovim \
                python3-pip

            # Install eza from binary
            if ! command_exists eza; then
                info "Installing eza from binary..."
                EZA_VERSION=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
                wget -q "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" -O /tmp/eza.tar.gz
                tar xzf /tmp/eza.tar.gz -C /usr/local/bin
                rm /tmp/eza.tar.gz
                success "eza v${EZA_VERSION} installed"
            fi
            ;;
    esac

    # Install btop, dust, duf via cargo/binary
    install_performance_tools

    # Install lazygit
    install_lazygit

    success "Modern CLI tools installed"
}

# =============================================================================
# Install Performance Monitoring Tools
# =============================================================================

install_performance_tools() {
    # btop
    if ! command_exists btop; then
        info "Installing btop..."
        case "$PKG_MANAGER" in
            pacman)
                $PKG_INSTALL btop
                ;;
            *)
                BTOP_VERSION=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
                wget -q "https://github.com/aristocratos/btop/releases/download/v${BTOP_VERSION}/btop-x86_64-linux-musl.tbz" -O /tmp/btop.tbz
                tar xjf /tmp/btop.tbz -C /tmp
                cd /tmp/btop && make install PREFIX=/usr/local
                rm -rf /tmp/btop /tmp/btop.tbz
                success "btop v${BTOP_VERSION} installed"
                ;;
        esac
    fi

    # dust
    if ! command_exists dust; then
        info "Installing dust..."
        run_as_user bash -c 'source "$HOME/.cargo/env" && cargo install du-dust'
        success "dust installed"
    fi

    # duf
    if ! command_exists duf; then
        info "Installing duf..."
        case "$PKG_MANAGER" in
            pacman)
                $PKG_INSTALL duf
                ;;
            *)
                DUF_VERSION=$(curl -s https://api.github.com/repos/muesli/duf/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
                wget -q "https://github.com/muesli/duf/releases/download/v${DUF_VERSION}/duf_${DUF_VERSION}_linux_amd64.tar.gz" -O /tmp/duf.tar.gz
                tar xzf /tmp/duf.tar.gz -C /tmp
                mv /tmp/duf /usr/local/bin/
                chmod +x /usr/local/bin/duf
                rm /tmp/duf.tar.gz
                success "duf v${DUF_VERSION} installed"
                ;;
        esac
    fi
}

# =============================================================================
# Install LazyGit
# =============================================================================

install_lazygit() {
    if ! command_exists lazygit; then
        info "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        wget -q "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -O /tmp/lazygit.tar.gz
        tar xzf /tmp/lazygit.tar.gz -C /tmp
        mv /tmp/lazygit /usr/local/bin/
        chmod +x /usr/local/bin/lazygit
        rm /tmp/lazygit.tar.gz
        success "lazygit v${LAZYGIT_VERSION} installed"
    fi
}

# =============================================================================
# Install Git Delta
# =============================================================================

install_git_delta() {
    step "Installing git-delta (better git diffs)"

    if ! command_exists delta; then
        info "Installing git-delta..."
        DELTA_VERSION=$(curl -s https://api.github.com/repos/dandavison/delta/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -O /tmp/delta.deb 2>/dev/null || \
        wget -q "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" -O /tmp/delta.tar.gz

        if [ -f /tmp/delta.deb ]; then
            dpkg -i /tmp/delta.deb || true
            rm /tmp/delta.deb
        elif [ -f /tmp/delta.tar.gz ]; then
            tar xzf /tmp/delta.tar.gz -C /tmp
            mv /tmp/delta-*/delta /usr/local/bin/
            rm -rf /tmp/delta-* /tmp/delta.tar.gz
        fi
        success "git-delta ${DELTA_VERSION} installed"
    fi
}

# =============================================================================
# Install Zoxide
# =============================================================================

install_zoxide() {
    step "Installing zoxide (smart directory jumper)"

    if ! command_exists zoxide; then
        run_as_user bash -c 'curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'
        success "zoxide installed"
    else
        info "zoxide already installed"
    fi
}

# =============================================================================
# Install Oh My Posh
# =============================================================================

install_oh_my_posh() {
    step "Installing oh-my-posh (prompt theme)"

    if ! command_exists oh-my-posh; then
        run_as_user bash -c 'curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin'
        success "oh-my-posh installed"
    else
        info "oh-my-posh already installed"
    fi
}

# =============================================================================
# Install NVM (Node Version Manager)
# =============================================================================

install_nvm() {
    step "Installing NVM and Node.js"

    if [ ! -d "$USER_HOME/.nvm" ]; then
        info "Installing NVM..."
        NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        run_as_user bash -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash"

        # Install latest LTS Node.js
        run_as_user bash -c 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; nvm install --lts'
        success "NVM v${NVM_VERSION} and Node.js LTS installed"
    else
        info "NVM already installed"
    fi
}

# =============================================================================
# Install Golang
# =============================================================================

install_golang() {
    step "Installing Golang (latest)"

    if command_exists go; then
        info "Golang already installed: $(go version)"
        return
    fi

    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)
    info "Installing ${GO_VERSION}..."

    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="armv6l" ;;
        *)       error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    wget -q "https://go.dev/dl/${GO_VERSION}.linux-${ARCH}.tar.gz" -O /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    success "Golang ${GO_VERSION} installed"
}

# =============================================================================
# Install Python Tools
# =============================================================================

install_python_tools() {
    step "Installing Python development tools"

    case "$PKG_MANAGER" in
        apt)
            $PKG_INSTALL python3 python3-pip python3-dev python3-venv python-is-python3 pipx
            ;;
        pacman)
            $PKG_INSTALL python python-pip python-virtualenv python-pipx
            ;;
        dnf|yum)
            $PKG_INSTALL python3 python3-pip python3-devel python3-virtualenv pipx
            ;;
    esac

    # Install pyenv
    if [ ! -d "$USER_HOME/.pyenv" ]; then
        info "Installing pyenv..."
        run_as_user bash -c 'curl https://pyenv.run | bash'
        success "pyenv installed"
    fi

    # Install poetry
    if ! command_exists poetry; then
        info "Installing poetry..."
        run_as_user bash -c 'curl -sSL https://install.python-poetry.org | python3 -'
        success "poetry installed"
    fi

    success "Python tools installed"
}

# =============================================================================
# Install Alacritty
# =============================================================================

install_alacritty() {
    step "Installing Alacritty terminal"

    if command_exists alacritty; then
        info "Alacritty already installed"
        return
    fi

    case "$PKG_MANAGER" in
        apt)
            add-apt-repository ppa:aslatter/ppa -y || true
            apt update
            $PKG_INSTALL alacritty || {
                warning "PPA failed, building from source..."
                build_alacritty_from_source
            }
            ;;
        pacman)
            $PKG_INSTALL alacritty
            ;;
        dnf|yum)
            $PKG_INSTALL alacritty || build_alacritty_from_source
            ;;
    esac

    success "Alacritty installed"
}

build_alacritty_from_source() {
    info "Building Alacritty from source..."

    # Install dependencies
    case "$PKG_MANAGER" in
        apt)
            $PKG_INSTALL cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3
            ;;
        dnf|yum)
            $PKG_INSTALL cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel python3
            ;;
    esac

    run_as_user bash -c 'source "$HOME/.cargo/env" && cargo install alacritty'
}

# =============================================================================
# Install FiraCode Nerd Font
# =============================================================================

install_nerd_fonts() {
    step "Installing FiraCode Nerd Font"

    FONT_DIR="/usr/share/fonts/truetype/firacode-nerd"

    if fc-list | grep -qi "FiraCode.*Nerd"; then
        info "FiraCode Nerd Font already installed"
        return
    fi

    mkdir -p "$FONT_DIR"
    cd "$FONT_DIR"

    info "Downloading FiraCode Nerd Font..."
    FONT_VERSION=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/FiraCode.zip" -O FiraCode.zip
    unzip -o FiraCode.zip
    rm FiraCode.zip

    # Refresh font cache
    fc-cache -fv

    success "FiraCode Nerd Font v${FONT_VERSION} installed"
}

# =============================================================================
# Install Docker
# =============================================================================

install_docker() {
    step "Installing Docker and Docker Compose"

    if command_exists docker; then
        info "Docker already installed: $(docker --version)"
        return
    fi

    case "$PKG_MANAGER" in
        apt)
            # Remove old versions
            apt remove -y docker docker-engine docker.io containerd runc || true

            # Install Docker
            curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
            sh /tmp/get-docker.sh
            rm /tmp/get-docker.sh
            ;;
        pacman)
            $PKG_INSTALL docker docker-compose docker-buildx
            ;;
        dnf|yum)
            $PKG_INSTALL dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || \
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
            ;;
    esac

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Add user to docker group
    usermod -aG docker "$ACTUAL_USER"

    success "Docker installed (logout/login required for group changes)"
}

# =============================================================================
# Install Kubernetes Tools
# =============================================================================

install_kubernetes_tools() {
    step "Installing Kubernetes tools"

    # kubectl
    if ! command_exists kubectl; then
        info "Installing kubectl..."
        KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
        curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
        success "kubectl ${KUBECTL_VERSION} installed"
    fi

    # helm
    if ! command_exists helm; then
        info "Installing helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        success "helm installed"
    fi

    # minikube
    if ! command_exists minikube; then
        info "Installing minikube..."
        MINIKUBE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        wget -q "https://storage.googleapis.com/minikube/releases/v${MINIKUBE_VERSION}/minikube-linux-amd64" -O minikube
        chmod +x minikube
        mv minikube /usr/local/bin/
        success "minikube v${MINIKUBE_VERSION} installed"
    fi

    # kind
    if ! command_exists kind; then
        info "Installing kind..."
        KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
        curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-amd64"
        chmod +x ./kind
        mv ./kind /usr/local/bin/kind
        success "kind v${KIND_VERSION} installed"
    fi

    success "Kubernetes tools installed"
}

# =============================================================================
# Install lazydocker
# =============================================================================

install_lazydocker() {
    step "Installing lazydocker"

    if command_exists lazydocker; then
        info "lazydocker already installed"
        return
    fi

    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="x86_64" ;;
        aarch64) ARCH="arm64" ;;
        *)       warning "Unsupported architecture: $ARCH"; return ;;
    esac

    LAZYDOCKER_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    wget -q "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VERSION}/lazydocker_${LAZYDOCKER_VERSION}_Linux_${ARCH}.tar.gz" -O /tmp/lazydocker.tar.gz
    tar xzf /tmp/lazydocker.tar.gz -C /tmp
    mv /tmp/lazydocker /usr/local/bin/
    chmod +x /usr/local/bin/lazydocker
    rm /tmp/lazydocker.tar.gz

    success "lazydocker v${LAZYDOCKER_VERSION} installed"
}

# =============================================================================
# Install k9s
# =============================================================================

install_k9s() {
    step "Installing k9s"

    if command_exists k9s; then
        info "k9s already installed"
        return
    fi

    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)       warning "Unsupported architecture: $ARCH"; return ;;
    esac

    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    wget -q "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${ARCH}.tar.gz" -O /tmp/k9s.tar.gz
    tar xzf /tmp/k9s.tar.gz -C /tmp
    mv /tmp/k9s /usr/local/bin/
    chmod +x /usr/local/bin/k9s
    rm /tmp/k9s.tar.gz

    success "k9s v${K9S_VERSION} installed"
}

# =============================================================================
# Install ble.sh (Bash Auto-suggestions)
# =============================================================================

install_blesh() {
    step "Installing ble.sh (bash auto-suggestions)"

    if [ -d "$USER_HOME/.local/share/blesh" ]; then
        info "ble.sh already installed"
        return
    fi

    run_as_user bash -c 'git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git ~/.local/share/blesh'
    run_as_user bash -c 'make -C ~/.local/share/blesh install PREFIX=~/.local'

    success "ble.sh installed"
}

# =============================================================================
# Install sesh (tmux session manager)
# =============================================================================

install_sesh() {
    step "Installing sesh (tmux session manager)"

    if ! command_exists sesh; then
        run_as_user bash -c 'source "$HOME/.cargo/env" && cargo install sesh'
        success "sesh installed"
    else
        info "sesh already installed"
    fi
}

# =============================================================================
# Install Tmux Plugin Manager
# =============================================================================

install_tmux_plugins() {
    step "Installing Tmux Plugin Manager (TPM)"

    if [ ! -d "$USER_HOME/.tmux/plugins/tpm" ]; then
        run_as_user git clone https://github.com/tmux-plugins/tpm "$USER_HOME/.tmux/plugins/tpm"
        success "TPM installed"
        info "Run 'tmux' and press Ctrl+g + I to install tmux plugins"
    else
        info "TPM already installed"
    fi
}

# =============================================================================
# Setup Configuration Files
# =============================================================================

setup_configs() {
    step "Setting up configuration files"

    # Backup existing configs
    backup_dir="$USER_HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    [ -f "$USER_HOME/.bashrc" ] && cp "$USER_HOME/.bashrc" "$backup_dir/"
    [ -f "$USER_HOME/.bash_aliases" ] && cp "$USER_HOME/.bash_aliases" "$backup_dir/"
    [ -f "$USER_HOME/.gitconfig" ] && cp "$USER_HOME/.gitconfig" "$backup_dir/"
    [ -f "$USER_HOME/.inputrc" ] && cp "$USER_HOME/.inputrc" "$backup_dir/"

    info "Backed up existing configs to: $backup_dir"

    # Symlink configs
    run_as_user ln -sf "$SCRIPT_DIR/bashrc" "$USER_HOME/.bashrc"
    run_as_user ln -sf "$SCRIPT_DIR/.bash_aliases" "$USER_HOME/.bash_aliases"
    run_as_user ln -sf "$SCRIPT_DIR/.inputrc" "$USER_HOME/.inputrc"
    run_as_user ln -sf "$SCRIPT_DIR/.gitconfig" "$USER_HOME/.gitconfig"
    run_as_user ln -sf "$SCRIPT_DIR/.ripgreprc" "$USER_HOME/.ripgreprc"

    # Tmux
    run_as_user mkdir -p "$USER_HOME/.config/tmux"
    run_as_user ln -sf "$SCRIPT_DIR/tmux/tmux.conf" "$USER_HOME/.config/tmux/tmux.conf"

    # Alacritty
    run_as_user mkdir -p "$USER_HOME/.config/alacritty"
    run_as_user ln -sf "$SCRIPT_DIR/alacritty/alacritty.toml" "$USER_HOME/.config/alacritty/alacritty.toml"

    # Oh-my-posh
    run_as_user mkdir -p "$USER_HOME/.config"
    run_as_user ln -sf "$SCRIPT_DIR/oh-my-posh/dark-colorblind.omp.json" "$USER_HOME/.config/oh-my-posh-dark-colorblind.omp.json"

    # k9s
    run_as_user mkdir -p "$USER_HOME/.config/k9s/skins"
    [ -f "$SCRIPT_DIR/k9s/config.yaml" ] && run_as_user ln -sf "$SCRIPT_DIR/k9s/config.yaml" "$USER_HOME/.config/k9s/config.yaml"
    [ -f "$SCRIPT_DIR/k9s/skins/github-dark.yaml" ] && run_as_user ln -sf "$SCRIPT_DIR/k9s/skins/github-dark.yaml" "$USER_HOME/.config/k9s/skins/github-dark.yaml"

    # lazydocker
    run_as_user mkdir -p "$USER_HOME/.config/lazydocker"
    [ -f "$SCRIPT_DIR/lazydocker/config.yml" ] && run_as_user ln -sf "$SCRIPT_DIR/lazydocker/config.yml" "$USER_HOME/.config/lazydocker/config.yml"

    # Bin scripts
    run_as_user mkdir -p "$USER_HOME/bin"
    if [ -d "$SCRIPT_DIR/bin" ]; then
        for script in "$SCRIPT_DIR/bin"/*; do
            [ -f "$script" ] && run_as_user ln -sf "$script" "$USER_HOME/bin/$(basename "$script")"
        done
    fi

    success "Configuration files symlinked"
}

# =============================================================================
# Update Bashrc
# =============================================================================

update_bashrc() {
    step "Ensuring all paths are in bashrc"

    BASHRC="$USER_HOME/.bashrc"

    # Ensure paths are in bashrc (these should already be in the bashrc file, but just in case)
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$BASHRC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC"
    fi

    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$BASHRC"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$BASHRC"
    fi

    if ! grep -q '/usr/local/go/bin' "$BASHRC"; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> "$BASHRC"
    fi

    if ! grep -q '$HOME/go/bin' "$BASHRC"; then
        echo 'export PATH=$PATH:$HOME/go/bin' >> "$BASHRC"
    fi

    if ! grep -q 'source "$HOME/.cargo/env"' "$BASHRC"; then
        echo '. "$HOME/.cargo/env"' >> "$BASHRC"
    fi

    chown "$ACTUAL_USER:$ACTUAL_USER" "$BASHRC"
    success "Bashrc updated"
}

# =============================================================================
# Print Summary
# =============================================================================

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            Installation Complete!                          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${CYAN}📦 Installed Tools:${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} Modern CLI Tools: bat, eza, ripgrep, fd, fzf, lazygit, btop, dust, duf"
    echo -e "${GREEN}✓${NC} Shell: zoxide, oh-my-posh, ble.sh, sesh"
    echo -e "${GREEN}✓${NC} Terminal: tmux, alacritty, FiraCode Nerd Font"
    echo -e "${GREEN}✓${NC} Languages: Rust ($(run_as_user bash -c 'source "$HOME/.cargo/env" && rustc --version 2>/dev/null || echo "N/A"'))"
    echo -e "${GREEN}✓${NC} Languages: Go ($(go version 2>/dev/null | awk '{print $3}' || echo "N/A"))"
    echo -e "${GREEN}✓${NC} Languages: Node.js ($(run_as_user bash -c 'source "$HOME/.nvm/nvm.sh" && node --version 2>/dev/null || echo "N/A"'))"
    echo -e "${GREEN}✓${NC} Languages: Python + pyenv + poetry"
    echo -e "${GREEN}✓${NC} Git: lazygit, git-delta"
    echo -e "${GREEN}✓${NC} Container: Docker ($(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo "N/A"))"
    echo -e "${GREEN}✓${NC} Container UI: lazydocker"
    echo -e "${GREEN}✓${NC} Kubernetes: kubectl, helm, minikube, kind, k9s"
    echo ""
    echo -e "${CYAN}📝 Next Steps:${NC}"
    echo ""
    echo "  1. ${YELLOW}Reload your shell:${NC}"
    echo "     exec bash"
    echo ""
    echo "  2. ${YELLOW}Start tmux and install plugins:${NC}"
    echo "     tmux"
    echo "     # Press Ctrl+g then Shift+I"
    echo ""
    echo "  3. ${YELLOW}Configure git with your info:${NC}"
    echo "     git config --global user.name \"Your Name\""
    echo "     git config --global user.email \"your@email.com\""
    echo ""
    if groups "$ACTUAL_USER" | grep -q docker; then
        echo -e "${GREEN}✓${NC} Docker group configured"
    else
        echo -e "${YELLOW}!${NC} Logout and login to use Docker without sudo"
    fi
    echo ""
    echo -e "${GREEN}All tools installed with latest stable versions!${NC}"
    echo ""
}

# =============================================================================
# Main Installation
# =============================================================================

main() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        error "Please run this script with sudo"
        exit 1
    fi

    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     Complete Development Environment Installation          ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    info "This will install ALL tools and dependencies"
    info "Installation user: $ACTUAL_USER"
    info "User home: $USER_HOME"
    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi

    detect_distro
    install_base_packages
    install_rust
    install_modern_cli_tools
    install_git_delta
    install_zoxide
    install_oh_my_posh
    install_nvm
    install_golang
    install_python_tools
    install_alacritty
    install_nerd_fonts
    install_docker
    install_kubernetes_tools
    install_lazydocker
    install_k9s
    install_blesh
    install_sesh
    install_tmux_plugins
    setup_configs
    update_bashrc
    print_summary
}

main "$@"
