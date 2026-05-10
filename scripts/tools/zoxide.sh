#!/usr/bin/env bash
# scripts/tools/zoxide.sh
TOOL_NAME="zoxide"

install_zoxide() {
    if ! needs_install zoxide; then
        info "zoxide already installed, skipping"
        return 0
    fi
    info "Installing zoxide..."
    if is_macos; then
        run_cmd brew install zoxide
    elif is_linux; then
        run_cmd bash -c "$(curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)"
    fi
    success "zoxide installed"
}
