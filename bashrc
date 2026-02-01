# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=50000
HISTFILESIZE=100000
HISTTIMEFORMAT="%F %T "
shopt -s histverify
HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:history"

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
# Efficient PATH setup - consolidated exports
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/go/bin:$HOME/go/bin:$PATH"
# Start prompt at the bottom of terminal (only when not in tmux) - disabled for speed
# if [ -z "$TMUX" ]; then
#     printf '\033[2J\033[999B'
# fi

# ============================================================================
# Bash Auto-Suggestions & Syntax Highlighting (ble.sh)
# ============================================================================
# Install with: git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git ~/.local/share/blesh
# Then run: make -C ~/.local/share/blesh install PREFIX=~/.local
if [[ -f ~/.local/share/blesh/ble.sh ]]; then
    source ~/.local/share/blesh/ble.sh
fi

eval "$(starship init bash)"

#eval "$(starship init bash)"
. "$HOME/.cargo/env"

export PATH="$HOME/bin:$PATH"
export VCPKG_ROOT=~/vcpkg

# ============================================================================
# ENHANCED TERMINAL WORKFLOW
# ============================================================================

# For tmux-resurrect: save history after each command
if [ -n "$TMUX" ]; then
    # Save history immediately after each command
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"

    # Auto-display previous pane content after restore (runs once per pane)
    if [ -f "$HOME/configs/bin/tmux-auto-restore-content" ]; then
        "$HOME/configs/bin/tmux-auto-restore-content" >/dev/null 2>&1
    fi
fi

# Environment Variables
export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS='-R -M --shift 5'

# Man pages with bat (when installed)
export MANPAGER="sh -c 'col -bx | bat -l man -p 2>/dev/null || less'"


# FZF Configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# FZF color scheme (GitHub Dark to match terminal)
export FZF_DEFAULT_OPTS="--color=bg+:#2d2d2d,bg:#0d1117,spinner:#3fb950,hl:#ff7b72 \
--color=fg:#c9d1d9,header:#ff7b72,info:#d29922,pointer:#3fb950 \
--color=marker:#3fb950,fg+:#c9d1d9,prompt:#58a6ff,hl+:#ff7b72 \
--height 40% --layout=reverse --border --preview-window=right:60%"

# Enable FZF keybindings and completion - immediate load
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if [ -f /usr/share/doc/fzf/examples/completion.bash ]; then
    source /usr/share/doc/fzf/examples/completion.bash
fi

# Zoxide (smart cd) - replaces cd with smart directory jumping
eval "$(zoxide init bash --cmd cd)"

# FZF Advanced Functions
# ----------------------

# frg - Search file contents with ripgrep and open in nvim
frg() {
  result=$(rg --ignore-case --color=always --line-number --no-heading "$@" |
    fzf --ansi \
        --color 'hl:-1:underline,hl+:-1:underline:reverse' \
        --delimiter ':' \
        --preview "bat --color=always {1} --highlight-line {2} 2>/dev/null || cat {1}" \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
  file="${result%%:*}"
  line="${result#*:}"
  line="${line%%:*}"
  [[ -n "$file" ]] && nvim "$file" "+${line}"
}

# zi - Interactive directory jumper with zoxide + fzf
zi() {
  local dir
  dir=$(zoxide query -l 2>/dev/null | fzf --preview 'eza --tree --level=2 --color=always {} 2>/dev/null || ls -la {}') &&
  cd "$dir"
}

# fkill - Interactive process killer
fkill() {
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}

# ============================================================================
# ble.sh is auto-attached when sourced with --
# ============================================================================

# Pyenv - Immediate load
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
# Final environment variables
export MY_INSTALL_DIR="$HOME/.local"
export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/tarun/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"



export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
