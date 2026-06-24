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
        local arch tag version file
        arch=$(get_arch)
        tag=$(get_latest_release_tag "jesseduffield/lazygit") || return 1
        version="${tag#v}"
        file="lazygit_${version}_Linux_${arch}.tar.gz"
        if download_github_release "jesseduffield/lazygit" "$file" "/tmp/lazygit.tar.gz"; then
            run_cmd tar xf /tmp/lazygit.tar.gz lazygit
            run_cmd sudo mkdir -p /usr/local/bin
            run_cmd sudo install lazygit /usr/local/bin
            rm -f lazygit /tmp/lazygit.tar.gz
        fi
    fi
    success "lazygit installed"
}
