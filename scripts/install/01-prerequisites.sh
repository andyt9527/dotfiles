#!/usr/bin/env bash
# =============================================================================
# Module: 01-prerequisites
# Description: Install prerequisite tools (git, curl, wget, node)
# =============================================================================

install_prerequisites() {
    info "Installing prerequisites..."

    if [ "$OS" = "macos" ]; then
        # Check for Homebrew
        if ! command_exists brew; then
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for this session
            if [ -d "/opt/homebrew/bin" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -d "/usr/local/bin" ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            info "Homebrew is already installed"
        fi

        # macOS packages - check before install
        local prereq_packages=("git" "curl" "wget" "node")
        for pkg in "${prereq_packages[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

    elif [ "$OS" = "linux" ]; then
        local prereq_packages=("git" "curl" "wget" "nodejs" "npm")
        local needs_update=false

        for pkg in "${prereq_packages[@]}"; do
            if apt_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                needs_update=true
                break
            fi
        done

        if [ "$needs_update" = true ]; then
            sudo apt-get update
            for pkg in "${prereq_packages[@]}"; do
                if apt_package_installed "$pkg"; then
                    info "$pkg is already installed, skipping"
                else
                    info "Installing $pkg..."
                    sudo apt-get install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                fi
            done
        fi
    fi

    success "Prerequisites installed"
}
