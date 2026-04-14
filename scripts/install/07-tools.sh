#!/usr/bin/env bash
# =============================================================================
# Module: 07-tools
# Description: Install additional tools (lazygit, lazydocker, claude, codex)
# =============================================================================

INSTALL_LAZYGIT=${INSTALL_LAZYGIT:-true}
INSTALL_LAZYDOCKER=${INSTALL_LAZYDOCKER:-true}
INSTALL_CLAUDE_CODE=${INSTALL_CLAUDE_CODE:-true}
INSTALL_CODEX=${INSTALL_CODEX:-true}
INSTALL_CC_SWITCH=${INSTALL_CC_SWITCH:-true}

# Dependencies for tools module
TOOLS_DEPS=(npm)

check_tools_dependencies() {
    for dep in "${TOOLS_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            error "Missing $dep — required for Claude Code / Codex installation"
            info "Install node via: brew install node (macOS) or sudo apt install nodejs (Linux)"
            return 1
        fi
    done
}

install_tools() {
    info "Installing tools..."

    check_tools_dependencies || return 1

    # Parallel installs for independent tools (no shared deps)
    install_lazygit &
    local lazygit_pid=$!

    install_lazydocker &
    local lazydocker_pid=$!

    install_cc_switch &
    local ccswitch_pid=$!

    # Wait for parallel installs
    local failed=0
    wait $lazygit_pid || ((failed++))
    wait $lazydocker_pid || ((failed++))
    wait $ccswitch_pid || ((failed++))

    # Sequential for npm-based tools (share npm)
    install_claude_code
    install_codex

    if [ $failed -gt 0 ]; then
        warning "$failed tool(s) failed to install — check errors above"
    fi

    success "Tools installed"
}

install_lazygit() {
    if ! needs_install lazygit; then
        info "Lazygit already installed, skipping"
        return 0
    fi

    info "Installing Lazygit..."

    if [ "$OS" = "macos" ]; then
        if ! brew install lazygit 2>&1; then
            error "Failed to install lazygit via Homebrew"
            info "Try manually: brew install lazygit"
            return 1
        fi
    elif [ "$OS" = "linux" ]; then
        local ARCH
        case "$(uname -m)" in
            x86_64|amd64) ARCH="x86_64" ;;
            aarch64|arm64) ARCH="arm64" ;;
            *) ARCH="x86_64" ;;
        esac

        local LAZYGIT_VERSION
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -o 'v[0-9.]*' | head -1 | sed 's/v//')

        if [ -z "$LAZYGIT_VERSION" ]; then
            error "Failed to fetch lazygit version from GitHub API"
            return 1
        fi

        if ! curl -fL -o lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" 2>&1; then
            error "Failed to download lazygit v${LAZYGIT_VERSION}"
            info "Check network connectivity and GitHub reachability"
            return 1
        fi

        if ! tar xf lazygit.tar.gz lazygit; then
            error "Failed to extract lazygit archive"
            rm -f lazygit.tar.gz
            return 1
        fi
        if ! sudo install lazygit /usr/local/bin 2>&1; then
            error "Failed to install lazygit to /usr/local/bin"
            info "Check permissions — you may need sudo"
            rm -f lazygit lazygit.tar.gz
            return 1
        fi
        rm -f lazygit lazygit.tar.gz
    fi

    success "Lazygit installed"
}

install_lazydocker() {
    if ! needs_install lazydocker; then
        info "Lazydocker already installed, skipping"
        return 0
    fi

    info "Installing Lazydocker..."

    if [ "$OS" = "macos" ]; then
        if ! brew install lazydocker 2>&1; then
            error "Failed to install lazydocker via Homebrew"
            info "Try manually: brew install lazydocker"
            return 1
        fi
    elif [ "$OS" = "linux" ]; then
        if ! curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh 2>&1 | bash; then
            error "Failed to install lazydocker via official script"
            info "Check network connectivity and https://raw.githubusercontent.com reachability"
            return 1
        fi
    fi

    success "Lazydocker installed"
}

install_claude_code() {
    if ! needs_install claude; then
        info "Claude Code already installed, skipping"
        return 0
    fi

    info "Installing Claude Code..."

    if ! command -v npm >/dev/null 2>&1; then
        error "npm is required to install Claude Code"
        info "Install node via: brew install node (macOS) or sudo apt install nodejs (Linux)"
        return 1
    fi

    if ! npm install -g @anthropic-ai/claude-code 2>&1; then
        error "Failed to install Claude Code via npm"
        info "Check npm connectivity and permissions"
        return 1
    fi

    success "Claude Code installed"
}

install_codex() {
    if ! needs_install codex; then
        info "Codex already installed, skipping"
        return 0
    fi

    info "Installing Codex CLI..."

    if ! command -v npm >/dev/null 2>&1; then
        error "npm is required to install Codex"
        info "Install node via: brew install node (macOS) or sudo apt install nodejs (Linux)"
        return 1
    fi

    if ! npm install -g @openai/codex 2>&1; then
        error "Failed to install Codex via npm"
        info "Check npm connectivity and permissions"
        return 1
    fi

    success "Codex installed"
}

install_cc_switch() {
    if [ "$INSTALL_CC_SWITCH" = false ]; then
        return 0
    fi

    # Always fetch latest tag first (needed for Linux install, and for version comparison)
    local latest_tag
    latest_tag=$(get_cc_switch_latest_tag)

    # Check if cc-switch is available via command (DMG or other install)
    if command -v cc-switch &> /dev/null; then
        # Version check: skip if installed version matches latest
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

    # Check if cc-switch app exists (DMG install to /Applications)
    if [ -d "/Applications/CC Switch.app" ]; then
        info "cc-switch already installed (/Applications/CC Switch.app)"
        return 0
    fi

    info "Installing cc-switch..."

    if [ "$OS" = "macos" ]; then
        local brew_output
        brew_output=$(brew install --cask farion1231/ccswitch/cc-switch 2>&1)
        local brew_status=$?

        # Graceful handling: "already an App at" means already installed
        if echo "$brew_output" | grep -q "already an App at"; then
            info "cc-switch already installed (macOS)"
            return 0
        fi

        if [ $brew_status -ne 0 ]; then
            error "Failed to install cc-switch via Homebrew"
            info "Try manually: brew install --cask farion1231/ccswitch/cc-switch"
            return 1
        fi
    elif [ "$OS" = "linux" ]; then
        install_cc_switch_linux "$latest_tag"
    else
        info "cc-switch is not supported on this OS"
        return 1
    fi

    if command -v cc-switch &> /dev/null; then
        success "cc-switch installed"
    else
        warning "cc-switch installation may have failed"
    fi
}

get_cc_switch_latest_tag() {
    local tag
    tag=$(curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest 2>/dev/null | jq -r '.tag_name' 2>/dev/null)

    if [ -z "$tag" ] || [ "$tag" = "null" ]; then
        return 1
    fi
    echo "$tag"
}

install_cc_switch_linux() {
    local tag="${1:-}"
    if [ -z "$tag" ]; then
        tag=$(get_cc_switch_latest_tag)
    fi

    if [ -z "$tag" ] || [ "$tag" = "null" ]; then
        error "Failed to get latest version"
        return 1
    fi

    info "Downloading latest cc-switch release (v${tag})..."

    local ARCH
    case "$(uname -m)" in
        x86_64|amd64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *)
            error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac

    local FILE="CC-Switch-${tag}-Linux-${ARCH}.deb"
    local URL="https://github.com/farion1231/cc-switch/releases/download/${tag}/${FILE}"

    info "Downloading $FILE"
    if ! curl -fL -o "$FILE" "$URL" 2>&1; then
        error "Failed to download cc-switch v${tag} for ${ARCH}"
        info "Check network connectivity and GitHub reachability"
        return 1
    fi

    if ! command -v apt-get >/dev/null; then
        error "apt-get required for Linux installation"
        rm -f "$FILE"
        return 1
    fi

    if ! sudo apt-get install -y "./$FILE" 2>&1; then
        error "Failed to install cc-switch via apt-get"
        info "Check apt-get permissions and package validity"
        rm -f "$FILE"
        return 1
    fi

    rm -f "$FILE"
    success "cc-switch installed successfully"
}
