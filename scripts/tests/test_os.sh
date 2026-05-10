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
