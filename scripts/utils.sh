#!/usr/bin/env bash
# =============================================================================
# Cross-platform utility functions for Ubuntu and macOS
# =============================================================================

# Detect OS type
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*)    echo "cygwin";;
        MINGW*)     echo "mingw";;
        *)          echo "unknown";;
    esac
}

OS=$(detect_os)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

# Create symbolic link if source exists
lnif() {
    if [ -e "$1" ]; then
        ln -sf "$1" "$2"
        return 0
    fi
    return 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install package based on OS
install_package() {
    local pkg="$1"
    if [ "$OS" = "macos" ]; then
        if command_exists brew; then
            brew install "$pkg"
        else
            error "Homebrew not installed. Please install Homebrew first."
            return 1
        fi
    elif [ "$OS" = "linux" ]; then
        if command_exists apt-get; then
            sudo apt-get install -y "$pkg"
        elif command_exists yum; then
            sudo yum install -y "$pkg"
        elif command_exists pacman; then
            sudo pacman -S --noconfirm "$pkg"
        else
            error "No supported package manager found"
            return 1
        fi
    fi
}

# Get script directory
get_script_dir() {
    cd "$(dirname "$0")" && pwd
}
