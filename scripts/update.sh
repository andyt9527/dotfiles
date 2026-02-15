#!/usr/bin/env bash
# =============================================================================
# Dotfiles Update Script
# Updates all plugins and configurations
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/utils.sh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Dotfiles Updater                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Update dotfiles repository
info "Updating dotfiles repository..."
cd "$DOTFILES_DIR"
git pull origin $(git branch --show-current 2>/dev/null || echo main)

# Update submodules (space-vim)
info "Updating submodules..."
git submodule update --init --recursive
git submodule update --remote

# Update Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Updating Oh My Zsh..."
    omz update || true
    
    # Update custom plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    for plugin_dir in "$ZSH_CUSTOM/plugins"/*; do
        if [ -d "$plugin_dir/.git" ]; then
            info "Updating plugin: $(basename "$plugin_dir")"
            cd "$plugin_dir" && git pull
        fi
    done
fi

# Update fzf
if [ -d "$HOME/.fzf" ]; then
    info "Updating fzf..."
    cd "$HOME/.fzf" && git pull && ./install --bin
fi

# Update Tmux plugins
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    info "Updating Tmux Plugin Manager..."
    cd "$HOME/.tmux/plugins/tpm" && git pull
    
    info "Updating Tmux plugins..."
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
fi

# Update Vim plugins
if command -v vim &> /dev/null && [ -f "$HOME/.vimrc" ]; then
    info "Updating Vim plugins..."
    vim +PlugUpdate +qall
fi

success "Update complete!"
echo ""
echo "You may need to restart your terminal or source your shell config."
