#!/usr/bin/env bash
# =============================================================================
# Module: 08-configs
# Description: Link configuration files to home directory
# =============================================================================

SKIP_P10K=${SKIP_P10K:-false}

install_configs() {
    info "Linking configuration files..."

    # Create necessary directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/zsh"
    mkdir -p "$HOME/.vim/undo"
    mkdir -p "$HOME/.vim/swap"
    mkdir -p "$HOME/.tmux/logs"

    # Shell configs
    backup_file "$HOME/.bashrc"
    lnif "$DOTFILES_DIR/shell/bashrc" "$HOME/.bashrc"

    backup_file "$HOME/.zshrc"
    lnif "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"

    # Local zsh config (conda, proxy, etc.)
    if [ ! -e "$HOME/.zshrc.local" ]; then
        lnif "$DOTFILES_DIR/shell/zshrc.local" "$HOME/.zshrc.local"
        info "Created ~/.zshrc.local (conda template)"
    else
        info "Skipping ~/.zshrc.local (already exists)"
    fi

    success "Shell configuration files linked"

    # Tmux config
    backup_file "$HOME/.tmux.conf"
    lnif "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

    # Git config
    backup_file "$HOME/.gitconfig"
    lnif "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

    # Tig config
    backup_file "$HOME/.tigrc"
    lnif "$DOTFILES_DIR/tig/tigrc" "$HOME/.tigrc"

    backup_file "$HOME/.tigrc.theme"
    lnif "$DOTFILES_DIR/tig/tigrc.theme" "$HOME/.tigrc.theme"

    # Powerlevel10k config
    if [ -f "$DOTFILES_DIR/config/p10k.zsh" ] && [ "$SKIP_P10K" = false ]; then
        backup_file "$HOME/.p10k.zsh"
        lnif "$DOTFILES_DIR/config/p10k.zsh" "$HOME/.p10k.zsh"
    fi

    # Lazygit config
    if [ -f "$DOTFILES_DIR/config/lazygit.yml" ]; then
        if [ "$OS" = "macos" ]; then
            mkdir -p "$HOME/Library/Application Support/lazygit"
            lnif "$DOTFILES_DIR/config/lazygit.yml" "$HOME/Library/Application Support/lazygit/config.yml"
        else
            mkdir -p "$HOME/.config/lazygit"
            lnif "$DOTFILES_DIR/config/lazygit.yml" "$HOME/.config/lazygit/config.yml"
        fi
    fi

    # Lazydocker config
    if [ -f "$DOTFILES_DIR/config/lazydocker.yml" ]; then
        if [ "$OS" = "macos" ]; then
            mkdir -p "$HOME/Library/Application Support/lazydocker"
            lnif "$DOTFILES_DIR/config/lazydocker.yml" "$HOME/Library/Application Support/lazydocker/config.yml"
        else
            mkdir -p "$HOME/.config/lazydocker"
            lnif "$DOTFILES_DIR/config/lazydocker.yml" "$HOME/.config/lazydocker/config.yml"
        fi
    fi

    success "Configuration files linked"
}
