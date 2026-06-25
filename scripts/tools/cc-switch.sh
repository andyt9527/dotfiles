#!/usr/bin/env bash
# scripts/tools/cc-switch.sh
TOOL_NAME="cc-switch"

install_cc_switch() {
    local latest_tag
    latest_tag=$(get_latest_release_tag "farion1231/cc-switch" 2>/dev/null || echo "")

    if command -v cc-switch &>/dev/null; then
        local installed_version
        installed_version=$(cc-switch --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//')
        if [ -n "$latest_tag" ] && [ -n "$installed_version" ]; then
            local latest_ver
            latest_ver=$(echo "$latest_tag" | sed 's/^v//')
            if [ "$installed_version" = "$latest_ver" ]; then
                info "cc-switch already installed (v${installed_version})"
                return 0
            else
                info "cc-switch v${installed_version} installed, latest is v${latest_ver} — updating..."
            fi
        else
            info "cc-switch already installed"
            return 0
        fi
    fi

    if [ -d "/Applications/CC Switch.app" ]; then
        info "cc-switch already installed (/Applications/CC Switch.app)"
        return 0
    fi

    info "Installing cc-switch..."

    if is_macos; then
        local brew_output
        brew_output=$(run_cmd brew install --cask farion1231/ccswitch/cc-switch 2>&1)
        local brew_status=$?
        if echo "$brew_output" | grep -q "already an App at"; then
            info "cc-switch already installed (macOS)"
            return 0
        fi
        if [ $brew_status -ne 0 ]; then
            error "Failed to install cc-switch via Homebrew"
            return 1
        fi
    elif is_linux; then
        if [ -z "$latest_tag" ]; then
            error "Failed to get latest cc-switch version"
            return 1
        fi
        local arch
        arch=$(get_arch)
        # cc-switch release assets use 'arm64' (Go convention), not 'aarch64'
        [[ "$arch" == "aarch64" ]] && arch="arm64"
        local file="CC-Switch-${latest_tag}-Linux-${arch}.deb"
        local url="https://github.com/farion1231/cc-switch/releases/download/${latest_tag}/${file}"
        info "Downloading $file"
        if ! run_cmd curl -fL -o "$file" "$url"; then
            error "Failed to download cc-switch ${latest_tag} for ${arch}"
            return 1
        fi
        run_cmd sudo apt-get install -y "./$file"
        rm -f "$file"
    fi

    if command -v cc-switch &>/dev/null; then
        success "cc-switch installed"
    else
        warning "cc-switch installation may have failed"
    fi
}
