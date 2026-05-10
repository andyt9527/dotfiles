#!/usr/bin/env bash
# scripts/tools/fd.sh
TOOL_NAME="fd"

install_fd() {
    if ! needs_install fd && ! needs_install fdfind; then
        info "fd already installed, skipping"
        return 0
    fi
    info "Installing fd..."
    if is_macos; then
        run_cmd brew install fd
    elif is_linux; then
        run_cmd sudo apt-get install -y fd-find
        if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
        fi
    fi
    success "fd installed"
}
