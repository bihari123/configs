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

# Docker shortcuts (if you use Docker)
# ------------------------------------------------------------
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dimg='docker images'
alias dex='docker exec -it'

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
