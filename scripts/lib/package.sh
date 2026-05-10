#!/usr/bin/env bash
# scripts/lib/package.sh
# Cross-platform package management

brew_package_installed() {
    local pkg="$1"
    if ! command_exists brew; then
        return 1
    fi
    brew list "$pkg" &>/dev/null
}

apt_package_installed() {
    local pkg="$1"
    if ! command_exists dpkg; then
        return 1
    fi
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
}

package_installed() {
    local pkg="$1"
    local cmd_name="${2:-$pkg}"
    if command_exists "$cmd_name"; then
        return 0
    fi
    if is_macos; then
        brew_package_installed "$pkg"
    elif is_linux; then
        apt_package_installed "$pkg"
    else
        return 1
    fi
}

install_package() {
    local pkg="$1"
    if is_macos; then
        if command_exists brew; then
            run_cmd brew install "$pkg"
        else
            error "Homebrew not installed. Please install Homebrew first."
            return 1
        fi
    elif is_linux; then
        if command_exists apt-get; then
            run_cmd sudo apt-get install -y "$pkg"
        elif command_exists yum; then
            run_cmd sudo yum install -y "$pkg"
        elif command_exists pacman; then
            run_cmd sudo pacman -S --noconfirm "$pkg"
        else
            error "No supported package manager found"
            return 1
        fi
    fi
}

install_packages_batch() {
    local pkgs=("$@")
    if is_macos; then
        for pkg in "${pkgs[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
                continue
            fi
            info "Installing $pkg..."
            run_cmd brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
        done
    elif is_linux; then
        local needs_update=false
        for pkg in "${pkgs[@]}"; do
            if ! apt_package_installed "$pkg"; then
                needs_update=true
                break
            fi
        done
        if [ "$needs_update" = true ]; then
            run_cmd sudo apt-get update
            for pkg in "${pkgs[@]}"; do
                if apt_package_installed "$pkg"; then
                    info "$pkg is already installed, skipping"
                    continue
                fi
                info "Installing $pkg..."
                run_cmd sudo apt-get install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            done
        else
            info "All packages already installed"
        fi
    fi
}
