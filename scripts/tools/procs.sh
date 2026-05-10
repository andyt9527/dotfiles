#!/usr/bin/env bash
# scripts/tools/procs.sh
TOOL_NAME="procs"

install_procs() {
    if ! needs_install procs; then
        info "procs already installed, skipping"
        return 0
    fi
    info "Installing procs..."
    if is_macos; then
        run_cmd brew install procs
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install procs
        else
            warning "cargo not found — skipping procs"
            return 0
        fi
    fi
    success "procs installed"
}
