#!/usr/bin/env bats
# scripts/tests/test_package.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/package.sh"
}

# --- brew_package_installed ---

@test "brew_package_installed returns 1 when brew is missing" {
    # Override command_exists to say brew is missing
    command_exists() { [ "$1" != "brew" ]; }
    run brew_package_installed "git"
    [ "$status" -eq 1 ]
}

@test "brew_package_installed returns 0 when brew list succeeds" {
    # Override command_exists to say brew exists
    command_exists() { [ "$1" = "brew" ]; }
    # Override brew to simulate "brew list git" succeeding
    brew() { return 0; }
    run brew_package_installed "git"
    [ "$status" -eq 0 ]
}

@test "brew_package_installed returns 1 when brew list fails" {
    command_exists() { [ "$1" = "brew" ]; }
    # Override brew to simulate "brew list nonexistent" failing
    brew() { return 1; }
    run brew_package_installed "nonexistent_pkg_xyz"
    [ "$status" -eq 1 ]
}

# --- apt_package_installed ---

@test "apt_package_installed returns 1 when dpkg is missing" {
    command_exists() { [ "$1" != "dpkg" ]; }
    run apt_package_installed "git"
    [ "$status" -eq 1 ]
}

@test "apt_package_installed returns 0 when dpkg shows package installed" {
    command_exists() { [ "$1" = "dpkg" ]; }
    # Override dpkg to simulate installed package
    dpkg() { echo "ii  git  1:2.34.1-1  amd64  fast, scalable, distributed revision control system"; }
    run apt_package_installed "git"
    [ "$status" -eq 0 ]
}

@test "apt_package_installed returns 1 when dpkg shows package not installed" {
    command_exists() { [ "$1" = "dpkg" ]; }
    # Override dpkg to simulate uninstalled package (no output)
    dpkg() { return 1; }
    run apt_package_installed "nonexistent_pkg_xyz"
    [ "$status" -eq 1 ]
}

# --- package_installed ---

@test "package_installed returns 0 when command_exists succeeds" {
    # Override command_exists: the specified command exists
    command_exists() { [ "$1" = "git" ]; }
    OS="linux"
    run package_installed "git" "git"
    [ "$status" -eq 0 ]
}

@test "package_installed falls back to brew on macOS" {
    # command_exists returns false for the cmd, but brew says it's installed
    command_exists() { return 1; }
    OS="macos"
    # Override brew_package_installed to succeed
    brew_package_installed() { return 0; }
    run package_installed "git" "git"
    [ "$status" -eq 0 ]
}

@test "package_installed falls back to apt on Linux" {
    command_exists() { return 1; }
    OS="linux"
    # Override apt_package_installed to succeed
    apt_package_installed() { return 0; }
    run package_installed "git" "git"
    [ "$status" -eq 0 ]
}

@test "package_installed returns 1 when nothing found" {
    command_exists() { return 1; }
    OS="linux"
    apt_package_installed() { return 1; }
    run package_installed "nonexistent_pkg_xyz"
    [ "$status" -eq 1 ]
}

@test "package_installed returns 1 on unsupported OS" {
    command_exists() { return 1; }
    OS="unsupported"
    run package_installed "git"
    [ "$status" -eq 1 ]
}
