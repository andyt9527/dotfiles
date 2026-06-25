#!/usr/bin/env bats
# scripts/tests/test_os.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
}

@test "is_macos returns 0 when OS=macos" {
    OS="macos"
    run is_macos
    [ "$status" -eq 0 ]
}

@test "is_macos returns 1 when OS=linux" {
    OS="linux"
    run is_macos
    [ "$status" -eq 1 ]
}

@test "is_linux returns 0 when OS=linux" {
    OS="linux"
    run is_linux
    [ "$status" -eq 0 ]
}

@test "is_linux returns 1 when OS=macos" {
    OS="macos"
    run is_linux
    [ "$status" -eq 1 ]
}

@test "get_arch returns x86_64 for x86_64" {
    uname() { echo "x86_64"; }
    run get_arch
    [ "$output" = "x86_64" ]
}

@test "get_arch returns aarch64 for arm64" {
    uname() { echo "arm64"; }
    run get_arch
    [ "$output" = "aarch64" ]
}

@test "assert_supported_os exits with error on unsupported" {
    OS="unsupported"
    run assert_supported_os
    [ "$status" -ne 0 ]
}

@test "assert_supported_os succeeds on macos" {
    OS="macos"
    run assert_supported_os
    [ "$status" -eq 0 ]
}

@test "get_arch warns on unknown architecture" {
    # Source log.sh so warning() is defined
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    uname() { echo "riscv64"; }
    # warning() in log.sh writes to stdout (no >&2), so `run` captures both
    # the warning line and the default value in $output.
    # NOTE: bats 1.13.0 only checks the LAST command's exit code, so the two
    # substring checks are joined with `&&` to ensure either failure fails
    # the test.
    run get_arch
    unset -f uname
    [ "$status" -eq 0 ]
    [[ "$output" == *"Unknown architecture"*"riscv64"* ]] && [[ "$output" == *"x86_64"* ]]
}
