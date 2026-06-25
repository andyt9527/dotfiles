#!/usr/bin/env bats
# scripts/tests/test_cc_switch.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/github.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/tools/cc-switch.sh"
}

@test "install_cc_switch on Linux aarch64 uses arm64 in asset filename" {
    is_macos() { return 1; }
    is_linux() { return 0; }
    command_exists() { return 1; }  # cc-switch not installed
    get_arch() { echo "aarch64"; }
    get_latest_release_tag() { echo "v1.2.3"; return 0; }

    # cc-switch.sh calls `command -v cc-switch` directly (not command_exists),
    # so mock `command` to make that check return 1 while delegating everything
    # else to builtin command. This makes the test hermetic on hosts where the
    # cc-switch binary is actually installed.
    command() {
        if [[ "$1" == "-v" && "$2" == "cc-switch" ]]; then
            return 1
        fi
        builtin command "$@"
    }

    # Simulate Linux: pretend /Applications/CC Switch.app doesn't exist so the
    # macOS early-return guard doesn't fire when running the test on macOS.
    [() {
        if [[ "$1" == "-d" && "$2" == "/Applications/CC Switch.app" ]]; then
            return 1
        fi
        builtin [ "$@"
    }

    local cap="$BATS_TMPDIR/ccswitch_url"
    : > "$cap"
    run_cmd() {
        # Capture URL when curl is called: run_cmd curl -fL -o "$file" "$url"
        if [ "$1" = "curl" ]; then
            echo "${@: -1}" >> "$cap"
        fi
        return 0
    }

    run install_cc_switch
    [ "$status" -eq 0 ]
    # Assert the captured URL contains arm64, NOT aarch64
    local url
    url=$(cat "$cap")
    [ -n "$url" ]  # URL was captured
    [[ "$url" == *"arm64"* ]]
    [[ "$url" != *"aarch64"* ]]
}

@test "install_cc_switch on Linux x86_64 keeps x86_64 in asset filename" {
    is_macos() { return 1; }
    is_linux() { return 0; }
    command_exists() { return 1; }
    get_arch() { echo "x86_64"; }
    get_latest_release_tag() { echo "v1.2.3"; return 0; }

    # See aarch64 test for rationale on the `command` and `[` overrides.
    command() {
        if [[ "$1" == "-v" && "$2" == "cc-switch" ]]; then
            return 1
        fi
        builtin command "$@"
    }

    # Simulate Linux: pretend /Applications/CC Switch.app doesn't exist.
    [() {
        if [[ "$1" == "-d" && "$2" == "/Applications/CC Switch.app" ]]; then
            return 1
        fi
        builtin [ "$@"
    }

    local cap="$BATS_TMPDIR/ccswitch_url"
    : > "$cap"
    run_cmd() {
        if [ "$1" = "curl" ]; then
            echo "${@: -1}" >> "$cap"
        fi
        return 0
    }

    run install_cc_switch
    [ "$status" -eq 0 ]
    local url
    url=$(cat "$cap")
    [ -n "$url" ]
    [[ "$url" == *"x86_64"* ]]
    [[ "$url" != *"arm64"* ]]
}
