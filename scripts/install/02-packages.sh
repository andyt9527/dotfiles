#!/usr/bin/env bash
# =============================================================================
# Module: 02-packages
# Description: Install platform-specific packages (tmux, vim, git, etc.)
# =============================================================================

install_packages() {
    info "Installing platform packages..."

    if [ "$OS" = "macos" ]; then
        # macOS specific
        local packages=("tmux" "vim" "git" "tig" "tree")
        local optional_packages=("reattach-to-user-namespace" "the_silver_searcher" "ripgrep" "fzf" "universal-ctags" "jq" "yq" "httpie" "tldr")

        info "Installing core packages..."
        for pkg in "${packages[@]}"; do
            if ! needs_install "$pkg"; then
                info "$pkg already installed, skipping"
                return 0
            elif brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                if brew install "$pkg" 2>/dev/null; then
                    success "$pkg installed"
                else
                    warning "Failed to install $pkg, trying to continue..."
                    # Try running postinstall for tmux if it was the failing package
                    if [ "$pkg" = "tmux" ]; then
                        info "Attempting brew postinstall tmux..."
                        brew postinstall tmux 2>/dev/null || warning "tmux postinstall failed"
                    fi
                fi
            fi
        done

        info "Installing optional packages..."
        for pkg in "${optional_packages[@]}"; do
            if ! needs_install "$pkg"; then
                info "$pkg already installed, skipping"
                return 0
            elif brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" 2>/dev/null && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

    elif [ "$OS" = "linux" ]; then
        local packages=("tmux" "vim" "git" "tig" "tree" "jq" "httpie" "silversearcher-ag" "ripgrep")
        local needs_update=false

        # First check if any package needs installation
        for pkg in "${packages[@]}"; do
            local cmd_name="$pkg"
            [ "$pkg" = "silversearcher-ag" ] && cmd_name="ag"
            if ! command_exists "$cmd_name" && ! apt_package_installed "$pkg"; then
                needs_update=true
                break
            fi
        done

        if [ "$needs_update" = true ]; then
            sudo apt-get update
            for pkg in "${packages[@]}"; do
                local cmd_name="$pkg"
                [ "$pkg" = "silversearcher-ag" ] && cmd_name="ag"
                if ! needs_install "$cmd_name"; then
                    info "$pkg already installed, skipping"
                    return 0
                elif command_exists "$cmd_name" || apt_package_installed "$pkg"; then
                    info "$pkg is already installed, skipping"
                else
                    info "Installing $pkg..."
                    sudo apt-get install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                fi
            done
        else
            info "All platform packages are already installed"
        fi

        # Universal ctags (required by space-vim)
        if ! needs_install ctags; then
            # ctags command exists, verify it's Universal
            if ctags --version 2>/dev/null | grep -q "Universal"; then
                info "Universal Ctags is already installed, skipping"
            else
                info "Installing Universal Ctags from source..."
                local build_deps=("build-essential" "autoconf" "automake" "pkg-config")
                for dep in "${build_deps[@]}"; do
                    if ! apt_package_installed "$dep"; then
                        sudo apt-get install -y "$dep"
                    fi
                done

                local original_dir="$(pwd)"
                rm -rf /tmp/ctags
                git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
                cd /tmp/ctags
                ./autogen.sh
                ./configure --prefix=/usr/local
                make
                sudo make install
                cd "$original_dir"
                rm -rf /tmp/ctags

                if command -v /usr/local/bin/ctags &> /dev/null && /usr/local/bin/ctags --version | grep -q "Universal"; then
                    success "Universal Ctags installed successfully"
                else
                    warning "Universal Ctags installation may have failed"
                fi
            fi
        else
            info "Installing Universal Ctags from source..."
            local build_deps=("build-essential" "autoconf" "automake" "pkg-config")
            for dep in "${build_deps[@]}"; do
                if ! apt_package_installed "$dep"; then
                    sudo apt-get install -y "$dep"
                fi
            done

            local original_dir="$(pwd)"
            rm -rf /tmp/ctags
            git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
            cd /tmp/ctags
            ./autogen.sh
            ./configure --prefix=/usr/local
            make
            sudo make install
            cd "$original_dir"
            rm -rf /tmp/ctags

            if command -v /usr/local/bin/ctags &> /dev/null && /usr/local/bin/ctags --version | grep -q "Universal"; then
                success "Universal Ctags installed successfully"
            else
                warning "Universal Ctags installation may have failed"
            fi
        fi

        # Build tools
        if ! needs_install cc; then
            info "build-essential is already installed, skipping"
            return 0
        elif apt_package_installed "build-essential"; then
            info "build-essential is already installed, skipping"
        else
            sudo apt-get install -y build-essential && success "build-essential installed" || warning "Failed to install build-essential"
        fi

        # Install tldr
        if ! needs_install tldr; then
            info "tldr is already installed, skipping"
            return 0
        elif command_exists tldr; then
            info "tldr is already installed, skipping"
        else
            info "Installing tldr..."
            sudo apt-get install -y tldr || npm install -g tldr 2>/dev/null || true
        fi
    fi

    success "Platform packages installed"
}
