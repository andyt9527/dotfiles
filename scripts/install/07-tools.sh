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

install_tools() {
    info "Installing tools..."

    install_lazygit
    install_lazydocker
    install_claude_code
    install_codex
    install_cc_switch

    success "Tools installed"
}

install_lazygit() {
    if [ "$INSTALL_LAZYGIT" = false ]; then
        return
    fi

    if command -v lazygit &> /dev/null; then
        info "Lazygit already installed"
        return
    fi

    info "Installing Lazygit..."

    if [ "$OS" = "macos" ]; then
        brew install lazygit
    elif [ "$OS" = "linux" ]; then
        # Detect architecture for Linux
        local ARCH
        case "$(uname -m)" in
            x86_64|amd64) ARCH="x86_64" ;;
            aarch64|arm64) ARCH="arm64" ;;
            *) ARCH="x86_64" ;;
        esac

        local LAZYGIT_VERSION
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -o 'v[0-9.]*' | head -1 | sed 's/v//')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
    fi

    success "Lazygit installed"
}

install_lazydocker() {
    if [ "$INSTALL_LAZYDOCKER" = false ]; then
        return
    fi

    if command -v lazydocker &> /dev/null; then
        info "Lazydocker already installed"
        return
    fi

    info "Installing Lazydocker..."

    if [ "$OS" = "macos" ]; then
        brew install lazydocker
    elif [ "$OS" = "linux" ]; then
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
    fi

    success "Lazydocker installed"
}

install_claude_code() {
    if [ "$INSTALL_CLAUDE_CODE" = false ]; then
        return
    fi

    if command -v claude &> /dev/null; then
        info "Claude Code already installed"
        return
    fi

    info "Installing Claude Code..."

    if ! command -v npm &> /dev/null; then
        error "npm is required to install Claude Code"
        return
    fi

    npm install -g @anthropic-ai/claude-code

    if command -v claude &> /dev/null; then
        success "Claude Code installed"
    else
        warning "Claude Code installation may have failed"
    fi
}

install_codex() {
    if [ "$INSTALL_CODEX" = false ]; then
        return
    fi

    if command -v codex &> /dev/null; then
        info "Codex already installed"
        return
    fi

    info "Installing Codex CLI..."

    if ! command -v npm &> /dev/null; then
        error "npm is required to install Codex"
        return
    fi

    npm install -g @openai/codex

    if command -v codex &> /dev/null; then
        success "Codex installed"
    else
        warning "Codex installation may have failed"
    fi
}

install_cc_switch() {
    if [ "$INSTALL_CC_SWITCH" = false ]; then
        return
    fi

    if command -v cc-switch &> /dev/null; then
        # Version check: skip if installed version matches latest
        local latest_tag
        latest_tag=$(get_cc_switch_latest_tag)
        local installed_version
        installed_version=$(cc-switch --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//')

        if [ -n "$latest_tag" ] && [ -n "$installed_version" ]; then
            local latest_ver
            latest_ver=$(echo "$latest_tag" | sed 's/^v//')
            if [ "$installed_version" = "$latest_ver" ]; then
                info "cc-switch already installed (v${installed_version})"
                return
            else
                info "cc-switch v${installed_version} installed, latest is v${latest_ver} — updating..."
            fi
        else
            info "cc-switch already installed"
            return
        fi
    fi

    info "Installing cc-switch..."

    if [ "$OS" = "macos" ]; then
        brew tap farion1231/ccswitch
        brew install --cask farion1231/ccswitch/cc-switch
    elif [ "$OS" = "linux" ]; then
        install_cc_switch_linux "$latest_tag"
    else
        info "cc-switch is not supported on this OS"
        return
    fi

    if command -v cc-switch &> /dev/null; then
        success "cc-switch installed"
    else
        warning "cc-switch installation may have failed"
    fi
}

get_cc_switch_latest_tag() {
    curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest | jq -r .tag_name
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
    curl -fL -o "$FILE" "$URL"

    if ! command -v apt-get >/dev/null; then
        error "apt-get required"
        return 1
    fi

    sudo apt-get install -y "./$FILE"
    success "cc-switch installed successfully"
}
