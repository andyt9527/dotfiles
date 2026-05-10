#!/usr/bin/env bash
# =============================================================================
# Dotfiles Uninstall Script
# Removes symbolic links using the shared config manifest
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# Source lib modules
source "$SCRIPT_DIR/scripts/lib/os.sh"
source "$SCRIPT_DIR/scripts/lib/log.sh"
source "$SCRIPT_DIR/scripts/lib/assert.sh"
source "$SCRIPT_DIR/scripts/lib/symlink.sh"

# Set OS
export OS=${OS:-$(detect_os)}

# Source config manifest (shared with install.sh)
source "$SCRIPT_DIR/scripts/configs/manifest.sh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Dotfiles Uninstaller                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Remove symlinks defined in manifest (reverse order)
info "Removing config symlinks..."

for (( i=${#CONFIGS[@]}-1; i>=0; i-- )); do
    entry="${CONFIGS[$i]}"
    IFS='|' read -r src target platform_flags <<< "$entry"
    platform="${platform_flags%%:*}"

    # Check platform filter
    if [ "$platform" != "all" ]; then
        if [ "$platform" = "macos" ] && ! is_macos; then continue; fi
        if [ "$platform" = "linux" ] && ! is_linux; then continue; fi
    fi

    # Expand ~ in target
    target="${target/#\~/$HOME}"

    if [ -L "$target" ]; then
        info "Removing symlink: $target"
        rm "$target"
    elif [ -e "$target" ]; then
        warning "Not a symlink, skipping: $target"
    fi
done

# Remove vim symlinks (not in manifest, created by tools/vim.sh)
for vimfile in "$HOME/.vimrc" "$HOME/.vimrc.bundle"; do
    if [ -L "$vimfile" ]; then
        info "Removing symlink: $vimfile"
        rm "$vimfile"
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
