#!/usr/bin/env bash
# scripts/tools/tmux.sh
TOOL_NAME="tmux"

install_tmux() {
    info "Installing tmux..."
    if ! needs_install tmux; then
        info "tmux already installed, skipping"
    else
        if is_macos; then
            if ! run_cmd brew install tmux; then
                info "Attempting brew postinstall tmux..."
                run_cmd brew postinstall tmux 2>/dev/null || warning "tmux postinstall failed"
            fi
        elif is_linux; then
            run_cmd sudo apt-get install -y tmux
        fi
    fi
    install_tpm
    success "tmux installed"
}

install_tpm() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        info "TPM already installed"
        return 0
    fi
    info "Installing Tmux Plugin Manager (TPM)..."
    run_cmd git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    success "TPM installed"
}
