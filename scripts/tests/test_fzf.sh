#!/usr/bin/env bats
# scripts/tests/test_fzf.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/tools/fzf.sh"

    # Isolate HOME so a real ~/.fzf dir or fzf binary on the dev machine
    # can't short-circuit the install path under test.
    export HOME="$BATS_TMPDIR/fake_home"
    mkdir -p "$HOME"
}

@test "install_fzf skips when fzf command already exists" {
    command() {
        if [ "$1" = "-v" ] && [ "$2" = "fzf" ]; then
            return 0
        fi
        builtin command "$@"
    }
    is_macos() { return 0; }

    local cap="$BATS_TMPDIR/fzf_calls"
    : > "$cap"
    run_cmd() { echo "$@" >> "$cap"; }

    run install_fzf
    [ "$status" -eq 0 ]
    [ "$(cat "$cap")" = "" ]
}

@test "install_fzf on macOS calls brew install fzf, does not clone" {
    command() {
        if [ "$1" = "-v" ] && [ "$2" = "fzf" ]; then
            return 1
        fi
        builtin command "$@"
    }
    command_exists() { return 1; }
    is_macos() { return 0; }
    is_linux() { return 1; }

    local cap="$BATS_TMPDIR/fzf_calls"
    : > "$cap"
    run_cmd() { echo "$@" >> "$cap"; }

    run install_fzf
    [ "$status" -eq 0 ]
    local calls
    calls=$(cat "$cap")
    [[ "$calls" == *"brew install fzf"* ]]
    [[ "$calls" != *"git clone"* ]]
}

@test "install_fzf on Linux with apt-get calls apt-get install, does not clone" {
    command() {
        if [ "$1" = "-v" ] && [ "$2" = "fzf" ]; then
            return 1
        fi
        builtin command "$@"
    }
    command_exists() { [ "$1" = "apt-get" ]; }
    is_macos() { return 1; }
    is_linux() { return 0; }

    local cap="$BATS_TMPDIR/fzf_calls"
    : > "$cap"
    run_cmd() { echo "$@" >> "$cap"; }

    run install_fzf
    [ "$status" -eq 0 ]
    local calls
    calls=$(cat "$cap")
    [[ "$calls" == *"sudo apt-get install -y fzf"* ]]
    [[ "$calls" != *"git clone"* ]]
}

@test "install_fzf on Linux without apt-get falls back to git clone" {
    command() {
        if [ "$1" = "-v" ] && [ "$2" = "fzf" ]; then
            return 1
        fi
        builtin command "$@"
    }
    command_exists() { return 1; }
    is_macos() { return 1; }
    is_linux() { return 0; }

    local cap="$BATS_TMPDIR/fzf_calls"
    : > "$cap"
    run_cmd() { echo "$@" >> "$cap"; }

    run install_fzf
    [ "$status" -eq 0 ]
    local calls
    calls=$(cat "$cap")
    [[ "$calls" == *"git clone"* ]]
    [[ "$calls" != *"apt-get"* ]]
    [[ "$calls" != *"brew"* ]]
}
