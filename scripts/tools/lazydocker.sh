#!/usr/bin/env bash
# scripts/tools/lazydocker.sh
TOOL_NAME="lazydocker"

install_lazydocker() {
    if ! needs_install lazydocker; then
        info "lazydocker already installed, skipping"
        return 0
    fi
    info "Installing lazydocker..."
    if is_macos; then
        run_cmd brew install lazydocker
    elif is_linux; then
        run_cmd bash -c "$(curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh)"
    fi
    success "lazydocker installed"
}
