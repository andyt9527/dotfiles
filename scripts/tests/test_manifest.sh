#!/usr/bin/env bats
# scripts/tests/test_manifest.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/configs/manifest.sh"
}

@test "CONFIGS array is not empty" {
    [ "${#CONFIGS[@]}" -gt 0 ]
}

@test "each CONFIGS entry has at least 3 pipe-delimited fields" {
    for entry in "${CONFIGS[@]}"; do
        local field_count
        field_count=$(echo "$entry" | awk -F'|' '{print NF}')
        [ "$field_count" -ge 3 ]
    done
}

@test "manifest contains .zshrc entry" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"shell/zshrc"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}

@test "manifest contains .tmux.conf entry" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"tmux/tmux.conf"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}

@test "manifest has macos-specific lazygit config" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"lazygit"*"macos"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}

@test "manifest has linux-specific lazygit config" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"lazygit"*"linux"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}
