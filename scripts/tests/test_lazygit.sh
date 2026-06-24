#!/usr/bin/env bats
# scripts/tests/test_lazygit.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/github.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/tools/lazygit.sh"
}

@test "install_lazygit on Linux x86_64 constructs correct asset filename" {
    is_macos() { return 1; }
    is_linux() { return 0; }
    needs_install() { return 0; }
    get_arch() { echo "x86_64"; }
    get_latest_release_tag() { echo "v0.44.1"; return 0; }

    local cap="$BATS_TMPDIR/lazygit_asset"
    : > "$cap"
    download_github_release() { echo "$2" > "$cap"; echo "v0.44.1"; return 0; }
    run_cmd() { return 0; }

    run install_lazygit
    [ "$status" -eq 0 ]
    [ "$(cat "$cap")" = "lazygit_0.44.1_Linux_x86_64.tar.gz" ]
}

@test "install_lazygit on Linux aarch64 constructs correct asset filename" {
    is_macos() { return 1; }
    is_linux() { return 0; }
    needs_install() { return 0; }
    get_arch() { echo "aarch64"; }
    get_latest_release_tag() { echo "v0.44.1"; return 0; }

    local cap="$BATS_TMPDIR/lazygit_asset"
    : > "$cap"
    download_github_release() { echo "$2" > "$cap"; echo "v0.44.1"; return 0; }
    run_cmd() { return 0; }

    run install_lazygit
    [ "$status" -eq 0 ]
    [ "$(cat "$cap")" = "lazygit_0.44.1_Linux_aarch64.tar.gz" ]
}

@test "install_lazygit on macOS calls brew, not download_github_release" {
    is_macos() { return 0; }
    is_linux() { return 1; }
    needs_install() { return 0; }

    local brew_cap="$BATS_TMPDIR/lazygit_brew"
    local dl_cap="$BATS_TMPDIR/lazygit_dl"
    : > "$brew_cap"
    : > "$dl_cap"
    run_cmd() {
        if [ "$1" = "brew" ] && [ "$2" = "install" ] && [ "$3" = "lazygit" ]; then
            echo 1 >> "$brew_cap"
        fi
        return 0
    }
    download_github_release() { echo 1 >> "$dl_cap"; return 0; }

    run install_lazygit
    [ "$status" -eq 0 ]
    [ "$(cat "$brew_cap")" = "1" ]
    [ "$(cat "$dl_cap")" = "" ]
}
