#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installation Script for Ubuntu and macOS
# Oh My Zsh + Powerlevel10k Edition
# Modular Architecture - delegates to scripts/install/
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
SKIP_OHMYZSH=false
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

# Backup existing file (also used by modules)
backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        info "Backing up $file"
        mv "$file" "$BACKUP_DIR/"
    fi
}

# Source all install modules
for module in "$SCRIPT_DIR/scripts/install"/[0-9]*.sh; do
    if [[ -f "$module" ]]; then
        # shellcheck source=./scripts/install/01-*.sh
        source "$module"
    fi
done

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
║  • ~/.zshrc.local        - Local customizations (conda, etc.) ║
║                                                                ║
║  Powerlevel10k Features:                                       ║
║  • Instant prompt - Blazing fast startup                       ║
║  • Git status - Comprehensive repo information                ║
║  • Context awareness - Shows relevant tool versions            ║
║  • Transient prompt - Clean scrollback (optional)             ║
║                                                                ║
║  Modern tools installed (if selected):                         ║
║  • fd: faster find    • bat: syntax-highlighted cat           ║
║  • eza: modern ls     • zoxide: smart cd                      ║
║  • fzf: fuzzy finder  • ripgrep: fast grep                    ║
║  • lazygit: TUI git   • lazydocker: TUI docker               ║
║  • claude: Claude Code CLI • codex: Codex CLI                ║
║                                                                ║
║  Your original configs are backed up to:                       ║
EOF
    echo "║    $BACKUP_DIR"
    cat << 'EOF2'
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF2
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
                SKIP_OHMYZSH=true
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

    # Run installation steps (delegated to modules)
    install_prerequisites

    if [ "$SKIP_PACKAGES" = false ]; then
        install_packages
        install_modern_tools
        install_lazygit
        install_lazydocker
        install_claude_code
        install_codex
        install_cc_switch
    fi

    install_shell
    install_tmux
    install_vim
    install_configs
    post_install
}

# Run main function
main "$@"
