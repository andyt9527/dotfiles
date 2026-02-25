#!/usr/bin/env zsh
# =============================================================================
# Aliases Configuration
# Cross-platform Zsh Aliases for Ubuntu and macOS
# =============================================================================

# =============================================================================
# Tmux Aliases
# =============================================================================
alias tmux="tmux -2"
alias t="tmux"
alias ta="tmux attach"
alias tl="tmux ls"

# =============================================================================
# Navigation Aliases
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# =============================================================================
# Listing Aliases (Modern Tools Priority)
# =============================================================================

# eza - modern ls replacement
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias l='eza -lbF --git --icons'
    alias ll='eza -lbGF --git --icons'
    alias llm='eza -lbGd --git --sort=modified'
    alias la='eza -lbhHigmuSa --time-style=long-iso --git --color-scale --icons'
    alias lx='eza -lbhHigmuSa@ --time-style=long-iso --git --color-scale --icons'
    alias lt='eza --tree --level=2 --icons'
    alias llt='eza -lah --tree --level=2 --icons'

# lsd - another modern ls replacement
elif command -v lsd &> /dev/null; then
    alias ls='lsd --group-dirs first'
    alias l='lsd -l'
    alias ll='lsd -lA'
    alias la='lsd -A'
    alias lt='lsd --tree --depth 2'
    alias lla='lsd -lA --tree --depth 2'

# Fallback to standard ls
else
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        alias ls='ls --color=auto --group-directories-first'
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        alias ls='ls -G'
    fi
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# =============================================================================
# File Viewing Aliases
# =============================================================================

# bat - cat with syntax highlighting
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never --style=plain'
    alias batp='bat --paging=never'
    alias less='bat --paging=always'
elif command -v batcat &> /dev/null; then
    # bat is named batcat on some Ubuntu/Debian systems
    alias cat='batcat --paging=never --style=plain'
    alias bat='batcat'
fi

# =============================================================================
# File System Aliases
# =============================================================================

# Find replacement (fd)
if command -v fd &> /dev/null; then
    alias find='fd'
fi

# Grep with ripgrep
if command -v rg &> /dev/null; then
    alias grep='rg --color=auto'
    alias rgf='rg --files-with-matches'
fi

# du replacement (dust)
if command -v dust &> /dev/null; then
    alias du='dust'
fi

# df replacement (duf)
if command -v duf &> /dev/null; then
    alias df='duf'
fi

# ps replacement (procs)
if command -v procs &> /dev/null; then
    alias ps='procs'
fi

# top replacement (btm or btop)
if command -v btm &> /dev/null; then
    alias top='btm'
    alias htop='btm'
elif command -v btop &> /dev/null; then
    alias top='btop'
    alias htop='btop'
fi

# =============================================================================
# Safety Aliases
# =============================================================================
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# =============================================================================
# Directory Size Aliases
# =============================================================================
alias dus='du -sh'
alias dud='du -d 1 -h'

# =============================================================================
# Git Aliases
# =============================================================================
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch -vv'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gst='git status'
alias gstp='git stash pop'
alias gsw='git switch'
alias gswc='git switch -c'

# =============================================================================
# Lazy Tools Aliases
# =============================================================================
alias lg='lazygit'
alias lzd='lazydocker'

# =============================================================================
# Config Editing Aliases
# =============================================================================
alias zshrc="${EDITOR:-vim} ~/.zshrc"
alias bashrc="${EDITOR:-vim} ~/.bashrc"
alias vimrc="${EDITOR:-vim} ~/.vimrc"
alias tmuxconf="${EDITOR:-vim} ~/.tmux.conf"
alias p10kcfg="${EDITOR:-vim} ~/.p10k.zsh"

# =============================================================================
# macOS Specific Aliases
# =============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Finder
    alias show_hidden="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hide_hidden="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    alias ql='qlmanage -p 2>/dev/null'
    alias finder='open -a Finder .'
    
    # DNS
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
    
    # Homebrew
    alias update_all='brew update && brew upgrade && brew cleanup && brew doctor'
    alias cleanup='brew cleanup && brew doctor'
    alias brews='brew list'
    alias casks='brew list --cask'
    
    # Clipboard
    alias pbc='pbcopy'
    alias pbp='pbpaste'
    
    # Applications
    alias chrome='open -a "Google Chrome"'
    alias safari='open -a Safari'
    alias firefox='open -a Firefox'
fi

# =============================================================================
# Linux Specific Aliases
# =============================================================================
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Package management (Ubuntu/Debian)
    if command -v apt-get &> /dev/null; then
        alias apt-update='sudo apt-get update'
        alias apt-upgrade='sudo apt-get upgrade -y'
        alias apt-clean='sudo apt-get autoremove -y && sudo apt-get clean'
        alias apt-install='sudo apt-get install'
        alias apt-search='apt-cache search'
        alias apt-show='apt-cache show'
        alias update_all='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean'
    fi
    
    # systemd shortcuts
    if command -v systemctl &> /dev/null; then
        alias sysstatus='systemctl status'
        alias sysstart='sudo systemctl start'
        alias sysstop='sudo systemctl stop'
        alias sysrestart='sudo systemctl restart'
        alias sysenable='sudo systemctl enable'
        alias sysdisable='sudo systemctl disable'
        alias syslogs='journalctl -u'
    fi
    
    # Clipboard
    if command -v xclip &> /dev/null; then
        alias pbc='xclip -selection clipboard'
        alias pbp='xclip -selection clipboard -o'
    elif command -v xsel &> /dev/null; then
        alias pbc='xsel --clipboard --input'
        alias pbp='xsel --clipboard --output'
    fi
fi
