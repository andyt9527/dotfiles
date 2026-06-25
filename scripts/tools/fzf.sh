#!/usr/bin/env bash
# scripts/tools/fzf.sh
TOOL_NAME="fzf"

install_fzf() {
    if command -v fzf &>/dev/null || [ -d "$HOME/.fzf" ]; then
        info "fzf already installed, skipping"
        return 0
    fi
    info "Installing fzf..."
    if is_macos; then
        run_cmd brew install fzf
    elif is_linux; then
        if command_exists apt-get; then
            run_cmd sudo apt-get install -y fzf
        else
            # Fallback for non-Debian Linux without packaged fzf
            run_cmd git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
            run_cmd "$HOME/.fzf/install" --no-key-bindings --no-completion 2>/dev/null || true
        fi
    fi
    success "fzf installed"
}
