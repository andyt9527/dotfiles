#!/usr/bin/env bash
# scripts/tools/lazygit.sh
TOOL_NAME="lazygit"

install_lazygit() {
    if ! needs_install lazygit; then
        info "lazygit already installed, skipping"
        return 0
    fi
    info "Installing lazygit..."
    if is_macos; then
        run_cmd brew install lazygit
    elif is_linux; then
        local arch
        arch=$(get_arch)
        local tag
        tag=$(download_github_release "jesseduffield/lazygit" \
            "lazygit_${arch}.tar.gz" "/tmp/lazygit.tar.gz")
        if [ $? -eq 0 ] && [ -n "$tag" ]; then
            run_cmd tar xf /tmp/lazygit.tar.gz lazygit
            run_cmd sudo install lazygit /usr/local/bin
            rm -f lazygit /tmp/lazygit.tar.gz
        fi
    fi
    success "lazygit installed"
}
