#!/usr/bin/env bats
# scripts/tests/test_github.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/github.sh"
}

# --- get_latest_release_tag ---

@test "get_latest_release_tag returns tag when curl and jq succeed" {
    # Mock curl to return valid JSON
    curl() {
        echo '{"tag_name": "v1.2.3"}'
    }
    # Mock jq to extract tag_name
    jq() {
        # Read stdin and extract tag_name
        local input
        input=$(cat)
        echo "$input" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"v[^"]*"'
        # Strip surrounding quotes
    }
    # Actually, let's use a simpler mock that just echoes the tag
    # The function pipes curl output into jq -r '.tag_name'
    # So jq receives the curl output on stdin and should output the tag
    _real_jq() { command jq -r '.tag_name'; }

    # Override both curl and jq properly
    curl() { echo '{"tag_name":"v1.2.3"}'; }
    jq() {
        # jq is called as: jq -r '.tag_name'
        # It reads stdin from the pipe
        sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
    }

    run get_latest_release_tag "owner/repo"
    [ "$status" -eq 0 ]
    [ "$output" = "v1.2.3" ]
}

@test "get_latest_release_tag returns 1 when curl fails" {
    # Mock curl to fail (produce no output)
    curl() { return 1; }
    jq() { echo "null"; }

    run get_latest_release_tag "owner/repo"
    [ "$status" -eq 1 ]
}

@test "get_latest_release_tag returns 1 when tag is null" {
    curl() { echo '{"tag_name": null}'; }
    jq() { echo "null"; }

    run get_latest_release_tag "owner/repo"
    [ "$status" -eq 1 ]
}

@test "get_latest_release_tag returns 1 when tag is empty" {
    curl() { echo '{"tag_name": ""}'; }
    jq() { echo ""; }

    run get_latest_release_tag "owner/repo"
    [ "$status" -eq 1 ]
}

# --- download_github_release ---

@test "download_github_release returns tag on success" {
    # Mock get_latest_release_tag
    get_latest_release_tag() { echo "v2.0.0"; return 0; }
    # Mock run_cmd to succeed
    run_cmd() { return 0; }

    local output_file
    output_file="$(mktemp)"

    run download_github_release "owner/repo" "asset.tar.gz" "$output_file"
    [ "$status" -eq 0 ]
    # info() also outputs to stdout, so tag is the last line
    [ "${lines[${#lines[@]}-1]}" = "v2.0.0" ]

    rm -f "$output_file"
}

@test "download_github_release returns 1 when tag fetch fails" {
    get_latest_release_tag() { return 1; }

    local output_file
    output_file="$(mktemp)"

    run download_github_release "owner/repo" "asset.tar.gz" "$output_file"
    [ "$status" -eq 1 ]

    rm -f "$output_file"
}

@test "download_github_release returns 1 when download fails" {
    get_latest_release_tag() { echo "v1.0.0"; return 0; }
    # Mock run_cmd to fail
    run_cmd() { return 1; }

    local output_file
    output_file="$(mktemp)"

    run download_github_release "owner/repo" "asset.tar.gz" "$output_file"
    [ "$status" -eq 1 ]

    rm -f "$output_file"
}
