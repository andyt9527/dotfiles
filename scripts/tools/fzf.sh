#!/usr/bin/env bash
# scripts/tools/fzf.sh
TOOL_NAME="fzf"

install_fzf() {
    if [ -d "$HOME/.fzf" ]; then
        info "fzf already installed, skipping"
        return 0
    fi
    info "Installing fzf..."
    if is_macos; then
        run_cmd brew install fzf
    fi
    if [ ! -d "$HOME/.fzf" ]; then
        run_cmd git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        run_cmd "$HOME/.fzf/install" --no-key-bindings --no-completion 2>/dev/null || true
    fi
    success "fzf installed"
}
