#!/usr/bin/env bash
# scripts/lib/symlink.sh
# Config file symlinking and backup

lnif() {
    if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then
        return 0
    fi
    if [ -e "$1" ]; then
        if [ "${DRY_RUN:-0}" = "1" ]; then
            info "[DRY-RUN] Would link: $1 → $2"
            return 0
        fi
        ln -sf "$1" "$2"
        return 0
    fi
    return 1
}

backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        if [ "${DRY_RUN:-0}" = "1" ]; then
            info "[DRY-RUN] Would back up: $file"
            return 0
        fi
        info "Backing up $file"
        mkdir -p "$BACKUP_DIR"
        # Handle basename conflicts (e.g. lazygit/config.yml vs lazydocker/config.yml)
        local backup_name
        backup_name="$(basename "$file")"
        local backup_path="$BACKUP_DIR/$backup_name"
        local counter=1
        while [ -e "$backup_path" ]; do
            backup_name="$(basename "$file").$counter"
            backup_path="$BACKUP_DIR/$backup_name"
            counter=$((counter + 1))
        done
        mv "$file" "$backup_path"
        echo "$file|$backup_name" >> "$BACKUP_DIR/manifest.txt"
    fi
}

link_config() {
    local src="$DOTFILES_DIR/$1"
    local target="$2"
    if [ "${DRY_RUN:-0}" != "1" ]; then
        mkdir -p "$(dirname "$target")"
    fi
    backup_file "$target"
    lnif "$src" "$target"
}
