#!/usr/bin/env bash
# scripts/tools/eza.sh
TOOL_NAME="eza"

install_eza() {
    if ! needs_install eza; then
        info "eza already installed, skipping"
        return 0
    fi
    info "Installing eza..."
    if is_macos; then
        run_cmd brew install eza
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install eza
        else
            warning "cargo not found — skipping eza (install rustup first)"
            return 0
        fi
    fi
    success "eza installed"
}
