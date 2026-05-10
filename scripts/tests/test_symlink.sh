#!/usr/bin/env bats
# scripts/tests/test_symlink.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/symlink.sh"

    # Create temp directories for each test
    TEST_TEMP_DIR="$(mktemp -d)"
    DOTFILES_DIR="$TEST_TEMP_DIR/dotfiles"
    BACKUP_DIR="$TEST_TEMP_DIR/backup"
    mkdir -p "$DOTFILES_DIR" "$BACKUP_DIR"
}

teardown() {
    [ -d "$TEST_TEMP_DIR" ] && rm -rf "$TEST_TEMP_DIR"
}

# --- lnif ---

@test "lnif creates symlink when source exists" {
    local src="$DOTFILES_DIR/zshrc"
    local target="$TEST_TEMP_DIR/.zshrc"
    touch "$src"
    run lnif "$src" "$target"
    [ "$status" -eq 0 ]
    [ -L "$target" ]
    [ "$(readlink "$target")" = "$src" ]
}

@test "lnif returns 1 when source missing" {
    local src="$DOTFILES_DIR/nonexistent"
    local target="$TEST_TEMP_DIR/.zshrc"
    run lnif "$src" "$target"
    [ "$status" -eq 1 ]
    [ ! -e "$target" ]
}

@test "lnif returns 0 when symlink already points to source" {
    local src="$DOTFILES_DIR/zshrc"
    local target="$TEST_TEMP_DIR/.zshrc"
    touch "$src"
    ln -sf "$src" "$target"
    # Running lnif again should succeed without error
    run lnif "$src" "$target"
    [ "$status" -eq 0 ]
    [ "$(readlink "$target")" = "$src" ]
}

@test "lnif replaces existing symlink with new target" {
    local src1="$DOTFILES_DIR/zshrc_old"
    local src2="$DOTFILES_DIR/zshrc_new"
    local target="$TEST_TEMP_DIR/.zshrc"
    touch "$src1" "$src2"
    ln -sf "$src1" "$target"
    [ "$(readlink "$target")" = "$src1" ]
    # lnif should replace with src2
    run lnif "$src2" "$target"
    [ "$status" -eq 0 ]
    [ "$(readlink "$target")" = "$src2" ]
}

# --- backup_file ---

@test "backup_file moves regular file to BACKUP_DIR" {
    local file="$TEST_TEMP_DIR/config.yml"
    echo "original" > "$file"
    [ -f "$file" ]
    run backup_file "$file"
    [ ! -f "$file" ]
    [ -f "$BACKUP_DIR/config.yml" ]
    [ "$(cat "$BACKUP_DIR/config.yml")" = "original" ]
}

@test "backup_file skips symlinks" {
    local src="$DOTFILES_DIR/config.yml"
    local link="$TEST_TEMP_DIR/config_link"
    touch "$src"
    ln -sf "$src" "$link"
    [ -L "$link" ]
    run backup_file "$link"
    # Symlink should still be there
    [ -L "$link" ]
    # Nothing in backup dir
    [ "$(ls "$BACKUP_DIR" | wc -l | tr -d ' ')" = "0" ]
}

@test "backup_file skips nonexistent files" {
    run backup_file "$TEST_TEMP_DIR/nonexistent"
    [ "$status" -eq 0 ]
    [ "$(ls "$BACKUP_DIR" | wc -l | tr -d ' ')" = "0" ]
}

# --- link_config ---

@test "link_config backs up and symlinks" {
    # Create source config in dotfiles
    mkdir -p "$DOTFILES_DIR/config"
    echo "dotfiles-version" > "$DOTFILES_DIR/config/app.conf"

    # Create existing file at target location
    local target_dir="$TEST_TEMP_DIR/home"
    mkdir -p "$target_dir"
    echo "old-version" > "$target_dir/app.conf"

    run link_config "config/app.conf" "$target_dir/app.conf"

    # Old file should be backed up
    [ -f "$BACKUP_DIR/app.conf" ]
    [ "$(cat "$BACKUP_DIR/app.conf")" = "old-version" ]

    # Target should be a symlink to dotfiles version
    [ -L "$target_dir/app.conf" ]
    [ "$(readlink "$target_dir/app.conf")" = "$DOTFILES_DIR/config/app.conf" ]
}

@test "link_config creates target directory if missing" {
    mkdir -p "$DOTFILES_DIR/config"
    echo "content" > "$DOTFILES_DIR/config/app.conf"

    local target="$TEST_TEMP_DIR/deep/nested/dir/app.conf"
    run link_config "config/app.conf" "$target"

    [ -L "$target" ]
    [ "$(readlink "$target")" = "$DOTFILES_DIR/config/app.conf" ]
}

@test "link_config returns 1 when source does not exist" {
    local target="$TEST_TEMP_DIR/app.conf"
    run link_config "nonexistent/app.conf" "$target"
    [ "$status" -eq 1 ]
    [ ! -e "$target" ]
}
