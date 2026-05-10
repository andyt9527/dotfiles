#!/usr/bin/env bash
# scripts/tools/bat.sh
TOOL_NAME="bat"

install_bat() {
    if ! needs_install bat && ! needs_install batcat; then
        info "bat already installed, skipping"
        return 0
    fi
    info "Installing bat..."
    if is_macos; then
        run_cmd brew install bat
    elif is_linux; then
        run_cmd sudo apt-get install -y bat
        if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        fi
    fi
    success "bat installed"
}
