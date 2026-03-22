#!/usr/bin/env bash
# =============================================================================
# Module: 04-shell
# Description: Install Oh My Zsh, Powerlevel10k, and configure shell
# =============================================================================

SKIP_OHMYZSH=${SKIP_OHMYZSH:-false}
SKIP_P10K=${SKIP_P10K:-false}

install_shell() {
    info "Installing shell..."

    install_ohmyzsh
    install_powerlevel10k
    install_fzf
    change_shell

    success "Shell installed"
}

install_ohmyzsh() {
    if [ "$SKIP_OHMYZSH" = true ]; then
        return
    fi

    if [ -d "$HOME/.oh-my-zsh" ]; then
        warning "Oh My Zsh already installed"
        return
    fi

    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install plugins
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    # zsh-history-substring-search
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
        git clone https://github.com/zsh-users/zsh-history-substring-search.git \
            "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    fi

    success "Oh My Zsh installed"
}

install_powerlevel10k() {
    if [ "$SKIP_P10K" = true ]; then
        return
    fi

    local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$P10K_DIR" ]; then
        warning "Powerlevel10k already installed"
        return
    fi

    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    success "Powerlevel10k installed"
}

install_fzf() {
    if [ -d ~/.fzf ]; then
        info "fzf already installed, skipping"
        return
    fi

    info "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --no-key-bindings --no-completion 2>/dev/null || true
    success "fzf installed"
}

change_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)

    if [ "$SHELL" = "$zsh_path" ]; then
        info "Shell is already zsh"
        return
    fi

    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        info "Adding zsh to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells 2>/dev/null || warning "Could not add zsh to /etc/shells (may need sudo)"
    fi

    info "Changing default shell to zsh..."
    chsh -s "$zsh_path" 2>/dev/null || warning "Could not change shell automatically (you may need to run: chsh -s $zsh_path)"
    success "Shell changed to zsh"
}
