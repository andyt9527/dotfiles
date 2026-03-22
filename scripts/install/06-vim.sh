#!/usr/bin/env bash
# =============================================================================
# Module: 06-vim
# Description: Install and configure space-vim
# =============================================================================

# Note: SCRIPT_DIR and DOTFILES_DIR are set by install.sh before sourcing

install_vim() {
    info "Installing vim..."

    local SPACEVIM_DIR="$DOTFILES_DIR/space-vim"
    local original_dir="$(pwd)"

    info "Setting up space-vim..."

    # Check if space-vim submodule exists
    if [ ! -f "$SPACEVIM_DIR/init.vim" ]; then
        info "space-vim submodule not found, initializing..."
        cd "$DOTFILES_DIR"
        git submodule update --init --recursive
        cd "$original_dir"
    fi

    # Backup existing vimrc, but keep existing ~/.vim directory
    backup_file "$HOME/.vimrc"

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
    if [ -d "$HOME/.vim/plugged" ] && [ "$(ls -A "$HOME/.vim/plugged" 2>/dev/null)" ]; then
        info "Vim plugins already installed, skipping"
    else
        info "Installing vim plugins via vim-plug..."
        vim -E -s -c "source $HOME/.vimrc" -c "PlugInstall --sync" -c "qa" 2>/dev/null || true
    fi

    success "space-vim configured"
}
