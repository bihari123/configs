#!/usr/bin/env bash
# =============================================================================
# Universal Linux Development Environment Bootstrap Script
# =============================================================================
# Supports: Ubuntu/Debian, Arch/Manjaro, RHEL/Fedora/CentOS
# Sets up: Modern CLI tools, Docker/K8s tools, shell enhancements, configs
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
            PKG_UPDATE="sudo apt update"
            PKG_INSTALL="sudo apt install -y"
            ;;
        arch|manjaro|endeavouros)
            PKG_MANAGER="pacman"
            PKG_UPDATE="sudo pacman -Sy"
            PKG_INSTALL="sudo pacman -S --noconfirm"
            ;;
        rhel|centos|fedora|rocky|almalinux)
            if command_exists dnf; then
                PKG_MANAGER="dnf"
                PKG_UPDATE="sudo dnf check-update || true"
                PKG_INSTALL="sudo dnf install -y"
            else
                PKG_MANAGER="yum"
                PKG_UPDATE="sudo yum check-update || true"
                PKG_INSTALL="sudo yum install -y"
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
# Install System Packages
# =============================================================================

install_base_packages() {
    step "Installing base packages"

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
                lsb-release
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
                pkgconf
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
                pkgconfig
            ;;
    esac

    success "Base packages installed"
}

# =============================================================================
# Install Modern CLI Tools
# =============================================================================

install_modern_cli_tools() {
    step "Installing modern CLI tools"

    case "$PKG_MANAGER" in
        apt)
            # Add repositories if needed
            if ! command_exists bat; then
                info "Installing bat..."
                wget -q https://github.com/sharkdp/bat/releases/download/v0.24.0/bat_0.24.0_amd64.deb -O /tmp/bat.deb
                sudo dpkg -i /tmp/bat.deb || true
                rm /tmp/bat.deb
            fi

            if ! command_exists eza; then
                info "Installing eza..."
                sudo mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                sudo apt update
                sudo apt install -y eza
            fi

            $PKG_INSTALL ripgrep fd-find fzf tmux neovim python3-pip
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
                python-pip \
                btop \
                dust \
                duf
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
                if wget -q https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O /tmp/eza.tar.gz 2>/dev/null; then
                    sudo tar xzf /tmp/eza.tar.gz -C /usr/local/bin 2>/dev/null || warning "Failed to extract eza"
                    rm -f /tmp/eza.tar.gz
                else
                    warning "Failed to download eza, skipping..."
                fi
            fi
            ;;
    esac

    # Install tools not in repos via cargo/binary
    install_rust_tools
    install_binary_tools

    success "Modern CLI tools installed"
}

install_rust_tools() {
    step "Installing Rust and Rust-based tools"

    # Install Rust if not present
    if ! command_exists cargo; then
        info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Install Rust tools if not available from system packages
    if ! command_exists btop && ! command_exists bottom; then
        cargo install bottom || true
    fi

    if ! command_exists dust; then
        cargo install du-dust || true
    fi

    if ! command_exists duf; then
        # duf is Go-based, we'll install it in binary section
        true
    fi

    success "Rust tools installed"
}

install_binary_tools() {
    step "Installing binary tools"

    mkdir -p ~/.local/bin

    # Install duf (Go)
    if ! command_exists duf; then
        info "Installing duf..."
        DUF_VERSION=$(curl -s https://api.github.com/repos/muesli/duf/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "")

        if [ -z "$DUF_VERSION" ]; then
            warning "Could not fetch duf version from GitHub API, skipping..."
        else
            if wget -q "https://github.com/muesli/duf/releases/download/v${DUF_VERSION}/duf_${DUF_VERSION}_linux_amd64.tar.gz" -O /tmp/duf.tar.gz 2>/dev/null; then
                tar xzf /tmp/duf.tar.gz -C /tmp 2>/dev/null || warning "Failed to extract duf"
                if [ -f /tmp/duf ]; then
                    mv /tmp/duf ~/.local/bin/ 2>/dev/null || warning "Failed to move duf"
                    chmod +x ~/.local/bin/duf 2>/dev/null || true
                fi
                rm -f /tmp/duf.tar.gz

                if command_exists duf; then
                    success "duf installed"
                else
                    warning "duf installation failed"
                fi
            else
                warning "Failed to download duf, skipping..."
            fi
        fi
    else
        info "duf already installed"
    fi

    # Install lazygit
    if ! command_exists lazygit; then
        info "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "")

        if [ -z "$LAZYGIT_VERSION" ]; then
            warning "Could not fetch lazygit version from GitHub API, skipping..."
        else
            if wget -q "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" -O /tmp/lazygit.tar.gz 2>/dev/null; then
                tar xzf /tmp/lazygit.tar.gz -C /tmp 2>/dev/null || warning "Failed to extract lazygit"
                if [ -f /tmp/lazygit ]; then
                    mv /tmp/lazygit ~/.local/bin/ 2>/dev/null || warning "Failed to move lazygit"
                    chmod +x ~/.local/bin/lazygit 2>/dev/null || true
                fi
                rm -f /tmp/lazygit.tar.gz

                if command_exists lazygit; then
                    success "lazygit installed"
                else
                    warning "lazygit installation failed"
                fi
            else
                warning "Failed to download lazygit, skipping..."
            fi
        fi
    else
        info "lazygit already installed"
    fi

    success "Binary tools installation completed"
}

# =============================================================================
# Install Zoxide
# =============================================================================

install_zoxide() {
    step "Installing zoxide"

    if ! command_exists zoxide; then
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        success "zoxide installed"
    else
        info "zoxide already installed"
    fi
}

# =============================================================================
# Install Oh My Posh
# =============================================================================

install_oh_my_posh() {
    step "Installing oh-my-posh"

    if ! command_exists oh-my-posh; then
        curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
        success "oh-my-posh installed"
    else
        info "oh-my-posh already installed"
    fi
}

# =============================================================================
# Install Sesh (Tmux Session Manager)
# =============================================================================

install_sesh() {
    step "Installing sesh"

    if ! command_exists sesh; then
        info "Installing sesh via cargo..."
        if ! command_exists cargo; then
            install_rust_tools
        fi
        go install github.com/joshmedeski/sesh/v2@latest
        success "sesh installed"
    else
        info "sesh already installed"
    fi
}

# =============================================================================
# Install NVM (Node Version Manager)
# =============================================================================

install_nvm() {
    step "Installing NVM"

    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        success "NVM installed"
    else
        info "NVM already installed"
    fi
}

# =============================================================================
# Install Golang
# =============================================================================

install_golang() {
    step "Installing Golang"

    if command_exists go; then
        info "Golang already installed: $(go version)"
        return
    fi

    # Get latest Go version
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)

    if [ -z "$GO_VERSION" ]; then
        warning "Could not fetch latest Go version, using go1.21.5"
        GO_VERSION="go1.21.5"
    fi

    info "Installing $GO_VERSION..."

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="armv6l" ;;
        *)       error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Download and install
    wget -q --show-progress "https://go.dev/dl/${GO_VERSION}.linux-${ARCH}.tar.gz" -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    # Add to PATH in bashrc if not already there
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi

    if ! grep -q '$HOME/go/bin' ~/.bashrc; then
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    fi

    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin

    success "Golang installed: $GO_VERSION"
}

# =============================================================================
# Install vcpkg (C++ Package Manager)
# =============================================================================

install_vcpkg() {
    step "Installing vcpkg"

    if [ -d "$HOME/vcpkg" ]; then
        info "vcpkg already installed at ~/vcpkg"
        return
    fi

    # Install prerequisites
    case "$PKG_MANAGER" in
        apt)
            $PKG_INSTALL curl zip unzip tar git
            ;;
        pacman)
            $PKG_INSTALL curl zip unzip tar git
            ;;
        dnf|yum)
            $PKG_INSTALL curl zip unzip tar git
            ;;
    esac

    info "Cloning vcpkg repository..."
    git clone https://github.com/microsoft/vcpkg.git "$HOME/vcpkg"

    info "Bootstrapping vcpkg..."
    "$HOME/vcpkg/bootstrap-vcpkg.sh"

    # Add to bashrc if not already there
    if ! grep -q "VCPKG_ROOT" ~/.bashrc; then
        echo 'export VCPKG_ROOT=~/vcpkg' >> ~/.bashrc
    fi

    export VCPKG_ROOT=~/vcpkg

    success "vcpkg installed at ~/vcpkg"
    info "Use: vcpkg install <package> to install C++ libraries"
}

# =============================================================================
# Install Alacritty (Terminal Emulator)
# =============================================================================

install_alacritty() {
    step "Installing Alacritty"

    if command_exists alacritty; then
        info "Alacritty already installed"
        return
    fi

    case "$PKG_MANAGER" in
        apt)
            # Add PPA for Ubuntu/Debian
            sudo add-apt-repository ppa:aslatter/ppa -y || true
            sudo apt update
            $PKG_INSTALL alacritty || {
                warning "PPA installation failed, trying cargo..."
                cargo install alacritty
            }
            ;;
        pacman)
            $PKG_INSTALL alacritty
            ;;
        dnf|yum)
            $PKG_INSTALL alacritty || {
                warning "Package not found, trying cargo..."
                cargo install alacritty
            }
            ;;
    esac

    success "Alacritty installed"
}

# =============================================================================
# Install FiraCode Nerd Font
# =============================================================================

install_nerd_fonts() {
    step "Installing FiraCode Nerd Font"

    FONT_DIR="$HOME/.local/share/fonts"
    FONT_NAME="FiraCode"

    if fc-list | grep -qi "FiraCode.*Nerd"; then
        info "FiraCode Nerd Font already installed"
        return
    fi

    mkdir -p "$FONT_DIR"
    cd "$FONT_DIR"

    info "Downloading FiraCode Nerd Font..."
    if wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip -O FiraCode.zip 2>/dev/null; then
        if [ -f FiraCode.zip ]; then
            unzip -o FiraCode.zip -d "$FONT_NAME" 2>&1 | grep -v "Archive:" || true
            rm -f FiraCode.zip

            # Refresh font cache
            fc-cache -fv >/dev/null 2>&1

            success "FiraCode Nerd Font installed"
            info "Configure your terminal to use 'FiraCode Nerd Font'"
        else
            warning "FiraCode Nerd Font download incomplete, skipping..."
            return 0
        fi
    else
        warning "Failed to download FiraCode Nerd Font, skipping..."
        return 0
    fi
}

# =============================================================================
# Install Multimedia Tools (FFmpeg, WebRTC, etc.)
# =============================================================================

install_multimedia_tools() {
    step "Installing multimedia tools and libraries"

    case "$PKG_MANAGER" in
        apt)
            $PKG_INSTALL \
                ffmpeg \
                libavcodec-dev \
                libavformat-dev \
                libavutil-dev \
                libswscale-dev \
                libswresample-dev \
                libavfilter-dev \
                libavdevice-dev \
                v4l-utils \
                libv4l-dev \
                libopus-dev \
                libvpx-dev \
                libx264-dev \
                libx265-dev \
                libaom-dev \
                libdav1d-dev \
                libmp3lame-dev \
                libvorbis-dev \
                libtheora-dev \
                libass-dev \
                libfreetype6-dev \
                libfontconfig1-dev \
                libfribidi-dev \
                yasm \
                nasm \
                libsrtp2-dev \
                libssl-dev \
                libwebrtc-audio-processing-dev || true
            ;;
        pacman)
            $PKG_INSTALL \
                ffmpeg \
                v4l-utils \
                opus \
                libvpx \
                x264 \
                x265 \
                aom \
                dav1d \
                lame \
                libvorbis \
                libtheora \
                libass \
                freetype2 \
                fontconfig \
                fribidi \
                yasm \
                nasm \
                libsrtp \
                openssl \
                webrtc-audio-processing || true
            ;;
        dnf|yum)
            # Enable RPM Fusion for ffmpeg
            sudo dnf install -y \
                https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

            $PKG_INSTALL \
                ffmpeg \
                ffmpeg-devel \
                v4l-utils \
                opus-devel \
                libvpx-devel \
                x264-devel \
                x265-devel \
                lame-devel \
                libvorbis-devel \
                libtheora-devel \
                libass-devel \
                freetype-devel \
                fontconfig-devel \
                fribidi-devel \
                yasm \
                nasm \
                libsrtp-devel \
                openssl-devel || true
            ;;
    esac

    success "Multimedia tools installed"
}

# =============================================================================
# Install C++23 Build Tools
# =============================================================================

install_cpp_build_tools() {
    step "Installing C++23 build tools"

    case "$PKG_MANAGER" in
        apt)
            # Add LLVM repository for latest clang
            wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | sudo tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc
            sudo add-apt-repository -y "deb http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main" || true

            # Add toolchain PPA for latest GCC
            sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test || true
            sudo apt update

            $PKG_INSTALL \
                build-essential \
                gcc-13 \
                g++-13 \
                gcc-14 \
                g++-14 \
                clang-18 \
                clang++-18 \
                clang-format-18 \
                clang-tidy-18 \
                lldb-18 \
                lld-18 \
                libc++-18-dev \
                libc++abi-18-dev \
                cmake \
                ninja-build \
                ccache \
                meson \
                autoconf \
                automake \
                libtool \
                pkg-config \
                libboost-all-dev \
                libeigen3-dev \
                libfmt-dev \
                libspdlog-dev \
                catch2 \
                libgtest-dev \
                libgmock-dev \
                libbenchmark-dev \
                valgrind \
                gdb \
                lldb-18 || true

            # Set GCC 13 as default if installed
            if command_exists gcc-13; then
                sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 || true
                sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 || true
            fi

            # Set Clang 18 as alternative
            if command_exists clang-18; then
                sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 || true
                sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 || true
            fi
            ;;
        pacman)
            $PKG_INSTALL \
                base-devel \
                gcc \
                clang \
                llvm \
                lld \
                lldb \
                libc++ \
                cmake \
                ninja \
                ccache \
                meson \
                autoconf \
                automake \
                libtool \
                pkgconf \
                boost \
                eigen \
                fmt \
                spdlog \
                catch2 \
                gtest \
                benchmark \
                valgrind \
                gdb || true
            ;;
        dnf|yum)
            $PKG_INSTALL \
                gcc \
                gcc-c++ \
                clang \
                llvm \
                lld \
                lldb \
                libcxx-devel \
                cmake \
                ninja-build \
                ccache \
                meson \
                autoconf \
                automake \
                libtool \
                pkgconfig \
                boost-devel \
                eigen3-devel \
                fmt-devel \
                spdlog-devel \
                gtest-devel \
                valgrind \
                gdb || true
            ;;
    esac

    success "C++23 build tools installed"
}

# =============================================================================
# Install Python Development Tools
# =============================================================================

install_python_dev_tools() {
    step "Installing Python development tools"

    case "$PKG_MANAGER" in
        apt)
            # Install essential packages first
            $PKG_INSTALL \
                python3 \
                python3-pip \
                python3-dev \
                python3-venv \
                python3-full \
                python3-setuptools \
                python3-wheel \
                python-is-python3 \
                libpython3-dev 2>/dev/null || true

            # Try to install optional packages individually (some may not exist in newer Ubuntu)
            local optional_packages=(
                "ipython3"
                "python3-pytest"
                "python3-pytest-cov"
                "python3-black"
                "python3-flake8"
                "python3-mypy"
                "python3-pylint"
                "python3-autopep8"
                "python3-rope"
                "python3-jedi"
                "cython3"
                "pipx"
            )

            for pkg in "${optional_packages[@]}"; do
                $PKG_INSTALL "$pkg" 2>/dev/null || info "Package $pkg not available, will install via pip/pipx"
            done
            ;;
        pacman)
            $PKG_INSTALL \
                python \
                python-pip \
                python-virtualenv \
                python-setuptools \
                python-wheel \
                ipython \
                python-pytest \
                python-pytest-cov \
                python-black \
                flake8 \
                mypy \
                python-pylint \
                autopep8 \
                python-rope \
                python-jedi \
                cython \
                python-pipx || true
            ;;
        dnf|yum)
            $PKG_INSTALL \
                python3 \
                python3-pip \
                python3-devel \
                python3-virtualenv \
                python3-setuptools \
                python3-wheel \
                ipython \
                python3-pytest \
                python3-black \
                python3-flake8 \
                python3-mypy \
                pylint \
                python3-autopep8 \
                python3-rope \
                python3-jedi \
                Cython \
                pipx || true
            ;;
    esac

    # Install pipx for isolated tool installation
    if ! command_exists pipx; then
        info "Installing pipx..."
        # Use --break-system-packages for user installs (safe since it's isolated to user)
        python3 -m pip install --user --break-system-packages pipx 2>/dev/null || {
            warning "Failed to install pipx via pip"
        }
        # Ensure pipx is in PATH
        export PATH="$HOME/.local/bin:$PATH"
        if command_exists pipx; then
            python3 -m pipx ensurepath 2>/dev/null || true
        fi
    fi

    # Install pyenv for Python version management
    if [ ! -d "$HOME/.pyenv" ]; then
        info "Installing pyenv..."
        if curl -s https://pyenv.run 2>/dev/null | bash 2>/dev/null; then
            # Add to bashrc if not present
            if ! grep -q 'pyenv init' ~/.bashrc; then
                cat >> ~/.bashrc << 'EOF'

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
EOF
            fi
        else
            warning "Failed to install pyenv, skipping..."
        fi
    fi

    # Install poetry for dependency management
    if ! command_exists poetry; then
        info "Installing poetry..."
        if curl -sSL https://install.python-poetry.org 2>/dev/null | python3 - 2>/dev/null; then
            export PATH="$HOME/.local/bin:$PATH"
            success "poetry installed"
        else
            warning "Failed to install poetry, skipping..."
        fi
    fi

    # Install common Python dev tools via pipx (preferred) or pip
    if command_exists pipx; then
        info "Installing Python tools via pipx..."
        local pipx_tools=(
            "black"
            "ruff"
            "isort"
            "mypy"
            "pylint"
            "flake8"
            "pytest"
            "ipython"
        )

        for tool in "${pipx_tools[@]}"; do
            if ! command_exists "$tool"; then
                pipx install "$tool" 2>/dev/null || info "$tool installation skipped"
            fi
        done
    else
        info "Installing Python tools via pip (--user)..."
        # Use --break-system-packages with --user flag (safe for user installs)
        python3 -m pip install --user --break-system-packages --upgrade \
            pip \
            setuptools \
            wheel \
            virtualenv \
            black \
            ruff \
            isort \
            mypy \
            pylint \
            flake8 \
            pytest \
            pytest-cov \
            ipython \
            jupyterlab \
            numpy \
            pandas \
            requests 2>/dev/null || warning "Some Python packages failed to install"
    fi

    success "Python development tools installation completed"
}

# =============================================================================
# Install Additional Rust Utilities
# =============================================================================

install_rust_utilities() {
    step "Installing additional Rust utilities"

    # Ensure Rust is installed
    if ! command_exists cargo; then
        install_rust_tools
    fi

    # Source cargo env to ensure it's in PATH
    [ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

    # Install useful Rust CLI tools one by one to avoid termination on failure
    info "Installing Rust utilities (this may take a while)..."

    local rust_tools=(
        "cargo-edit"
        "cargo-watch"
        "cargo-audit"
        "cargo-outdated"
        "cargo-tree"
        "cargo-expand"
        "cargo-bloat"
        "tokei"
        "hyperfine"
        "sd"
        "procs"
        "grex"
        "zellij"
    )

    for tool in "${rust_tools[@]}"; do
        if ! command_exists "$tool"; then
            info "Installing $tool..."
            cargo install "$tool" 2>/dev/null || warning "Failed to install $tool (skipping)"
        else
            info "$tool already installed"
        fi
    done

    success "Rust utilities installation completed"
}

# =============================================================================
# Build Neovim from Source
# =============================================================================

build_neovim_from_source() {
    step "Building Neovim from source"

    # Install build dependencies
    info "Installing Neovim build dependencies..."

    case "$PKG_MANAGER" in
        apt)
            $PKG_INSTALL \
                ninja-build \
                gettext \
                cmake \
                unzip \
                curl \
                build-essential \
                libtool \
                libtool-bin \
                autoconf \
                automake \
                cmake \
                g++ \
                pkg-config \
                doxygen \
                libluajit-5.1-dev \
                libunibilium-dev \
                libmsgpack-dev \
                libtermkey-dev \
                libvterm-dev \
                libutf8proc-dev \
                luajit \
                lua5.1 \
                liblua5.1-dev || true
            ;;
        pacman)
            $PKG_INSTALL \
                base-devel \
                cmake \
                unzip \
                ninja \
                curl \
                tree-sitter \
                libtool \
                autoconf \
                automake \
                pkg-config \
                gettext \
                luajit \
                msgpack-c \
                libtermkey \
                libvterm \
                utf8proc || true
            ;;
        dnf|yum)
            $PKG_INSTALL \
                ninja-build \
                cmake \
                gcc \
                gcc-c++ \
                make \
                unzip \
                gettext \
                curl \
                autoconf \
                automake \
                libtool \
                pkgconfig \
                msgpack-devel \
                libtermkey-devel \
                libvterm-devel \
                utf8proc-devel \
                luajit-devel || true
            ;;
    esac

    # Clone and build Neovim
    info "Cloning Neovim repository..."
    NVIM_BUILD_DIR="/tmp/neovim-build-$$"
    git clone https://github.com/neovim/neovim "$NVIM_BUILD_DIR"
    cd "$NVIM_BUILD_DIR"

    # Checkout stable version
    git checkout stable

    info "Building Neovim (this will take several minutes)..."
    make CMAKE_BUILD_TYPE=RelWithDebInfo 
    cd build && cpack -G DEB && sudo dpkg -i nvim-linux-x86_64.deb

    # Cleanup
    cd - > /dev/null
    rm -rf "$NVIM_BUILD_DIR"

    success "Neovim built and installed to ~/.local/bin/nvim"
}

# =============================================================================
# Setup AstroNvim with Dependencies
# =============================================================================

setup_astronvim() {
    step "Setting up AstroNvim"

    # Install AstroNvim dependencies
    info "Installing AstroNvim dependencies..."

    # Tree-sitter CLI
    if ! command_exists tree-sitter; then
        case "$PKG_MANAGER" in
            apt)
                $PKG_INSTALL libtree-sitter-dev || cargo install tree-sitter-cli
                ;;
            pacman)
                $PKG_INSTALL tree-sitter tree-sitter-cli
                ;;
            dnf|yum)
                cargo install tree-sitter-cli
                ;;
        esac
    fi

    # Node.js for LSP servers
    if ! command_exists node; then
        info "Installing Node.js via NVM for LSP servers..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm use --lts
    fi

    # Language servers and tools
    info "Installing language servers..."
    npm install -g \
        bash-language-server \
        typescript-language-server \
        vscode-langservers-extracted \
        yaml-language-server \
        dockerfile-language-server-nodejs \
        pyright \
        @tailwindcss/language-server \
        graphql-language-service-cli 2>/dev/null || true

    # Python language servers
    python3 -m pip install --user \
        python-lsp-server \
        pyls-flake8 \
        pylsp-mypy \
        python-lsp-black 2>/dev/null || true

    # Rust analyzer (if Rust installed)
    if command_exists rustup; then
        rustup component add rust-analyzer
    fi

    # Backup existing nvim config
    if [ -d ~/.config/nvim ]; then
        info "Backing up existing nvim config..."
        mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d-%H%M%S)
    fi

    if [ -d ~/.local/share/nvim ]; then
        mv ~/.local/share/nvim ~/.local/share/nvim.backup.$(date +%Y%m%d-%H%M%S)
    fi

    if [ -d ~/.local/state/nvim ]; then
        mv ~/.local/state/nvim ~/.local/state/nvim.backup.$(date +%Y%m%d-%H%M%S)
    fi

    if [ -d ~/.cache/nvim ]; then
        mv ~/.cache/nvim ~/.cache/nvim.backup.$(date +%Y%m%d-%H%M%S)
    fi

    # Clone AstroNvim
    info "Cloning AstroNvim..."
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim

    # Remove .git folder for clean start
    rm -rf ~/.config/nvim/.git

    success "AstroNvim installed!"
    info "Run 'nvim' to complete the setup (plugins will auto-install)"
}

# =============================================================================
# Install Docker
# =============================================================================

install_docker() {
    step "Installing Docker"

    if command_exists docker; then
        info "Docker already installed"
        return
    fi

    case "$PKG_MANAGER" in
        apt)
            # Remove old versions
	    sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)

            # Install Docker
	    # Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            # Enable and start Docker
            sudo systemctl enable docker
            sudo systemctl start docker

            # Add user to docker group
            sudo usermod -aG docker "$USER"
            ;;
        pacman)
            $PKG_INSTALL docker docker-compose
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
        dnf|yum)
            $PKG_INSTALL dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || \
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $PKG_INSTALL docker-ce docker-ce-cli containerd.io docker-compose-plugin
            sudo systemctl enable docker
            sudo systemctl start docker
            sudo usermod -aG docker "$USER"
            ;;
    esac

    success "Docker installed (you may need to logout/login for group changes)"
}

# =============================================================================
# Install Kubernetes Tools
# =============================================================================

install_kubernetes_tools() {
    step "Installing Kubernetes tools (kubectl, helm, minikube, kind)"

    # Install kubectl
    if ! command_exists kubectl; then
        info "Installing kubectl..."
        KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null || echo "")

        if [ -z "$KUBECTL_VERSION" ]; then
            warning "Could not fetch kubectl version, skipping..."
        else
            if curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" 2>/dev/null; then
                chmod +x kubectl 2>/dev/null || true
                mv kubectl ~/.local/bin/ 2>/dev/null || { warning "Failed to install kubectl"; rm -f kubectl; }

                if command_exists kubectl; then
                    success "kubectl installed"
                else
                    warning "kubectl installation failed"
                fi
            else
                warning "Failed to download kubectl, skipping..."
            fi
        fi
    else
        info "kubectl already installed"
    fi

    # Install helm
    if ! command_exists helm; then
        info "Installing helm..."
        if curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 2>/dev/null | bash 2>/dev/null; then
            success "helm installed"
        else
            warning "Failed to install helm, skipping..."
        fi
    else
        info "helm already installed"
    fi

    # Install minikube
    if ! command_exists minikube; then
        info "Installing minikube..."
        if curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 2>/dev/null; then
            chmod +x minikube-linux-amd64 2>/dev/null || true
            mv minikube-linux-amd64 ~/.local/bin/minikube 2>/dev/null || { warning "Failed to install minikube"; rm -f minikube-linux-amd64; }

            if command_exists minikube; then
                success "minikube installed"
            else
                warning "minikube installation failed"
            fi
        else
            warning "Failed to download minikube, skipping..."
        fi
    else
        info "minikube already installed"
    fi

    # Install kind (Kubernetes in Docker)
    if ! command_exists kind; then
        info "Installing kind..."
        # Detect architecture
        ARCH=$(uname -m)
        case $ARCH in
            x86_64)  ARCH="amd64" ;;
            aarch64) ARCH="arm64" ;;
            *)       warning "Skipping kind - unsupported architecture: $ARCH"; return 0 ;;
        esac

        KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' 2>/dev/null || echo "")

        if [ -z "$KIND_VERSION" ]; then
            warning "Could not fetch kind version, skipping..."
        else
            if curl -Lo ./kind "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-${ARCH}" 2>/dev/null; then
                chmod +x ./kind 2>/dev/null || true
                mv ./kind ~/.local/bin/kind 2>/dev/null || { warning "Failed to install kind"; rm -f kind; }

                if command_exists kind; then
                    success "kind installed"
                else
                    warning "kind installation failed"
                fi
            else
                warning "Failed to download kind, skipping..."
            fi
        fi
    else
        info "kind already installed"
    fi

    # Install kubectx and kubens
    if ! command_exists kubectx; then
        info "Installing kubectx and kubens..."
        if sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx 2>/dev/null || (cd /opt/kubectx && sudo git pull 2>/dev/null); then
            sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx 2>/dev/null || true
            sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens 2>/dev/null || true
            success "kubectx and kubens installed"
        else
            warning "Failed to install kubectx/kubens, skipping..."
        fi
    else
        info "kubectx already installed"
    fi
}

# =============================================================================
# Install ble.sh (Bash Auto-suggestions)
# =============================================================================

install_blesh() {
    step "Installing ble.sh (bash auto-suggestions)"

    # Install gawk (required for building ble.sh)
    if ! command_exists gawk; then
        info "Installing gawk (required for ble.sh)..."
        case "$PKG_MANAGER" in
            apt)
                $PKG_INSTALL gawk 2>/dev/null || { warning "Failed to install gawk, skipping ble.sh"; return 0; }
                ;;
            pacman)
                $PKG_INSTALL gawk 2>/dev/null || { warning "Failed to install gawk, skipping ble.sh"; return 0; }
                ;;
            dnf|yum)
                $PKG_INSTALL gawk 2>/dev/null || { warning "Failed to install gawk, skipping ble.sh"; return 0; }
                ;;
        esac
    fi

    if [[ -d ~/.local/share/blesh ]]; then
        info "Updating ble.sh..."
        cd ~/.local/share/blesh || { warning "Failed to access ble.sh directory"; return 0; }

        if git pull 2>/dev/null; then
            if make install PREFIX=~/.local 2>/dev/null; then
                success "ble.sh updated"
            else
                warning "Failed to build ble.sh update, skipping..."
            fi
        else
            warning "Failed to update ble.sh, skipping..."
        fi
        cd - > /dev/null
    else
        info "Installing ble.sh..."
        if git clone --recursive --depth 1 --shallow-submodules \
            https://github.com/akinomyoga/ble.sh.git ~/.local/share/blesh 2>/dev/null; then

            if make -C ~/.local/share/blesh install PREFIX=~/.local 2>/dev/null; then
                success "ble.sh installed"
            else
                warning "Failed to build ble.sh, skipping..."
                rm -rf ~/.local/share/blesh
            fi
        else
            warning "Failed to clone ble.sh repository, skipping..."
        fi
    fi
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
        *)       warning "Unsupported architecture: $ARCH, skipping lazydocker"; return 0 ;;
    esac

    LATEST_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "")

    if [ -z "$LATEST_VERSION" ]; then
        warning "Could not fetch lazydocker version from GitHub API, skipping..."
        return 0
    fi

    DOWNLOAD_URL="https://github.com/jesseduffield/lazydocker/releases/download/v${LATEST_VERSION}/lazydocker_${LATEST_VERSION}_Linux_${ARCH}.tar.gz"

    info "Downloading lazydocker v${LATEST_VERSION}..."
    if wget -q --show-progress "$DOWNLOAD_URL" -O /tmp/lazydocker.tar.gz 2>/dev/null; then
        tar xzf /tmp/lazydocker.tar.gz -C /tmp 2>/dev/null || { warning "Failed to extract lazydocker"; return 0; }
        if [ -f /tmp/lazydocker ]; then
            mv /tmp/lazydocker ~/.local/bin/ 2>/dev/null || { warning "Failed to move lazydocker"; return 0; }
            chmod +x ~/.local/bin/lazydocker 2>/dev/null || true
        fi
        rm -f /tmp/lazydocker.tar.gz

        if command_exists lazydocker; then
            success "lazydocker installed"
        else
            warning "lazydocker installation failed"
        fi
    else
        warning "Failed to download lazydocker, skipping..."
    fi
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
        *)       warning "Unsupported architecture: $ARCH, skipping k9s"; return 0 ;;
    esac

    LATEST_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "")

    if [ -z "$LATEST_VERSION" ]; then
        warning "Could not fetch k9s version from GitHub API, skipping..."
        return 0
    fi

    DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/v${LATEST_VERSION}/k9s_Linux_${ARCH}.tar.gz"

    info "Downloading k9s v${LATEST_VERSION}..."
    if wget -q --show-progress "$DOWNLOAD_URL" -O /tmp/k9s.tar.gz 2>/dev/null; then
        tar xzf /tmp/k9s.tar.gz -C /tmp 2>/dev/null || { warning "Failed to extract k9s"; return 0; }
        if [ -f /tmp/k9s ]; then
            mv /tmp/k9s ~/.local/bin/ 2>/dev/null || { warning "Failed to move k9s"; return 0; }
            chmod +x ~/.local/bin/k9s 2>/dev/null || true
        fi
        rm -f /tmp/k9s.tar.gz

        if command_exists k9s; then
            success "k9s installed"
        else
            warning "k9s installation failed"
        fi
    else
        warning "Failed to download k9s, skipping..."
    fi
}

# =============================================================================
# Setup Configuration Files
# =============================================================================

setup_configs() {
    step "Setting up configuration files"

    # Backup existing configs
    backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup existing files
    [ -f ~/.bashrc ] && cp ~/.bashrc "$backup_dir/"
    [ -f ~/.bash_aliases ] && cp ~/.bash_aliases "$backup_dir/"
    [ -f ~/.gitconfig ] && cp ~/.gitconfig "$backup_dir/"
    [ -f ~/.inputrc ] && cp ~/.inputrc "$backup_dir/"

    info "Backed up existing configs to: $backup_dir"

    # Symlink or copy configs
    if [ -d "$SCRIPT_DIR" ]; then
        info "Symlinking configuration files..."

        # Bash configs
        ln -sf "$SCRIPT_DIR/bashrc" ~/.bashrc
        ln -sf "$SCRIPT_DIR/.bash_aliases" ~/.bash_aliases
        ln -sf "$SCRIPT_DIR/.inputrc" ~/.inputrc

        # Git config
        ln -sf "$SCRIPT_DIR/.gitconfig" ~/.gitconfig
        ln -sf "$SCRIPT_DIR/.ripgreprc" ~/.ripgreprc

        # Tmux
        mkdir -p ~/.config/tmux
        ln -sf "$SCRIPT_DIR/tmux/tmux.conf" ~/.config/tmux/tmux.conf

        # Alacritty
        mkdir -p ~/.config/alacritty
        ln -sf "$SCRIPT_DIR/alacritty/alacritty.toml" ~/.config/alacritty/alacritty.toml

        # Oh-my-posh theme
        mkdir -p ~/.config
        ln -sf "$SCRIPT_DIR/oh-my-posh/dark-colorblind.omp.json" ~/.config/oh-my-posh-dark-colorblind.omp.json

        # Neovim
        mkdir -p ~/.config/nvim
        [ -d "$SCRIPT_DIR/nvim" ] && ln -sf "$SCRIPT_DIR/nvim" ~/.config/nvim

        # k9s
        mkdir -p ~/.config/k9s/skins
        [ -f "$SCRIPT_DIR/k9s/config.yaml" ] && ln -sf "$SCRIPT_DIR/k9s/config.yaml" ~/.config/k9s/config.yaml
        [ -f "$SCRIPT_DIR/k9s/skins/github-dark.yaml" ] && ln -sf "$SCRIPT_DIR/k9s/skins/github-dark.yaml" ~/.config/k9s/skins/github-dark.yaml

        # lazydocker
        mkdir -p ~/.config/lazydocker
        [ -f "$SCRIPT_DIR/lazydocker/config.yml" ] && ln -sf "$SCRIPT_DIR/lazydocker/config.yml" ~/.config/lazydocker/config.yml

        # Bin scripts
        mkdir -p ~/bin
        if [ -d "$SCRIPT_DIR/bin" ]; then
            for script in "$SCRIPT_DIR/bin"/*; do
                [ -f "$script" ] && ln -sf "$script" ~/bin/$(basename "$script")
            done
        fi

        success "Configuration files symlinked"
    else
        error "Config directory not found: $SCRIPT_DIR"
        return 1
    fi
}

# =============================================================================
# Install Tmux Plugin Manager
# =============================================================================

install_tmux_plugins() {
    step "Installing Tmux Plugin Manager"

    if [ ! -d ~/.tmux/plugins/tpm ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        success "TPM installed"
        info "Run 'tmux' and press Ctrl+g + I to install tmux plugins"
    else
        info "TPM already installed"
    fi
}

# =============================================================================
# Create k9s/lazydocker configs
# =============================================================================

create_tool_configs() {
    step "Creating k9s and lazydocker configurations"

    # Create k9s config directory
    mkdir -p ~/.config/k9s/skins

    # Only create if doesn't exist (don't overwrite symlinks)
    if [ ! -f ~/.config/k9s/config.yaml ]; then
        cat > ~/.config/k9s/config.yaml << 'EOF'
k9s:
  liveViewAutoRefresh: false
  refreshRate: 2
  maxConnRetry: 3
  readOnly: false
  ui:
    enableMouse: true
    headless: false
    logoless: false
    skin: github-dark
  logger:
    tail: 100
    buffer: 5000
    sinceSeconds: 60
EOF
    fi

    if [ ! -f ~/.config/k9s/skins/github-dark.yaml ]; then
        # Copy the skin from the script directory or create default
        if [ -f "$SCRIPT_DIR/k9s/skins/github-dark.yaml" ]; then
            cp "$SCRIPT_DIR/k9s/skins/github-dark.yaml" ~/.config/k9s/skins/
        fi
    fi

    # Create lazydocker config
    mkdir -p ~/.config/lazydocker
    if [ ! -f ~/.config/lazydocker/config.yml ] && [ -f "$SCRIPT_DIR/lazydocker/config.yml" ]; then
        cp "$SCRIPT_DIR/lazydocker/config.yml" ~/.config/lazydocker/
    fi

    success "Tool configurations created"
}

# =============================================================================
# Final Setup
# =============================================================================

final_setup() {
    step "Final setup and verification"

    # Ensure ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && [[ ":$PATH:" != *":~/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi

    # Ensure ~/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/bin:"* ]] && [[ ":$PATH:" != *":~/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
    fi

    success "Setup complete!"
}

# =============================================================================
# Print Summary
# =============================================================================

print_summary() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                    Setup Complete!                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${CYAN}📦 Installed Tools:${NC}"
    echo ""
    echo -e "${MAGENTA}Modern CLI Tools:${NC}"
    echo -e "  ${GREEN}✓${NC} bat, eza, ripgrep, fd, fzf, lazygit"
    echo -e "  ${GREEN}✓${NC} btop/bottom, dust, duf"
    echo -e "  ${GREEN}✓${NC} zoxide, sesh, tmux, neovim"
    echo ""
    echo -e "${MAGENTA}Container & Orchestration:${NC}"
    echo -e "  ${GREEN}✓${NC} Docker + Docker Compose"
    echo -e "  ${GREEN}✓${NC} lazydocker (TUI for Docker)"
    echo ""
    echo -e "${MAGENTA}Kubernetes Tools:${NC}"
    echo -e "  ${GREEN}✓${NC} kubectl (K8s CLI)"
    echo -e "  ${GREEN}✓${NC} helm (K8s package manager)"
    echo -e "  ${GREEN}✓${NC} minikube (local K8s cluster)"
    echo -e "  ${GREEN}✓${NC} kind (Kubernetes in Docker)"
    echo -e "  ${GREEN}✓${NC} k9s (K8s TUI)"
    echo -e "  ${GREEN}✓${NC} kubectx & kubens (context/namespace switcher)"
    echo ""
    echo -e "${MAGENTA}Multimedia & Development Libraries:${NC}"
    echo -e "  ${GREEN}✓${NC} FFmpeg + full codec support"
    echo -e "  ${GREEN}✓${NC} WebRTC libraries (opus, vpx, x264, x265, etc.)"
    echo -e "  ${GREEN}✓${NC} Video/Audio processing libs"
    echo ""
    echo -e "${MAGENTA}C++ Build Tools (C++23 Support):${NC}"
    echo -e "  ${GREEN}✓${NC} GCC 13/14 + Clang 18"
    echo -e "  ${GREEN}✓${NC} CMake, Ninja, Meson"
    echo -e "  ${GREEN}✓${NC} vcpkg (C++ package manager)"
    echo -e "  ${GREEN}✓${NC} Boost, Eigen, fmt, spdlog"
    echo -e "  ${GREEN}✓${NC} GoogleTest, Catch2, Benchmark"
    echo -e "  ${GREEN}✓${NC} Valgrind, GDB, LLDB"
    echo ""
    echo -e "${MAGENTA}Programming Languages:${NC}"
    echo -e "  ${GREEN}✓${NC} Golang (latest stable version)"
    echo -e "  ${GREEN}✓${NC} Rust + Cargo + utilities"
    echo -e "  ${GREEN}✓${NC} Python (pyenv, poetry, pip tools)"
    echo -e "  ${GREEN}✓${NC} NVM (Node.js version manager)"
    echo ""
    echo -e "${MAGENTA}Neovim & AstroNvim:${NC}"
    echo -e "  ${GREEN}✓${NC} Neovim (built from source - latest)"
    echo -e "  ${GREEN}✓${NC} AstroNvim (fully configured)"
    echo -e "  ${GREEN}✓${NC} Tree-sitter (syntax highlighting)"
    echo -e "  ${GREEN}✓${NC} Language servers (8+ LSPs installed)"
    echo -e "  ${GREEN}✓${NC} Rust-analyzer, Pyright, TypeScript, etc."
    echo ""
    echo -e "${MAGENTA}Terminal & Fonts:${NC}"
    echo -e "  ${GREEN}✓${NC} Alacritty (GPU-accelerated terminal)"
    echo -e "  ${GREEN}✓${NC} FiraCode Nerd Font (with icons)"
    echo -e "  ${GREEN}✓${NC} Tmux (with 5 plugins)"
    echo ""
    echo -e "${MAGENTA}Shell Enhancements:${NC}"
    echo -e "  ${GREEN}✓${NC} ble.sh (auto-suggestions & syntax highlighting)"
    echo -e "  ${GREEN}✓${NC} oh-my-posh (beautiful prompt)"
    echo -e "  ${GREEN}✓${NC} zoxide (smart directory jumper)"
    echo ""
    echo -e "${MAGENTA}Rust Utilities:${NC}"
    echo -e "  ${GREEN}✓${NC} cargo-edit, cargo-watch, cargo-audit"
    echo -e "  ${GREEN}✓${NC} tokei, hyperfine, sd, procs"
    echo -e "  ${GREEN}✓${NC} zellij (terminal multiplexer)"
    echo ""
    echo -e "${MAGENTA}Configurations:${NC}"
    echo -e "  ${GREEN}✓${NC} bashrc, bash_aliases (60+ aliases)"
    echo -e "  ${GREEN}✓${NC} gitconfig, inputrc, ripgreprc"
    echo -e "  ${GREEN}✓${NC} tmux.conf (Zellij-style keybindings)"
    echo -e "  ${GREEN}✓${NC} alacritty.toml (GitHub Dark theme)"
    echo -e "  ${GREEN}✓${NC} k9s, lazydocker, neovim configs"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo ""
    echo "  1. ${YELLOW}Reload your shell:${NC}"
    echo "     source ~/.bashrc"
    echo ""
    echo "  2. ${YELLOW}Start tmux and install plugins:${NC}"
    echo "     tmux"
    echo "     # Press Ctrl+g then Shift+I to install plugins"
    echo ""
    echo "  3. ${YELLOW}Try Docker:${NC}"
    echo "     docker run hello-world"
    echo "     lzd         # LazyDocker TUI"
    echo ""
    echo "  4. ${YELLOW}Setup Kubernetes (choose one):${NC}"
    echo "     minikube start              # Local cluster (easiest)"
    echo "     kind create cluster         # K8s in Docker (lightweight)"
    echo "     k9s                         # Kubernetes TUI"
    echo ""
    echo "  5. ${YELLOW}Test CLI tools:${NC}"
    echo "     ll          # eza with icons"
    echo "     frg         # Search with preview"
    echo "     zi          # Interactive directory jump"
    echo "     lazygit     # Git TUI"
    echo ""
    echo "  6. ${YELLOW}Install fonts for icons:${NC}"
    echo "     https://www.nerdfonts.com/font-downloads"
    echo "     Recommended: FiraCode Nerd Font"
    echo ""
    if groups | grep -q docker; then
        echo -e "${GREEN}✓${NC} You're in the docker group"
    else
        echo -e "${YELLOW}!${NC} Logout and login again to use Docker without sudo"
    fi
    echo ""
    echo -e "${CYAN}📚 Documentation:${NC}"
    echo "  - Quick Start: ~/configs/README.md"
    echo "  - Full Guide:  ~/configs/BOOTSTRAP.md"
    echo "  - Tmux Keys:   ~/configs/tmux/keyboard-shortcuts.md"
    echo ""
}

# =============================================================================
# Interactive Menu
# =============================================================================

show_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     Universal Linux Development Environment Bootstrap      ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Select installation type:"
    echo ""
    echo "  1) Full Installation (Everything)"
    echo "  2) Minimal (CLI tools + configs only)"
    echo "  3) Custom (Choose components)"
    echo "  4) Exit"
    echo ""
    read -p "Enter choice [1-4]: " choice

    case $choice in
        1) full_installation ;;
        2) minimal_installation ;;
        3) custom_installation ;;
        4) exit 0 ;;
        *) error "Invalid choice"; show_menu ;;
    esac
}

full_installation() {
    detect_distro
    install_base_packages
    install_modern_cli_tools
    install_multimedia_tools
    install_cpp_build_tools
    install_python_dev_tools
    install_golang
    install_vcpkg
    install_rust_utilities
    install_zoxide
    install_oh_my_posh
    install_sesh
    install_nvm
    install_alacritty
    install_nerd_fonts
    install_docker
    install_kubernetes_tools
    install_blesh
    install_lazydocker
    install_k9s
    build_neovim_from_source
    setup_astronvim
    setup_configs
    install_tmux_plugins
    create_tool_configs
    final_setup
    print_summary
}

minimal_installation() {
    detect_distro
    install_base_packages
    install_modern_cli_tools
    install_zoxide
    install_oh_my_posh
    install_sesh
    install_blesh
    setup_configs
    install_tmux_plugins
    final_setup
    print_summary
}

custom_installation() {
    detect_distro
    install_base_packages

    echo ""
    echo "Select components to install (space-separated numbers):"
    echo "   1) Modern CLI tools (bat, eza, ripgrep, fzf, etc.)"
    echo "   2) Multimedia tools (FFmpeg, WebRTC libs)"
    echo "   3) C++23 build tools (GCC 14, Clang 18, CMake, etc.)"
    echo "   4) Python dev tools (pyenv, poetry, pip tools)"
    echo "   5) Golang"
    echo "   6) vcpkg (C++ package manager)"
    echo "   7) Rust utilities (cargo tools, zellij, etc.)"
    echo "   8) Zoxide (smart cd)"
    echo "   9) Oh-my-posh (prompt)"
    echo "  10) Sesh (tmux session manager)"
    echo "  11) NVM (Node Version Manager)"
    echo "  12) Alacritty (terminal emulator)"
    echo "  13) FiraCode Nerd Font"
    echo "  14) Docker + Docker Compose"
    echo "  15) Kubernetes tools (kubectl, helm, minikube, kind, k9s, kubectx)"
    echo "  16) ble.sh (bash auto-suggestions)"
    echo "  17) lazydocker + k9s (TUIs)"
    echo "  18) Build Neovim from source"
    echo "  19) Setup AstroNvim with all dependencies"
    echo ""
    read -p "Components: " -a components

    for comp in "${components[@]}"; do
        case $comp in
            1) install_modern_cli_tools ;;
            2) install_multimedia_tools ;;
            3) install_cpp_build_tools ;;
            4) install_python_dev_tools ;;
            5) install_golang ;;
            6) install_vcpkg ;;
            7) install_rust_utilities ;;
            8) install_zoxide ;;
            9) install_oh_my_posh ;;
            10) install_sesh ;;
            11) install_nvm ;;
            12) install_alacritty ;;
            13) install_nerd_fonts ;;
            14) install_docker ;;
            15) install_kubernetes_tools ;;
            16) install_blesh ;;
            17) install_lazydocker; install_k9s ;;
            18) build_neovim_from_source ;;
            19) setup_astronvim ;;
        esac
    done

    setup_configs
    install_tmux_plugins
    create_tool_configs
    final_setup
    print_summary
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root!"
        exit 1
    fi

    # Check for arguments
    if [ "$1" = "--full" ]; then
        full_installation
    elif [ "$1" = "--minimal" ]; then
        minimal_installation
    elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [--full|--minimal|--help]"
        echo ""
        echo "  --full     Full installation (all components)"
        echo "  --minimal  Minimal installation (CLI tools + configs)"
        echo "  --help     Show this help message"
        echo ""
        echo "Run without arguments for interactive menu"
        exit 0
    else
        show_menu
    fi
}

main "$@"
