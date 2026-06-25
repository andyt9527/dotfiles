#!/usr/bin/env bats

setup() {
    load helpers/test_helper
}

@test "shell/aliases.zsh has self-contained comment for OSTYPE use" {
    grep -q 'self-contained' "$DOTFILES_TEST_PROJECT_DIR/shell/aliases.zsh"
}

@test "shell/utils.sh has self-contained comment or sources scripts/lib/os.sh" {
    grep -qE 'self-contained|source.*scripts/lib/os\.sh' "$DOTFILES_TEST_PROJECT_DIR/shell/utils.sh"
}

@test "shell/zshrc.local empty macOS block removed" {
    # The empty macOS block (if [[ "$OSTYPE" == "darwin"* ]]; then ... : ... fi)
    # is deleted entirely; verify the darwin guard is no longer present.
    # (Brief's original `grep -A1 | grep -q '^[[:space:]]*:'` only inspected the
    # line immediately after `if`, but the block had comment lines between `if`
    # and `:`, so it never matched. Checking for the guard itself is equivalent
    # since the fix removes the whole block.)
    ! grep -q 'if \[\[ "\$OSTYPE" == "darwin"\* \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local does not contain hardcoded /home/andy/ paths" {
    ! grep -n '/home/andy/' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local modules.sh source is guarded with [[ -f" {
    grep -q '\[\[ -f /etc/profile.d/modules.sh \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local NPU block is guarded with [[ -d \$HOME/NPU" {
    grep -q '\[\[ -d "\$HOME/NPU" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local Android SDK block is guarded with [[ -d" {
    grep -q '\[\[ -d "\$HOME/andywork/sdk-android/Sdk" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local does not double the Sdk segment in build-tools path" {
    ! grep -q 'Sdk/Sdk/build-tools' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/bashrc does not contain hardcoded /Users/andy/ paths" {
    ! grep -n '/Users/andy/' "$DOTFILES_TEST_PROJECT_DIR/shell/bashrc"
}

@test "shell/bashrc jishushell path is guarded" {
    grep -q '\[\[ -d "\$HOME/\.jishushell/bin" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/bashrc"
}

@test "shell/bashrc mavis path is guarded and not duplicated" {
    local count
    count=$(grep -c '\[\[ -d "\$HOME/\.mavis/bin" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/bashrc")
    [ "$count" -eq 1 ]
}
