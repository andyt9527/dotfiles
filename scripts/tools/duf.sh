#!/usr/bin/env bash
# scripts/tools/duf.sh
TOOL_NAME="duf"

install_duf() {
    if ! needs_install duf; then
        info "duf already installed, skipping"
        return 0
    fi
    info "Installing duf..."
    if is_macos; then
        run_cmd brew install duf
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install duf
        else
            warning "cargo not found — skipping duf"
            return 0
        fi
    fi
    success "duf installed"
}
