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
if check_command git; then
    info "Updating dotfiles repository..."
    cd "$DOTFILES_DIR"
    git pull origin $(git branch --show-current 2>/dev/null || echo main)

    # Update submodules (space-vim)
    info "Updating submodules..."
    git submodule update --init --recursive
    git submodule update --remote
else
    warning "git not found, skipping dotfiles update"
fi

# Update Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    if check_command omz; then
        info "Updating Oh My Zsh..."
        omz update || true
    fi

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
    if check_command git; then
        info "Updating fzf..."
        cd "$HOME/.fzf" && git pull && ./install --bin
    fi
fi

# Update Tmux plugins
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    if check_command git; then
        info "Updating Tmux Plugin Manager..."
        cd "$HOME/.tmux/plugins/tpm" && git pull
    fi

    if [ -f "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]; then
        info "Updating Tmux plugins..."
        "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
    fi
fi

# Update Vim plugins
if check_command vim && [ -f "$HOME/.vimrc" ]; then
    info "Updating Vim plugins..."
    vim +PlugUpdate +qall
fi

success "Update complete!"
echo ""
echo "You may need to restart your terminal or source your shell config."
