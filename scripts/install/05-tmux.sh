#!/usr/bin/env bash
# =============================================================================
# Module: 05-tmux
# Description: Install Tmux and Tmux Plugin Manager (TPM)
# =============================================================================

install_tmux() {
    info "Installing tmux..."

    install_tpm

    success "Tmux installed"
}

install_tpm() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        info "TPM already installed"
        return
    fi

    info "Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    success "TPM installed"
}
