#!/usr/bin/env bash
# =============================================================================
# Dotfiles Uninstall Script
# Removes symbolic links created by install.sh
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/utils.sh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Dotfiles Uninstaller                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Files to remove
DOTFILES=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.zshrc.local"
    "$HOME/.tmux.conf"
    "$HOME/.gitconfig"
    "$HOME/.tigrc"
    "$HOME/.tigrc.theme"
    "$HOME/.vimrc"
    "$HOME/.vimrc.bundle"
    "$HOME/.p10k.zsh"
    "$HOME/.config/starship.toml"
)

# Platform-specific config paths
if [[ "$OSTYPE" == "darwin"* ]]; then
    LAZYGIT_CONFIG="$HOME/Library/Application Support/lazygit/config.yml"
    LAZYDOCKER_CONFIG="$HOME/Library/Application Support/lazydocker/config.yml"
else
    LAZYGIT_CONFIG="$HOME/.config/lazygit/config.yml"
    LAZYDOCKER_CONFIG="$HOME/.config/lazydocker/config.yml"
fi

# Add platform-specific configs
DOTFILES+=("$LAZYGIT_CONFIG" "$LAZYDOCKER_CONFIG")

# Remove symbolic links
for file in "${DOTFILES[@]}"; do
    if [ -L "$file" ]; then
        info "Removing symlink: $file"
        rm "$file"
    elif [ -e "$file" ]; then
        warning "Not a symlink, skipping: $file"
    fi
done

# Clean up Powerlevel10k instant prompt cache
if [ -d "$HOME/.cache" ]; then
    info "Cleaning Powerlevel10k cache..."
    rm -f "$HOME/.cache/p10k-instant-prompt-"*".zsh" 2>/dev/null || true
fi

# Clean up vim-plug and plugins
if [ -d "$HOME/.vim/plugged" ]; then
    info "Note: ~/.vim/plugged contains vim plugins (not removed)"
fi

echo ""
echo "Uninstallation complete!"
echo ""
echo "Note: The following were not removed:"
echo "  - ~/.oh-my-zsh (Oh My Zsh installation)"
echo "  - ~/.oh-my-zsh/custom/themes/powerlevel10k (Powerlevel10k theme)"
echo "  - ~/.tmux/plugins (Tmux plugins)"
echo "  - ~/.fzf (FZF installation)"
echo "  - ~/.vim (Vim configuration and plugins)"
echo ""
echo "To completely remove everything, run:"
echo "  rm -rf ~/.oh-my-zsh ~/.tmux ~/.fzf ~/.vim ~/.cache/p10k-*"
echo ""
