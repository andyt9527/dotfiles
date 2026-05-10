#!/usr/bin/env bash
# scripts/lib/github.sh
# GitHub release tag fetching and asset downloading

get_latest_release_tag() {
    local repo="$1"
    local tag
    tag=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
        | jq -r '.tag_name' 2>/dev/null)
    if [ -z "$tag" ] || [ "$tag" = "null" ]; then
        error "Failed to fetch latest release tag for $repo"
        return 1
    fi
    echo "$tag"
}

download_github_release() {
    local repo="$1"
    local asset_pattern="$2"
    local output_path="$3"
    local tag
    tag=$(get_latest_release_tag "$repo")
    if [ $? -ne 0 ]; then
        return 1
    fi
    local url="https://github.com/$repo/releases/download/$tag/$asset_pattern"
    info "Downloading $repo $tag: $asset_pattern"
    if ! run_cmd curl -fL -o "$output_path" "$url"; then
        error "Failed to download $asset_pattern from $repo"
        rm -f "$output_path"
        return 1
    fi
    echo "$tag"
}
