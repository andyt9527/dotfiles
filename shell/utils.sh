#!/usr/bin/env sh
# =============================================================================
# Shell utility functions (for interactive shell use)
# =============================================================================

# Detect OS type
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        *)          echo "unknown" ;;
    esac
}

# Check if command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}
