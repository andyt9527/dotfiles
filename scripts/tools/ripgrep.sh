#!/usr/bin/env bash
# scripts/tools/ripgrep.sh
TOOL_NAME="ripgrep"

install_ripgrep() {
    if ! needs_install rg; then
        info "ripgrep already installed, skipping"
        return 0
    fi
    info "Installing ripgrep..."
    if is_macos; then
        run_cmd brew install ripgrep
    elif is_linux; then
        run_cmd sudo apt-get install -y ripgrep
    fi
    success "ripgrep installed"
}
