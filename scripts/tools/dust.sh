#!/usr/bin/env bash
# scripts/tools/dust.sh
TOOL_NAME="dust"

install_dust() {
    if ! needs_install dust; then
        info "dust already installed, skipping"
        return 0
    fi
    info "Installing dust..."
    if is_macos; then
        run_cmd brew install dust
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install du-dust
        else
            warning "cargo not found — skipping dust"
            return 0
        fi
    fi
    success "dust installed"
}
