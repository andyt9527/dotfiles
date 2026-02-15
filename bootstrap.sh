#!/usr/bin/env bash
# =============================================================================
# Bootstrap Script
# One-liner to download and install dotfiles
# Usage: curl -fsSL https://raw.githubusercontent.com/USER/REPO/main/bootstrap.sh | bash
# =============================================================================

set -e

DOTFILES_REPO="https://github.com/andyt9527/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Dotfiles Bootstrap Installer                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
if ! command -v git &> /dev/null; then
    echo "Git is required but not installed. Please install Git first."
    exit 1
fi

# Clone or update repository
if [ -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles directory already exists. Updating..."
    cd "$DOTFILES_DIR"
    git pull
    echo "Updating submodules..."
    git submodule update --init --recursive
else
    echo "Cloning dotfiles repository..."
    git clone --recursive "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# Run installer
echo ""
echo "Running installer..."
echo ""
cd "$DOTFILES_DIR"
./install.sh "$@"
