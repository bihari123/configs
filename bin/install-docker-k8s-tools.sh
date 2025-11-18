#!/usr/bin/env bash
# =============================================================================
# Docker & Kubernetes Tools Installer
# =============================================================================
# Installs: lazydocker, k9s, and bash auto-suggestions (ble.sh)
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# 1. Install ble.sh (Bash Line Editor with auto-suggestions)
# =============================================================================
install_blesh() {
    info "Installing ble.sh (Bash auto-suggestions & syntax highlighting)..."

    if [[ -d ~/.local/share/blesh ]]; then
        warning "ble.sh already installed, updating..."
        cd ~/.local/share/blesh
        git pull
        make install PREFIX=~/.local
    else
        git clone --recursive --depth 1 --shallow-submodules \
            https://github.com/akinomyoga/ble.sh.git ~/.local/share/blesh
        make -C ~/.local/share/blesh install PREFIX=~/.local
    fi

    success "ble.sh installed! Restart your shell to activate."
}

# =============================================================================
# 2. Install lazydocker (Docker TUI)
# =============================================================================
install_lazydocker() {
    info "Installing lazydocker..."

    if command_exists lazydocker; then
        warning "lazydocker already installed at: $(which lazydocker)"
        read -p "Reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Skipping lazydocker installation"
            return
        fi
    fi

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="x86_64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="armv7" ;;
        *)       error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest release
    info "Fetching latest lazydocker release..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

    if [[ -z "$LATEST_VERSION" ]]; then
        error "Failed to fetch latest version"
        return 1
    fi

    info "Latest version: v${LATEST_VERSION}"

    # Download and install
    DOWNLOAD_URL="https://github.com/jesseduffield/lazydocker/releases/download/v${LATEST_VERSION}/lazydocker_${LATEST_VERSION}_Linux_${ARCH}.tar.gz"

    info "Downloading from: $DOWNLOAD_URL"

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    curl -L "$DOWNLOAD_URL" -o lazydocker.tar.gz
    tar xzf lazydocker.tar.gz

    # Install to ~/.local/bin
    mkdir -p ~/.local/bin
    mv lazydocker ~/.local/bin/
    chmod +x ~/.local/bin/lazydocker

    # Cleanup
    rm -rf "$TMP_DIR"

    success "lazydocker v${LATEST_VERSION} installed to ~/.local/bin/lazydocker"
}

# =============================================================================
# 3. Install k9s (Kubernetes TUI)
# =============================================================================
install_k9s() {
    info "Installing k9s..."

    if command_exists k9s; then
        warning "k9s already installed at: $(which k9s)"
        read -p "Reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Skipping k9s installation"
            return
        fi
    fi

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="arm" ;;
        *)       error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest release
    info "Fetching latest k9s release..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')

    if [[ -z "$LATEST_VERSION" ]]; then
        error "Failed to fetch latest version"
        return 1
    fi

    info "Latest version: v${LATEST_VERSION}"

    # Download and install
    DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/v${LATEST_VERSION}/k9s_Linux_${ARCH}.tar.gz"

    info "Downloading from: $DOWNLOAD_URL"

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    curl -L "$DOWNLOAD_URL" -o k9s.tar.gz
    tar xzf k9s.tar.gz

    # Install to ~/.local/bin
    mkdir -p ~/.local/bin
    mv k9s ~/.local/bin/
    chmod +x ~/.local/bin/k9s

    # Cleanup
    rm -rf "$TMP_DIR"

    success "k9s v${LATEST_VERSION} installed to ~/.local/bin/k9s"
}

# =============================================================================
# 4. Create k9s configuration
# =============================================================================
configure_k9s() {
    info "Creating k9s configuration..."

    K9S_CONFIG_DIR=~/.config/k9s
    mkdir -p "$K9S_CONFIG_DIR"

    # Create config.yaml if it doesn't exist
    if [[ ! -f "$K9S_CONFIG_DIR/config.yaml" ]]; then
        cat > "$K9S_CONFIG_DIR/config.yaml" << 'EOF'
k9s:
  # Refresh rate in seconds
  refreshRate: 2

  # Max number of logs lines
  maxConnRetry: 5

  # Enable mouse support
  enableMouse: true

  # Show all resources including CRDs
  headless: false

  # Logo display
  logoless: false

  # Cluster read only mode
  readOnly: false

  # UI Settings
  ui:
    # Enable color
    enableMouse: true
    headless: false
    logoless: false
    crumbsless: false
    reactive: false
    noIcons: false

  # Logger settings
  logger:
    # Log file location
    tail: 100
    buffer: 5000
    sinceSeconds: 60
    fullScreenLogs: false
    textWrap: false
    showTime: false

  # Skin/Theme - GitHub Dark inspired
  skin: github-dark
EOF
        success "k9s config created at $K9S_CONFIG_DIR/config.yaml"
    else
        info "k9s config already exists, skipping"
    fi

    # Create skin file
    if [[ ! -f "$K9S_CONFIG_DIR/skins/github-dark.yaml" ]]; then
        mkdir -p "$K9S_CONFIG_DIR/skins"
        cat > "$K9S_CONFIG_DIR/skins/github-dark.yaml" << 'EOF'
# GitHub Dark theme for k9s
k9s:
  body:
    fgColor: "#c9d1d9"
    bgColor: "#0d1117"
    logoColor: "#58a6ff"
  prompt:
    fgColor: "#c9d1d9"
    bgColor: "#0d1117"
    suggestColor: "#58a6ff"
  info:
    fgColor: "#ff7b72"
    sectionColor: "#c9d1d9"
  dialog:
    fgColor: "#c9d1d9"
    bgColor: "#0d1117"
    buttonFgColor: "#0d1117"
    buttonBgColor: "#58a6ff"
    buttonFocusFgColor: "#ffffff"
    buttonFocusBgColor: "#1f6feb"
    labelFgColor: "#79c0ff"
    fieldFgColor: "#c9d1d9"
  frame:
    border:
      fgColor: "#30363d"
      focusColor: "#58a6ff"
    menu:
      fgColor: "#c9d1d9"
      keyColor: "#ff7b72"
      numKeyColor: "#ff7b72"
    crumbs:
      fgColor: "#c9d1d9"
      bgColor: "#0d1117"
      activeColor: "#58a6ff"
    status:
      newColor: "#3fb950"
      modifyColor: "#d29922"
      addColor: "#79c0ff"
      errorColor: "#f85149"
      highlightColor: "#79c0ff"
      killColor: "#8b949e"
      completedColor: "#8b949e"
    title:
      fgColor: "#c9d1d9"
      bgColor: "#0d1117"
      highlightColor: "#58a6ff"
      counterColor: "#d29922"
      filterColor: "#ff7b72"
  views:
    charts:
      bgColor: "#0d1117"
      dialBgColor: "#0d1117"
      defaultDialColors:
        - "#58a6ff"
        - "#f85149"
      defaultChartColors:
        - "#58a6ff"
        - "#f85149"
    table:
      fgColor: "#c9d1d9"
      bgColor: "#0d1117"
      header:
        fgColor: "#79c0ff"
        bgColor: "#0d1117"
        sorterColor: "#ff7b72"
    xray:
      fgColor: "#c9d1d9"
      bgColor: "#0d1117"
      cursorColor: "#58a6ff"
      graphicColor: "#58a6ff"
      showIcons: false
    yaml:
      keyColor: "#ff7b72"
      colonColor: "#c9d1d9"
      valueColor: "#79c0ff"
    logs:
      fgColor: "#c9d1d9"
      bgColor: "#0d1117"
      indicator:
        fgColor: "#79c0ff"
        bgColor: "#0d1117"
EOF
        success "k9s GitHub Dark theme created"
    else
        info "k9s skin already exists, skipping"
    fi
}

# =============================================================================
# 5. Create lazydocker configuration
# =============================================================================
configure_lazydocker() {
    info "Creating lazydocker configuration..."

    LAZYDOCKER_CONFIG_DIR=~/.config/lazydocker
    mkdir -p "$LAZYDOCKER_CONFIG_DIR"

    if [[ ! -f "$LAZYDOCKER_CONFIG_DIR/config.yml" ]]; then
        cat > "$LAZYDOCKER_CONFIG_DIR/config.yml" << 'EOF'
# LazyDocker Configuration
gui:
  # Color theme
  theme:
    activeBorderColor:
      - '#58a6ff'
      - bold
    inactiveBorderColor:
      - '#30363d'
    selectedLineBgColor:
      - '#1f6feb'

  # UI Settings
  scrollHeight: 2
  scrollPastBottom: true
  mouseEvents: true
  skipUnchangedStateScreenUpdates: false
  skipDiscardChangeWarning: false

  # Which panels to show
  showAllContainers: false

# How to show container logs
logs:
  timestamps: false
  since: '60m'
  tail: '300'

# How commands are run
commandTemplates:
  dockerCompose: docker-compose
  restartService: '{{ .DockerCompose }} restart {{ .Service.Name }}'
  up: '{{ .DockerCompose }} up -d'
  down: '{{ .DockerCompose }} down'
  downWithVolumes: '{{ .DockerCompose }} down --volumes'
  upService: '{{ .DockerCompose }} up -d {{ .Service.Name }}'
  startService: '{{ .DockerCompose }} start {{ .Service.Name }}'
  stopService: '{{ .DockerCompose }} stop {{ .Service.Name }}'
  serviceLogs: '{{ .DockerCompose }} logs --since=60m --follow {{ .Service.Name }}'
  viewServiceLogs: '{{ .DockerCompose }} logs --follow {{ .Service.Name }}'
  rebuildService: '{{ .DockerCompose }} up -d --build {{ .Service.Name }}'
  recreateService: '{{ .DockerCompose }} up -d --force-recreate {{ .Service.Name }}'

# Custom commands
customCommands:
  containers:
    - name: bash
      attach: true
      command: 'docker exec -it {{ .Container.ID }} /bin/bash'
      serviceNames: []
    - name: sh
      attach: true
      command: 'docker exec -it {{ .Container.ID }} /bin/sh'
      serviceNames: []
  services:
    - name: bash
      attach: true
      command: 'docker-compose exec {{ .Service.Name }} /bin/bash'
      serviceNames: []
    - name: sh
      attach: true
      command: 'docker-compose exec {{ .Service.Name }} /bin/sh'
      serviceNames: []

# Stats
stats:
  graphs:
    - caption: CPU (%)
      statPath: DerivedStats.CPUPercentage
      color: blue
    - caption: Memory (%)
      statPath: DerivedStats.MemoryPercentage
      color: green
EOF
        success "lazydocker config created at $LAZYDOCKER_CONFIG_DIR/config.yml"
    else
        info "lazydocker config already exists, skipping"
    fi
}

# =============================================================================
# Main Installation
# =============================================================================
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   Docker & Kubernetes Tools Installer                 ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""

    # Check prerequisites
    info "Checking prerequisites..."

    if ! command_exists git; then
        error "git is not installed. Please install git first."
        exit 1
    fi

    if ! command_exists curl; then
        error "curl is not installed. Please install curl first."
        exit 1
    fi

    if ! command_exists make; then
        warning "make is not installed. ble.sh installation may fail."
    fi

    success "Prerequisites check passed!"
    echo ""

    # Install components
    PS3="Select what to install (or 0 to exit): "
    options=("All tools" "ble.sh only" "lazydocker only" "k9s only" "Configure k9s" "Configure lazydocker" "Exit")

    select opt in "${options[@]}"; do
        case $opt in
            "All tools")
                install_blesh
                install_lazydocker
                configure_lazydocker
                install_k9s
                configure_k9s
                break
                ;;
            "ble.sh only")
                install_blesh
                break
                ;;
            "lazydocker only")
                install_lazydocker
                configure_lazydocker
                break
                ;;
            "k9s only")
                install_k9s
                configure_k9s
                break
                ;;
            "Configure k9s")
                configure_k9s
                break
                ;;
            "Configure lazydocker")
                configure_lazydocker
                break
                ;;
            "Exit")
                info "Exiting..."
                exit 0
                ;;
            *)
                error "Invalid option"
                ;;
        esac
    done

    echo ""
    success "Installation complete!"
    echo ""
    info "Next steps:"
    echo "  1. Restart your shell or run: source ~/.bashrc"
    echo "  2. Run 'lzd' to start lazydocker (if installed)"
    echo "  3. Run 'k9' to start k9s (if installed)"
    echo "  4. Type a command and see auto-suggestions (if ble.sh installed)"
    echo ""
    info "Make sure ~/.local/bin is in your PATH!"
}

# Run main function
main
