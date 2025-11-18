# ============================================================================
# Bash Aliases (~/.bash_aliases)
# Modern CLI tool replacements and useful shortcuts
# ============================================================================

# Modern replacements (will use these if tools are installed)
# ------------------------------------------------------------

# eza - modern ls replacement with git integration
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
    alias tree='eza --tree --icons'
fi

# bat - cat with syntax highlighting
if command -v bat &> /dev/null; then
    alias cat='bat --style=auto'
    alias catt='/usr/bin/cat'  # original cat if needed
fi

# btop - modern system monitor
if command -v btop &> /dev/null; then
    alias top='btop'
    alias htop='btop'
fi

# duf - modern df (disk free)
if command -v duf &> /dev/null; then
    alias df='duf'
fi

# dust - modern du (disk usage)
if command -v dust &> /dev/null; then
    alias du='dust'
fi

# Git Shortcuts
# ------------------------------------------------------------
alias lg='lazygit'
alias gst='git status'
alias gd='git diff'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'
alias glast='git log -1 HEAD'
alias gunstage='git reset HEAD --'

# Editor Shortcuts
# ------------------------------------------------------------
alias vim='nvim'
alias vi='nvim'
alias v='nvim'

# Navigation Shortcuts
# ------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Useful Shortcuts
# ------------------------------------------------------------
alias cls='clear'
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'

# Tmux Shortcuts
# ------------------------------------------------------------
alias ta='tmux attach'
alias tl='tmux ls'
alias tn='tmux new -s'
alias tk='tmux kill-session -t'

# Safety Aliases (ask before overwriting)
# ------------------------------------------------------------
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# FZF Enhanced Commands
# ------------------------------------------------------------
# File preview with fzf
alias preview="fzf --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}'"

# Quick directory jump with fzf
alias fcd='cd $(fd --type d | fzf)'

# System Information
# ------------------------------------------------------------
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias cpuinfo='lscpu'

# Misc Utilities
# ------------------------------------------------------------
alias wget='wget -c'  # resume downloads by default
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Quick file operations
# ------------------------------------------------------------
alias mkdir='mkdir -pv'  # create parent directories as needed

# Python shortcuts
# ------------------------------------------------------------
alias py='python3'
alias pip='python3 -m pip'
alias venv='python3 -m venv'

# Development shortcuts
# ------------------------------------------------------------
alias serve='python3 -m http.server'  # Quick HTTP server
alias json='python3 -m json.tool'     # Format JSON

# Cargo/Rust shortcuts
# ------------------------------------------------------------
alias cr='cargo run'
alias cb='cargo build'
alias ct='cargo test'
alias cc='cargo check'

# Docker shortcuts
# ------------------------------------------------------------
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'
alias dlogf='docker logs -f'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'
alias drestart='docker restart'
alias dinspect='docker inspect'
alias dprune='docker system prune -af'
alias dvol='docker volume ls'
alias dnet='docker network ls'

# Docker Compose shortcuts
# ------------------------------------------------------------
alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcud='docker-compose up -d'
alias dcd='docker-compose down'
alias dcl='docker-compose logs'
alias dclf='docker-compose logs -f'
alias dcps='docker-compose ps'
alias dcrestart='docker-compose restart'
alias dcbuild='docker-compose build'
alias dcpull='docker-compose pull'
alias dcstop='docker-compose stop'
alias dcstart='docker-compose start'
alias dcexec='docker-compose exec'

# LazyDocker - TUI for Docker
# ------------------------------------------------------------
if command -v lazydocker &> /dev/null; then
    alias lzd='lazydocker'
fi

# Kubernetes shortcuts
# ------------------------------------------------------------
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe node'
alias kdel='kubectl delete'
alias klog='kubectl logs'
alias klogf='kubectl logs -f'
alias kexec='kubectl exec -it'
alias kapply='kubectl apply -f'
alias kctx='kubectl config current-context'
alias kns='kubectl config view --minify --output "jsonpath={..namespace}"'

# K9s - TUI for Kubernetes
# ------------------------------------------------------------
if command -v k9s &> /dev/null; then
    alias k9='k9s'
fi

# Quick notes (creates notes in ~/notes/)
# ------------------------------------------------------------
note() {
    mkdir -p ~/notes
    nvim ~/notes/"$(date +%Y-%m-%d)".md
}

# Extract any archive
# ------------------------------------------------------------
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick backup of a file
# ------------------------------------------------------------
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Make directory and cd into it
# ------------------------------------------------------------
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Docker helper functions
# ------------------------------------------------------------

# dsh - Shell into a running container
dsh() {
    if [ -z "$1" ]; then
        echo "Usage: dsh <container_name_or_id>"
        return 1
    fi
    docker exec -it "$1" /bin/bash || docker exec -it "$1" /bin/sh
}

# dcsh - Shell into a docker-compose service
dcsh() {
    if [ -z "$1" ]; then
        echo "Usage: dcsh <service_name>"
        return 1
    fi
    docker-compose exec "$1" /bin/bash || docker-compose exec "$1" /bin/sh
}

# dclean - Clean up Docker (containers, images, volumes, networks)
dclean() {
    echo "Cleaning up Docker resources..."
    docker container prune -f
    docker image prune -f
    docker volume prune -f
    docker network prune -f
    echo "Docker cleanup complete!"
}

# dip - Get IP address of a container
dip() {
    if [ -z "$1" ]; then
        echo "Usage: dip <container_name_or_id>"
        return 1
    fi
    docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$1"
}

# Kubernetes helper functions
# ------------------------------------------------------------

# kshell - Shell into a pod
kshell() {
    if [ -z "$1" ]; then
        echo "Usage: kshell <pod_name> [container_name]"
        return 1
    fi
    if [ -z "$2" ]; then
        kubectl exec -it "$1" -- /bin/bash || kubectl exec -it "$1" -- /bin/sh
    else
        kubectl exec -it "$1" -c "$2" -- /bin/bash || kubectl exec -it "$1" -c "$2" -- /bin/sh
    fi
}

# ksetns - Set default namespace
ksetns() {
    if [ -z "$1" ]; then
        echo "Usage: ksetns <namespace>"
        return 1
    fi
    kubectl config set-context --current --namespace="$1"
    echo "Default namespace set to: $1"
}

# kgetns - Get current namespace
kgetns() {
    kubectl config view --minify --output 'jsonpath={..namespace}' | xargs
}

# kwatchpods - Watch pods in current namespace
kwatchpods() {
    watch -n 2 kubectl get pods
}

# kport - Port forward to a pod
kport() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: kport <pod_name> <local_port:pod_port>"
        return 1
    fi
    kubectl port-forward "$1" "$2"
}
