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
        local pm
        if command_exists apt-get; then
            pm="apt"
        elif command_exists yum; then
            pm="yum"
        elif command_exists pacman; then
            pm="pacman"
        else
            error "No supported package manager found (apt/yum/pacman)"
            return 1
        fi

        local needs_install=()
        for pkg in "${pkgs[@]}"; do
            if ! _package_installed_linux "$pkg" "$pm"; then
                needs_install+=("$pkg")
            else
                info "$pkg is already installed, skipping"
            fi
        done

        if [ ${#needs_install[@]} -eq 0 ]; then
            info "All packages already installed"
            return 0
        fi

        case "$pm" in
            apt)
                run_cmd sudo apt-get update
                for pkg in "${needs_install[@]}"; do
                    run_cmd sudo apt-get install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                done
                ;;
            yum)
                for pkg in "${needs_install[@]}"; do
                    run_cmd sudo yum install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                done
                ;;
            pacman)
                run_cmd sudo pacman -Sy --noconfirm
                for pkg in "${needs_install[@]}"; do
                    run_cmd sudo pacman -S --noconfirm "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                done
                ;;
        esac
    fi
}

_package_installed_linux() {
    local pkg="$1"
    local pm="$2"
    case "$pm" in
        apt)    apt_package_installed "$pkg" ;;
        yum)    rpm -q "$pkg" &>/dev/null ;;
        pacman) pacman -Q "$pkg" &>/dev/null ;;
        *)      return 1 ;;
    esac
}
