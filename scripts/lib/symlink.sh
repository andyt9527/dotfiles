#!/usr/bin/env bash
# scripts/lib/symlink.sh
# Config file symlinking and backup

lnif() {
    if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then
        return 0
    fi
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
        return 0
    fi
    return 1
}

backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        info "Backing up $file"
        mv "$file" "$BACKUP_DIR/"
    fi
}

link_config() {
    local src="$DOTFILES_DIR/$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"
    backup_file "$target"
    lnif "$src" "$target"
}
