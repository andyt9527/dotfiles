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
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *)            echo "x86_64" ;;
    esac
}

assert_supported_os() {
    if [ "$OS" != "macos" ] && [ "$OS" != "linux" ]; then
        echo "[ERROR] Unsupported OS: $OS. This script supports macOS and Linux only." >&2
        return 1
    fi
}
