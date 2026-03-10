#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installation Script for Ubuntu and macOS
# Oh My Zsh + Powerlevel10k Edition
# =============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities
source "$SCRIPT_DIR/scripts/utils.sh"

# Configuration
DOTFILES_DIR="$SCRIPT_DIR"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Installation flags (default: install all optional tools)
INSTALL_MODERN_TOOLS=true
INSTALL_LAZYGIT=true
INSTALL_LAZYDOCKER=true
INSTALL_CLAUDE_CODE=true
INSTALL_CODEX=true
INSTALL_CC_SWITCH=true
SKIP_PACKAGES=false
SKIP_P10K=false

# Print banner
cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║           Dotfiles Installer (Ubuntu & macOS)                  ║
║           Oh My Zsh + Powerlevel10k Edition                    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF

info "Detected OS: $OS"
info "Dotfiles directory: $DOTFILES_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup existing file
backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        info "Backing up $file"
        mv "$file" "$BACKUP_DIR/"
    fi
}

# Install prerequisites
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
        # Check and install packages one by one
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

# Install modern CLI tools
install_modern_tools() {
    if [ "$INSTALL_MODERN_TOOLS" = false ]; then
        return
    fi

    info "Installing modern CLI tools..."

    if [ "$OS" = "macos" ]; then
        # Core tools with individual checks
        local core_tools=("fd" "bat" "eza" "zoxide" "fzf" "ripgrep")
        for pkg in "${core_tools[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

        # Optional tools
        local optional_tools=("duf" "dust" "procs" "bottom")
        for pkg in "${optional_tools[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

        # Additional tools
        local additional_tools=("tldr" "httpie" "jq" "yq" "tree")
        for pkg in "${additional_tools[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

    elif [ "$OS" = "linux" ]; then
        # Check and install fd-find
        if command_exists fdfind || command_exists fd; then
            info "fd is already installed, skipping"
        else
            info "Installing fd-find..."
            sudo apt-get install -y fd-find && success "fd-find installed" || warning "Failed to install fd-find"
        fi

        # Check and install bat
        if command_exists batcat || command_exists bat; then
            info "bat is already installed, skipping"
        else
            info "Installing bat..."
            sudo apt-get install -y bat && success "bat installed" || warning "Failed to install bat"
        fi

        # Create symlinks for fd and bat if needed (Ubuntu uses different names)
        if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
            sudo ln -sf $(which fdfind) /usr/local/bin/fd 2>/dev/null || true
        fi

        if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
            sudo ln -sf $(which batcat) /usr/local/bin/bat 2>/dev/null || true
        fi

        # Install rust-based tools via cargo if available
        if command -v cargo &> /dev/null; then
            local rust_tools=("eza" "zoxide" "du-dust" "duf" "procs" "bottom")
            for tool in "${rust_tools[@]}"; do
                local cmd_name="$tool"
                [ "$tool" = "du-dust" ] && cmd_name="dust"
                if command_exists "$cmd_name"; then
                    info "$tool is already installed, skipping"
                else
                    info "Installing $tool via cargo..."
                    cargo install "$tool" 2>/dev/null && success "$tool installed" || warning "Failed to install $tool"
                fi
            done
        fi

        # Install zoxide via install script if not already installed
        if command_exists zoxide; then
            info "zoxide is already installed, skipping"
        else
            info "Installing zoxide..."
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            success "zoxide installed"
        fi
    fi

    success "Modern CLI tools installed"
}

# Install Powerlevel10k
install_powerlevel10k() {
    if [ "$SKIP_P10K" = true ]; then
        return
    fi

    local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$P10K_DIR" ]; then
        warning "Powerlevel10k already installed"
        return
    fi

    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    success "Powerlevel10k installed"
}

# Install Lazygit
install_lazygit() {
    if [ "$INSTALL_LAZYGIT" = false ]; then
        return
    fi

    if command -v lazygit &> /dev/null; then
        warning "Lazygit already installed"
        return
    fi

    info "Installing Lazygit..."

    if [ "$OS" = "macos" ]; then
        brew install lazygit
    elif [ "$OS" = "linux" ]; then
        # Get latest version (use grep with basic regex for portability)
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -o 'v[0-9.]*' | head -1 | sed 's/v//')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
    fi

    success "Lazygit installed"
}

# Install Lazydocker
install_lazydocker() {
    if [ "$INSTALL_LAZYDOCKER" = false ]; then
        return
    fi

    if command -v lazydocker &> /dev/null; then
        warning "Lazydocker already installed"
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

# Install Claude Code
install_claude_code() {
    if [ "$INSTALL_CLAUDE_CODE" = false ]; then
        return
    fi

    if command -v claude &> /dev/null; then
        warning "Claude Code already installed"
        return
    fi

    info "Installing Claude Code..."

    if ! command -v npm &> /dev/null; then
        error "npm is required to install Claude Code"
        return
    fi

    npm install -g @anthropic-ai/claude-code

    # Verify installation
    if command -v claude &> /dev/null; then
        success "Claude Code installed"
    else
        warning "Claude Code installation may have failed"
    fi
}

# Install cc-switch
install_cc_switch() {
    if [ "$INSTALL_CC_SWITCH" = false ]; then
        return
    fi

    if command -v cc-switch &> /dev/null; then
        warning "cc-switch already installed"
        return
    fi

    info "Installing cc-switch..."

    if [ "$OS" = "macos" ]; then
        brew tap farion1231/ccswitch
        brew install --cask cc-switch
    elif [ "$OS" = "linux" ]; then
        install_cc_switch_linux
    else
        warning "cc-switch is not supported on this OS"
        return
    fi

    # Verify installation
    if command -v cc-switch &> /dev/null; then
        success "cc-switch installed"
    else
        warning "cc-switch installation may have failed"
    fi
}

# Install cc-switch on Linux (download latest .deb from GitHub)
install_cc_switch_linux() {
    info "Downloading latest cc-switch release..."

    local tmp
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    cd "$tmp" || exit 1

    # get latest tag
    TAG=$(curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest | jq -r .tag_name)

    if [ -z "$TAG" ] || [ "$TAG" = "null" ]; then
        error "Failed to get latest version"
        return 1
    fi

    info "Latest version: $TAG"

    # detect arch
    case "$(uname -m)" in
        x86_64|amd64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac

    FILE="CC-Switch-${TAG}-Linux-${ARCH}.deb"
    URL="https://github.com/farion1231/cc-switch/releases/download/${TAG}/${FILE}"

    info "Downloading $FILE"

    curl -fL -o "$FILE" "$URL"

    if ! command -v apt-get >/dev/null; then
        error "apt-get required"
        return 1
    fi

    sudo apt-get install -y "./$FILE"

    success "cc-switch installed successfully"
}

# Install Codex CLI
install_codex() {
    if [ "$INSTALL_CODEX" = false ]; then
        return
    fi

    if command -v codex &> /dev/null; then
        warning "Codex already installed"
        return
    fi

    info "Installing Codex CLI..."

    if ! command -v npm &> /dev/null; then
        error "npm is required to install Codex"
        return
    fi

    npm install -g @openai/codex

    # Verify installation
    if command -v codex &> /dev/null; then
        success "Codex installed"
    else
        warning "Codex installation may have failed"
    fi
}

# Install fzf
install_fzf() {
    if [ -d ~/.fzf ]; then
        warning "fzf already installed"
        return
    fi

    info "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    # Run install script; if it fails (e.g., due to missing dependencies), continue anyway
    ~/.fzf/install --no-key-bindings --no-completion 2>/dev/null || true
    success "fzf installed"
}

# Install Oh My Zsh
install_ohmyzsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        warning "Oh My Zsh already installed"
        return
    fi

    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # Install plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    # zsh-history-substring-search
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
        git clone https://github.com/zsh-users/zsh-history-substring-search.git \
            "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    fi

    success "Oh My Zsh installed"
}

# Change default shell to zsh
change_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)

    if [ "$SHELL" = "$zsh_path" ]; then
        info "Shell is already zsh"
        return
    fi

    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        if [ "$OS" = "macos" ]; then
            info "Adding zsh to /etc/shells"
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
    fi

    info "Changing default shell to zsh..."
    chsh -s "$zsh_path"
    success "Shell changed to zsh"
}

# Install Tmux Plugin Manager
install_tpm() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        warning "TPM already installed"
        return
    fi

    info "Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    success "TPM installed"
}

# Install space-vim (as submodule)
install_spacevim() {
    local SPACEVIM_DIR="$DOTFILES_DIR/space-vim"
    local ORIGINAL_DIR="$(pwd)"

    info "Setting up space-vim..."

    # Check if space-vim submodule exists
    if [ ! -f "$SPACEVIM_DIR/init.vim" ]; then
        warning "space-vim submodule not found, initializing..."
        cd "$DOTFILES_DIR"
        git submodule update --init --recursive
        cd "$ORIGINAL_DIR"
    fi

    # Backup existing vim config
    backup_file "$HOME/.vimrc"
    if [ -d "$HOME/.vim" ] && [ ! -L "$HOME/.vim" ]; then
        info "Backing up ~/.vim directory"
        mv "$HOME/.vim" "$BACKUP_DIR/"
    fi

    # Create vim directories
    mkdir -p "$HOME/.vim/undo"
    mkdir -p "$HOME/.vim/swap"
    mkdir -p "$HOME/.vim/autoload"

    # Install vim-plug
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        info "Installing vim-plug..."
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        success "vim-plug installed"
    fi

    # Create symlinks
    lnif "$SPACEVIM_DIR/init.vim" "$HOME/.vimrc"

    # Create .vimrc.bundle if not exists
    if [ ! -e "$HOME/.vimrc.bundle" ]; then
        lnif "$SPACEVIM_DIR/init.spacevim" "$HOME/.vimrc.bundle"
        success "Created ~/.vimrc.bundle"
    fi

    # Install vim plugins (non-interactive mode)
    info "Installing vim plugins via vim-plug..."
    # Use vim in ex mode for non-interactive installation
    vim -E -s -c "source $HOME/.vimrc" -c "PlugInstall --sync" -c "qa" 2>/dev/null || true

    success "space-vim configured"
}

# Link configuration files
link_configs() {
    info "Linking configuration files..."

    # Create necessary directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/zsh"
    mkdir -p "$HOME/.vim/undo"
    mkdir -p "$HOME/.vim/swap"
    mkdir -p "$HOME/.tmux/logs"

    # Shell configs - Modular structure
    # Main shell configs
    backup_file "$HOME/.bashrc"
    lnif "$DOTFILES_DIR/shell/bashrc" "$HOME/.bashrc"

    backup_file "$HOME/.zshrc"
    lnif "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"

    # Local zsh config (conda, proxy, etc.)
    # Only link if not exists to preserve user's local customizations
    if [ ! -e "$HOME/.zshrc.local" ]; then
        lnif "$DOTFILES_DIR/shell/zshrc.local" "$HOME/.zshrc.local"
        info "Created ~/.zshrc.local (conda template)"
    else
        info "Skipping ~/.zshrc.local (already exists)"
    fi

    success "Shell configuration files linked (modular structure)"

    # Tmux config
    backup_file "$HOME/.tmux.conf"
    lnif "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

    # Git config
    backup_file "$HOME/.gitconfig"
    lnif "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

    # Tig config
    backup_file "$HOME/.tigrc"
    lnif "$DOTFILES_DIR/tig/tigrc" "$HOME/.tigrc"

    backup_file "$HOME/.tigrc.theme"
    lnif "$DOTFILES_DIR/tig/tigrc.theme" "$HOME/.tigrc.theme"

    # Vim config (space-vim)
    # This is handled by install_spacevim() function

    # Powerlevel10k config
    if [ -f "$DOTFILES_DIR/config/p10k.zsh" ] && [ "$SKIP_P10K" = false ]; then
        backup_file "$HOME/.p10k.zsh"
        lnif "$DOTFILES_DIR/config/p10k.zsh" "$HOME/.p10k.zsh"
    fi

    # Lazygit config
    if [ -f "$DOTFILES_DIR/config/lazygit.yml" ]; then
        if [ "$OS" = "macos" ]; then
            mkdir -p "$HOME/Library/Application Support/lazygit"
            lnif "$DOTFILES_DIR/config/lazygit.yml" "$HOME/Library/Application Support/lazygit/config.yml"
        else
            mkdir -p "$HOME/.config/lazygit"
            lnif "$DOTFILES_DIR/config/lazygit.yml" "$HOME/.config/lazygit/config.yml"
        fi
    fi

    # Lazydocker config
    if [ -f "$DOTFILES_DIR/config/lazydocker.yml" ]; then
        if [ "$OS" = "macos" ]; then
            mkdir -p "$HOME/Library/Application Support/lazydocker"
            lnif "$DOTFILES_DIR/config/lazydocker.yml" "$HOME/Library/Application Support/lazydocker/config.yml"
        else
            mkdir -p "$HOME/.config/lazydocker"
            lnif "$DOTFILES_DIR/config/lazydocker.yml" "$HOME/.config/lazydocker/config.yml"
        fi
    fi

    success "Configuration files linked"
}

# Install platform-specific packages
install_platform_packages() {
    info "Installing platform-specific packages..."

    if [ "$OS" = "macos" ]; then
        # macOS specific
        # Install packages one by one to handle partial failures gracefully
        local packages=("tmux" "vim" "git" "tig" "tree")
        local optional_packages=("reattach-to-user-namespace" "the_silver_searcher" "ripgrep" "fzf" "universal-ctags" "jq" "yq" "httpie" "tldr")

        info "Installing core packages..."
        for pkg in "${packages[@]}"; do
            if brew_package_installed "$pkg"; then
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
                        brew postinstall tmux 2>/dev/null || warning "tmux postinstall failed, tmux should still work"
                    fi
                fi
            fi
        done

        info "Installing optional packages..."
        for pkg in "${optional_packages[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
            else
                info "Installing $pkg..."
                brew install "$pkg" 2>/dev/null && success "$pkg installed" || warning "Failed to install $pkg"
            fi
        done

    elif [ "$OS" = "linux" ]; then
        # Ubuntu/Debian specific - check each package before installing
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
                if command_exists "$cmd_name" || apt_package_installed "$pkg"; then
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
        # Try to install from source if package not available
        if command_exists ctags && ctags --version 2>/dev/null | grep -q "Universal"; then
            info "Universal Ctags is already installed, skipping"
        else
            info "Installing Universal Ctags from source..."
            # Check build dependencies first
            local build_deps=("build-essential" "autoconf" "automake" "pkg-config")
            for dep in "${build_deps[@]}"; do
                if ! apt_package_installed "$dep"; then
                    sudo apt-get install -y "$dep"
                fi
            done
            
            local ORIGINAL_DIR="$(pwd)"
            rm -rf /tmp/ctags
            git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
            cd /tmp/ctags
            ./autogen.sh
            ./configure --prefix=/usr/local
            make
            sudo make install
            cd "$ORIGINAL_DIR"
            rm -rf /tmp/ctags

            # Verify installation
            if command -v /usr/local/bin/ctags &> /dev/null && /usr/local/bin/ctags --version | grep -q "Universal"; then
                success "Universal Ctags installed successfully"
            else
                warning "Universal Ctags installation may have failed"
                warning "Please install manually: https://github.com/universal-ctags/ctags"
            fi
        fi

        # Build tools
        if apt_package_installed "build-essential"; then
            info "build-essential is already installed, skipping"
        else
            sudo apt-get install -y build-essential && success "build-essential installed" || warning "Failed to install build-essential"
        fi

        # Install tldr
        if command_exists tldr; then
            info "tldr is already installed, skipping"
        else
            info "Installing tldr..."
            sudo apt-get install -y tldr || npm install -g tldr 2>/dev/null || true
        fi
    fi

    success "Platform-specific packages installed"
}

# Post-installation message
post_install() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════╗
║                   Installation Complete!                       ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Next steps:                                                   ║
║  1. Restart your terminal or run: source ~/.zshrc             ║
║  2. For tmux plugins, press 'prefix + I' in a tmux session    ║
║  3. To customize Powerlevel10k prompt: p10k configure         ║
║  4. space-vim is ready! Customize via ~/.vimrc.bundle         ║
║                                                                ║
║  Shell Configuration:                                          ║
║  • ~/.zshrc              - Main configuration (linked)         ║
║  • ~/.zshrc.local        - Local customizations (conda, etc.)  ║
║                                                                ║
║  Powerlevel10k Features:                                       ║
║  • Instant prompt - Blazing fast startup                       ║
║  • Git status - Comprehensive repo information                 ║
║  • Context awareness - Shows relevant tool versions            ║
║  • Transient prompt - Clean scrollback (optional)              ║
║                                                                ║
║  Modern tools installed (if selected):                         ║
║  • fd: faster find    • bat: syntax-highlighted cat           ║
║  • eza: modern ls     • zoxide: smart cd                      ║
║  • fzf: fuzzy finder  • ripgrep: fast grep                    ║
║  • lazygit: TUI git   • lazydocker: TUI docker                ║
║  • claude: Claude Code CLI • codex: Codex CLI                 ║
║                                                                ║
║  Your original configs are backed up to:                       ║
EOF
    echo "║    $BACKUP_DIR"
cat << 'EOF'
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF
}

# Main installation flow
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --skip-ohmyzsh)
                shift
                ;;
            --skip-p10k)
                SKIP_P10K=true
                shift
                ;;
            --with-modern-tools)
                INSTALL_MODERN_TOOLS=true
                shift
                ;;
            --with-lazygit)
                INSTALL_LAZYGIT=true
                shift
                ;;
            --with-lazydocker)
                INSTALL_LAZYDOCKER=true
                shift
                ;;
            --with-claude-code)
                INSTALL_CLAUDE_CODE=true
                shift
                ;;
            --with-codex)
                INSTALL_CODEX=true
                shift
                ;;
            --with-cc-switch)
                INSTALL_CC_SWITCH=true
                shift
                ;;
            --with-all)
                INSTALL_MODERN_TOOLS=true
                INSTALL_LAZYGIT=true
                INSTALL_LAZYDOCKER=true
                INSTALL_CLAUDE_CODE=true
                INSTALL_CODEX=true
                INSTALL_CC_SWITCH=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-packages         Skip package installation"
                echo "  --skip-ohmyzsh          Skip Oh My Zsh installation"
                echo "  --skip-p10k             Skip Powerlevel10k installation"
                echo "  --with-modern-tools     Install modern CLI tools (fd, bat, eza, etc.)"
                echo "  --with-lazygit          Install Lazygit TUI"
                echo "  --with-lazydocker       Install Lazydocker TUI"
                echo "  --with-claude-code      Install Claude Code CLI"
                echo "  --with-codex            Install Codex CLI"
                echo "  --with-cc-switch        Install cc-switch"
                echo "  --help, -h              Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                      Full installation (default)"
                echo "  $0 --skip-packages      Skip optional tools"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Run installation steps
    install_prerequisites
    if [ "$SKIP_PACKAGES" = false ]; then
        install_platform_packages
        install_modern_tools
        install_lazygit
        install_lazydocker
        install_claude_code
        install_codex
        install_cc_switch
    fi
    install_fzf
    install_ohmyzsh
    install_powerlevel10k
    change_shell
    install_tpm
    install_spacevim
    link_configs
    post_install
}

# Run main function
main "$@"
