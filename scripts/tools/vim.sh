#!/usr/bin/env bash
# scripts/tools/vim.sh
TOOL_NAME="vim"

install_vim() {
    info "Installing vim configuration..."
    local SPACEVIM_DIR="$DOTFILES_DIR/space-vim"
    if [ ! -f "$SPACEVIM_DIR/init.vim" ]; then
        info "space-vim submodule not found, initializing..."
        local original_dir="$(pwd)"
        cd "$DOTFILES_DIR"
        run_cmd git submodule update --init --recursive
        cd "$original_dir"
    fi
    backup_file "$HOME/.vimrc"
    mkdir -p "$HOME/.vim/undo"
    mkdir -p "$HOME/.vim/swap"
    mkdir -p "$HOME/.vim/autoload"
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        info "Installing vim-plug..."
        run_cmd curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        success "vim-plug installed"
    fi
    lnif "$SPACEVIM_DIR/init.vim" "$HOME/.vimrc"
    if [ ! -e "$HOME/.vimrc.bundle" ]; then
        lnif "$SPACEVIM_DIR/init.spacevim" "$HOME/.vimrc.bundle"
        success "Created ~/.vimrc.bundle"
    fi
    if [ -d "$HOME/.vim/plugged" ] && [ "$(ls -A "$HOME/.vim/plugged" 2>/dev/null)" ]; then
        info "Vim plugins already installed, skipping"
    else
        info "Installing vim plugins via vim-plug..."
        vim -E -s -c "source $HOME/.vimrc" -c "PlugInstall --sync" -c "qa" 2>/dev/null || true
    fi
    success "space-vim configured"
}
