#!/usr/bin/env bats
# scripts/tests/test_assert.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
}

@test "command_exists returns 0 for existing command" {
    run command_exists bash
    [ "$status" -eq 0 ]
}

@test "command_exists returns 1 for missing command" {
    run command_exists nonexistent_command_xyz_12345
    [ "$status" -eq 1 ]
}

@test "needs_install returns 0 for missing command" {
    run needs_install nonexistent_command_xyz_12345
    [ "$status" -eq 0 ]
}

@test "needs_install returns 1 for existing command" {
    run needs_install bash
    [ "$status" -eq 1 ]
}
