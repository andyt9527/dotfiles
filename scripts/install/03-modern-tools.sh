#!/usr/bin/env bash
# =============================================================================
# Module: 03-modern-tools
# Description: Install modern CLI tools (fd, bat, eza, zoxide, fzf, ripgrep)
# =============================================================================

INSTALL_MODERN_TOOLS=${INSTALL_MODERN_TOOLS:-true}

install_modern_tools() {
    if [ "$INSTALL_MODERN_TOOLS" = false ]; then
        return
    fi

    info "Installing modern CLI tools..."

    if [ "$OS" = "macos" ]; then
        local core_tools=("fd" "bat" "eza" "zoxide" "fzf" "ripgrep")
        for pkg in "${core_tools[@]}"; do
            if ! needs_install "$pkg"; then
                info "$pkg already installed, skipping"
                continue
            fi
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

        local optional_tools=("duf" "dust" "procs" "bottom")
        for pkg in "${optional_tools[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

    elif [ "$OS" = "linux" ]; then
        # Check and install fd-find
        if needs_install fd || needs_install fdfind; then
            info "Installing fd-find..."
            sudo apt-get install -y fd-find && success "fd-find installed" || warning "Failed to install fd-find"
        else
            info "fd is already installed, skipping"
        fi

        # Check and install bat
        if needs_install bat || needs_install batcat; then
            info "Installing bat..."
            sudo apt-get install -y bat && success "bat installed" || warning "Failed to install bat"
        else
            info "bat is already installed, skipping"
        fi

        # Create symlinks for fd and bat if needed (Ubuntu uses different names)
        # Use ~/.local/bin which is already in PATH on Linux
        if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
        fi

        if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which batcat)" "$HOME/.local/bin/bat" 2>/dev/null || true
        fi

        # Install rust-based tools via cargo if available
        if command -v cargo &> /dev/null; then
            local rust_tools=("eza" "zoxide" "du-dust" "duf" "procs" "bottom")
            for tool in "${rust_tools[@]}"; do
                local cmd_name="$tool"
                [ "$tool" = "du-dust" ] && cmd_name="dust"
                if ! needs_install "$cmd_name"; then
                    info "$tool already installed, skipping"
                    continue
                fi
                if command_exists "$cmd_name"; then
                    info "$tool is already installed, skipping"
                else
                    info "Installing $tool via cargo..."
                    cargo install "$tool" 2>/dev/null && success "$tool installed" || warning "Failed to install $tool"
                fi
            done
        fi

        # Install zoxide via install script if not already installed
        if ! needs_install zoxide; then
            info "zoxide already installed, skipping"
        else
            info "Installing zoxide..."
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            success "zoxide installed"
        fi
    fi

    success "Modern CLI tools installed"
}
