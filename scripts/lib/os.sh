#!/usr/bin/env bash
# scripts/lib/os.sh
# OS detection, architecture mapping, and platform assertions

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        *)          echo "unsupported" ;;
    esac
}

is_macos() {
    [ "$OS" = "macos" ]
}

is_linux() {
    [ "$OS" = "linux" ]
}

get_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *)
            # Log a warning so unknown archs are visible; default to x86_64
            # for forward-compat (callers expect a value, not an error).
            if command -v warning &>/dev/null; then
                warning "Unknown architecture: $arch, defaulting to x86_64"
            fi
            echo "x86_64"
            ;;
    esac
}

assert_supported_os() {
    if [ "$OS" != "macos" ] && [ "$OS" != "linux" ]; then
        echo "[ERROR] Unsupported OS: $OS. This script supports macOS and Linux only." >&2
        return 1
    fi
}
