#!/usr/bin/env sh
# =============================================================================
# Shell utility functions (for interactive shell use)
#
# This file is self-contained re: OS detection — it loads early in zsh startup
# before scripts/lib/os.sh is available. Re-implements detect_os locally rather
# than sourcing the lib to avoid a load-order dependency.
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
