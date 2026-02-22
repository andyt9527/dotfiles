#!/usr/bin/env zsh
# =============================================================================
# Environment Variables Configuration
# Cross-platform Exports for Ubuntu and macOS
# =============================================================================

# =============================================================================
# Editor Settings
# =============================================================================
if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
fi

# =============================================================================
# Locale Settings
# =============================================================================
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# =============================================================================
# Pager Settings
# =============================================================================
export PAGER="less"
export LESS="-R -F -X"

# =============================================================================
# FZF Configuration
# =============================================================================
export FZF_DEFAULT_OPTS="
    --height 60%
    --layout=reverse
    --border=rounded
    --info=inline
    --prompt='∼ '
    --pointer='▶'
    --marker='✓'
    --preview-window='right:50%:wrap'
    --color='fg:#f8f8f2,bg:#282a36,hl:#bd93f9'
    --color='fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9'
    --color='info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6'
    --color='marker:#ff79c6,spinner:#ffb86c,header:#6272a4'
    --bind='ctrl-/:change-preview-window(down|hidden|)'
    --bind='ctrl-o:execute(\${EDITOR:-vim} {})'
    --bind='ctrl-y:execute-silent(echo {} | (command -v pbcopy &>/dev/null && pbcopy || xclip -selection clipboard || cat))+abort'
    --bind='ctrl-u:preview-half-page-up'
    --bind='ctrl-d:preview-half-page-down'
"

# Use fd for FZF if available (faster than find)
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude target --exclude build'
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude target --exclude build'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!node_modules/*" --glob "!target/*" --glob "!build/*"'
    export FZF_ALT_C_COMMAND='rg --files --null | xargs -0 dirname | sort -u'
fi

# =============================================================================
# Bat Theme
# =============================================================================
export BAT_THEME="Dracula"

# Use bat as man pager if available
if command -v bat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif command -v batcat &> /dev/null; then
    export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
fi

# =============================================================================
# Oh My Zsh
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"

# =============================================================================
# Node Version Manager (nvm) - macOS
# =============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    export NVM_DIR="$HOME/.nvm"
fi

# =============================================================================
# Android SDK
# =============================================================================
# macOS
#if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "$HOME/Library/Android/sdk" ]]; then
#    export ANDROID_HOME="$HOME/Library/Android/sdk"
#fi

# Linux
#if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -d "$HOME/Android/Sdk" ]]; then
#    export ANDROID_HOME="$HOME/Android/Sdk"
#fi

# =============================================================================
# Java Home (macOS - auto-detect latest)
# =============================================================================
#if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/Library/Java/JavaVirtualMachines" ]]; then
#    latest_java=$(ls /Library/Java/JavaVirtualMachines 2>/dev/null | sort -V | tail -1)
#    if [[ -n "$latest_java" ]]; then
#        export JAVA_HOME="/Library/Java/JavaVirtualMachines/${latest_java}/Contents/Home"
#    fi
#fi
