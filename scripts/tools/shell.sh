#!/usr/bin/env bash
# scripts/tools/shell.sh
TOOL_NAME="shell"

install_shell() {
    info "Installing shell environment..."
    install_ohmyzsh
    install_powerlevel10k
    change_shell
    success "Shell environment installed"
}

install_ohmyzsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Oh My Zsh already installed"
        return 0
    fi
    info "Installing Oh My Zsh..."
    run_cmd bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
        run_cmd git clone https://github.com/zsh-users/zsh-history-substring-search.git "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    fi
    success "Oh My Zsh installed"
}

install_powerlevel10k() {
    local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ -d "$P10K_DIR" ]; then
        info "Powerlevel10k already installed"
        return 0
    fi
    info "Installing Powerlevel10k..."
    run_cmd git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    success "Powerlevel10k installed"
}

change_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)
    if [ "$SHELL" = "$zsh_path" ]; then
        info "Shell is already zsh"
        return 0
    fi
    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        info "Adding zsh to /etc/shells"
        echo "$zsh_path" | run_cmd sudo tee -a /etc/shells 2>/dev/null || warning "Could not add zsh to /etc/shells"
    fi
    info "Changing default shell to zsh..."
    run_cmd chsh -s "$zsh_path" 2>/dev/null || warning "Could not change shell automatically (run: chsh -s $zsh_path)"
    success "Shell changed to zsh"
}
