#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installation Script for Ubuntu and macOS
# Tool Registry Architecture with Platform Abstraction Layer
# =============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Source all lib modules
source "$SCRIPT_DIR/scripts/lib/os.sh"
source "$SCRIPT_DIR/scripts/lib/log.sh"
source "$SCRIPT_DIR/scripts/lib/assert.sh"
source "$SCRIPT_DIR/scripts/lib/symlink.sh"
source "$SCRIPT_DIR/scripts/lib/package.sh"
source "$SCRIPT_DIR/scripts/lib/github.sh"

# Set OS
export OS=${OS:-$(detect_os)}

# Source config manifest
source "$SCRIPT_DIR/scripts/configs/manifest.sh"

# Source all tool modules
for tool_file in "$SCRIPT_DIR/scripts/tools/"*.sh; do
    if [ -f "$tool_file" ] && [ "$(basename "$tool_file")" != "_template.sh" ]; then
        source "$tool_file"
    fi
done

# Track enabled tools
ALL_TOOLS=()
ENABLED_TOOLS=()
SKIP_TOOLS=()
SKIP_SHELL=false
SKIP_CONFIGS=false

# Discover all tools from tool files
discover_tools() {
    ALL_TOOLS=()
    for tool_file in "$SCRIPT_DIR/scripts/tools/"*.sh; do
        local name
        name=$(basename "$tool_file" .sh)
        if [ "$name" != "_template" ]; then
            ALL_TOOLS+=("$name")
        fi
    done
}

# Print banner
print_banner() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║           Dotfiles Installer (Ubuntu & macOS)                  ║
║           Tool Registry Edition                                ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF
    info "Detected OS: $OS"
    info "Dotfiles directory: $DOTFILES_DIR"
}

# Print usage
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --tools <list>      Install only specified tools (comma-separated)"
    echo "  --skip-tools <list> Skip specified tools (comma-separated)"
    echo "  --skip-shell        Skip Oh My Zsh and Powerlevel10k"
    echo "  --skip-configs      Skip config file symlinks"
    echo "  --dry-run           Show what would be done without executing"
    echo "  --list-tools        List all available tools"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          Full installation"
    echo "  $0 --tools fd,bat,eza       Install only specific tools"
    echo "  $0 --skip-tools procs,bottom  Skip specific tools"
    echo "  $0 --dry-run                Preview what would be installed"
    echo ""
    echo "Available tools:"
    for tool in "${ALL_TOOLS[@]}"; do
        echo "  $tool"
    done
}

# Parse CLI arguments
parse_args() {
    discover_tools

    # Default: enable all tools
    ENABLED_TOOLS=("${ALL_TOOLS[@]}")

    while [[ $# -gt 0 ]]; do
        case $1 in
            --tools)
                if [ -z "$2" ]; then
                    error "--tools requires a comma-separated list"
                    exit 1
                fi
                ENABLED_TOOLS=()
                IFS=',' read -ra ENABLED_TOOLS <<< "$2"
                shift 2
                ;;
            --skip-tools)
                if [ -z "$2" ]; then
                    error "--skip-tools requires a comma-separated list"
                    exit 1
                fi
                IFS=',' read -ra SKIP_TOOLS <<< "$2"
                shift 2
                ;;
            --skip-shell)
                SKIP_SHELL=true
                shift
                ;;
            --skip-configs)
                SKIP_CONFIGS=true
                shift
                ;;
            --dry-run)
                export DRY_RUN=1
                shift
                ;;
            --list-tools)
                for tool in "${ALL_TOOLS[@]}"; do
                    echo "$tool"
                done
                exit 0
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done

    # Remove skipped tools from enabled list
    if [ ${#SKIP_TOOLS[@]} -gt 0 ]; then
        local filtered=()
        for tool in "${ENABLED_TOOLS[@]}"; do
            local skip=false
            for s in "${SKIP_TOOLS[@]}"; do
                if [ "$tool" = "$s" ]; then
                    skip=true
                    break
                fi
            done
            if [ "$skip" = false ]; then
                filtered+=("$tool")
            fi
        done
        ENABLED_TOOLS=("${filtered[@]}")
    fi
}

# Phase 1: Install prerequisites (git, curl, wget, node)
install_prerequisites() {
    info "=== Phase 1: Prerequisites ==="

    if is_macos; then
        if ! command_exists brew; then
            info "Installing Homebrew..."
            run_cmd bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ -d "/opt/homebrew/bin" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -d "/usr/local/bin" ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            info "Homebrew is already installed"
        fi
        install_packages_batch git curl wget node
    elif is_linux; then
        install_packages_batch git curl wget nodejs npm
    fi

    success "Prerequisites installed"
}

# Phase 2: Core packages (tmux, vim, tig, tree, ctags)
install_core_packages() {
    info "=== Phase 2: Core packages ==="

    if is_macos; then
        local pkgs=("tmux" "vim" "git" "tig" "tree" "universal-ctags" "jq" "yq" "httpie" "tldr" "the_silver_searcher")
        install_packages_batch "${pkgs[@]}"

        # tmux fallback
        if ! command_exists tmux; then
            info "Attempting brew postinstall tmux..."
            run_cmd brew postinstall tmux 2>/dev/null || warning "tmux postinstall failed"
        fi
    elif is_linux; then
        local pkgs=("tmux" "vim" "git" "tig" "tree" "jq" "httpie" "silversearcher-ag")
        install_packages_batch "${pkgs[@]}"
        install_universal_ctags
        install_build_essential
        install_tldr
    fi

    success "Core packages installed"
}

# Linux-only: build Universal Ctags from source
install_universal_ctags() {
    if ! is_linux; then return 0; fi

    if command -v ctags &>/dev/null && ctags --version 2>/dev/null | grep -q "Universal"; then
        info "Universal Ctags already installed, skipping"
        return 0
    fi

    info "Installing Universal Ctags from source..."
    local build_deps=("build-essential" "autoconf" "automake" "pkg-config")
    for dep in "${build_deps[@]}"; do
        if ! apt_package_installed "$dep"; then
            run_cmd sudo apt-get install -y "$dep"
        fi
    done

    local original_dir="$(pwd)"
    rm -rf /tmp/ctags
    run_cmd git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
    cd /tmp/ctags
    ./autogen.sh && ./configure --prefix=/usr/local && make && run_cmd sudo make install
    cd "$original_dir"
    rm -rf /tmp/ctags

    if command -v /usr/local/bin/ctags &>/dev/null && /usr/local/bin/ctags --version | grep -q "Universal"; then
        success "Universal Ctags installed"
    else
        warning "Universal Ctags installation may have failed"
    fi
}

# Linux-only: build-essential
install_build_essential() {
    if ! is_linux; then return 0; fi
    if apt_package_installed "build-essential"; then
        info "build-essential already installed, skipping"
        return 0
    fi
    run_cmd sudo apt-get install -y build-essential && success "build-essential installed"
}

# Linux-only: tldr
install_tldr() {
    if ! is_linux; then return 0; fi
    if needs_install tldr; then
        info "Installing tldr..."
        run_cmd sudo apt-get install -y tldr || run_cmd npm install -g tldr 2>/dev/null || true
    fi
}

# Phase 4: Link all config files using manifest
link_all_configs() {
    info "=== Phase 4: Config symlinks ==="

    for entry in "${CONFIGS[@]}"; do
        IFS='|' read -r src target platform_flags <<< "$entry"
        local platform="${platform_flags%%:*}"
        local flags="${platform_flags#*:}"
        [ "$flags" = "$platform" ] && flags=""

        # Check platform filter
        if [ "$platform" != "all" ]; then
            if [ "$platform" = "macos" ] && ! is_macos; then continue; fi
            if [ "$platform" = "linux" ] && ! is_linux; then continue; fi
        fi

        # Expand ~ in target
        target="${target/#\~/$HOME}"

        # Handle skip_existing flag
        if [[ "$flags" == *"skip_existing"* ]] && [ -e "$target" ]; then
            info "Skipping $(basename "$target") (already exists)"
            continue
        fi

        # Ensure parent directory exists
        mkdir -p "$(dirname "$target")"

        backup_file "$target"
        if lnif "$DOTFILES_DIR/$src" "$target"; then
            info "Linked $src → $target"
        else
            warning "Failed to link $src (source may not exist)"
        fi
    done

    success "Configuration files linked"
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
║  3. To customize Powerlevel10k prompt: p10k configure          ║
║  4. space-vim is ready! Customize via ~/.vimrc.bundle         ║
║                                                                ║
║  Shell Configuration:                                          ║
║  • ~/.zshrc              - Main configuration (linked)        ║
║  • ~/.zshrc.local        - Local customizations               ║
║                                                                ║
║  Your original configs are backed up to:
EOF
    echo "║    $BACKUP_DIR"
    cat << 'EOF2'
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF2
}

# Main installation flow
main() {
    parse_args "$@"
    assert_supported_os
    print_banner

    # Phase 1: Prerequisites
    install_prerequisites

    # Phase 2: Core packages
    install_core_packages

    # Phase 3: Tools (on demand)
    info "=== Phase 3: Tools ==="
    for tool in "${ENABLED_TOOLS[@]}"; do
        if [ "$tool" = "shell" ] || [ "$tool" = "tmux" ] || [ "$tool" = "vim" ]; then
            continue  # Skip special tools here, handled below
        fi
        local func="install_${tool//-/_}"
        if type -t "$func" &>/dev/null; then
            "$func"
        else
            warning "No install function found for tool: $tool (expected: $func)"
        fi
    done

    # Special tools (shell, tmux, vim) — always run unless explicitly skipped
    if [ "$SKIP_SHELL" != true ]; then
        local shell_in_tools=false
        for t in "${ENABLED_TOOLS[@]}"; do
            [ "$t" = "shell" ] && shell_in_tools=true
        done
        if [ "$shell_in_tools" = true ]; then
            install_shell
        fi
    fi

    for t in "${ENABLED_TOOLS[@]}"; do
        [ "$t" = "tmux" ] && install_tmux
        [ "$t" = "vim" ] && install_vim
    done

    # Phase 4: Config symlinks
    if [ "$SKIP_CONFIGS" != true ]; then
        link_all_configs
    fi

    post_install
}

main "$@"
