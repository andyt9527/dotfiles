#!/usr/bin/env sh
# =============================================================================
# Shell-agnostic utility functions for bash and zsh
# This file can be sourced by both bash and zsh scripts
# =============================================================================

# Detect OS type (compatible with both bash and zsh)
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "cygwin";;
        MINGW*)     echo "mingw";;
        *)          echo "unknown";;
    esac
}

# Check if command exists (returns 0 if command is available)
check_command() {
    command -v "$1" >/dev/null 2>&1
}
