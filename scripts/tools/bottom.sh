#!/usr/bin/env bash
# scripts/tools/bottom.sh
TOOL_NAME="bottom"

install_bottom() {
    if ! needs_install btm; then
        info "bottom already installed, skipping"
        return 0
    fi
    info "Installing bottom..."
    if is_macos; then
        run_cmd brew install bottom
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install bottom
        else
            warning "cargo not found — skipping bottom"
            return 0
        fi
    fi
    success "bottom installed"
}
