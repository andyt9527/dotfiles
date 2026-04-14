# =============================================================================
# Shell-agnostic utilities (sourced from shell/utils.sh)
# =============================================================================

# Get the dotfiles directory (works regardless of how this script is called)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

# Source shell-agnostic utilities
# shellcheck source=../shell/utils.sh
if [[ -f "$DOTFILES_DIR/shell/utils.sh" ]]; then
    source "$DOTFILES_DIR/shell/utils.sh"
fi

OS=${OS:-$(detect_os)}

# =============================================================================
# Cross-platform utility functions for Ubuntu and macOS
# =============================================================================

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

# Create symbolic link if source exists (skip if already correctly linked)
lnif() {
    if [ -L "$2" ] && [ "$(readlink "$2")" = "$1" ]; then
        return 0
    fi
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

# Returns 0 if command is missing (needs install), 1 if present
# Use this for fast-path pre-checks to skip already-installed tools
needs_install() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1 && return 1
    return 0
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

# =============================================================================
# Package Check Functions
# =============================================================================

# Check if a Homebrew package is installed
brew_package_installed() {
    local pkg="$1"
    if ! command_exists brew; then
        return 1
    fi
    brew list "$pkg" &>/dev/null
}

# Check if an apt package is installed
apt_package_installed() {
    local pkg="$1"
    if ! command_exists dpkg; then
        return 1
    fi
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
}

# Check if a package is installed (cross-platform)
package_installed() {
    local pkg="$1"
    local cmd_name="${2:-$pkg}"
    
    # First check if command exists
    if command_exists "$cmd_name"; then
        return 0
    fi
    
    # Then check package manager
    if [ "$OS" = "macos" ]; then
        brew_package_installed "$pkg"
    elif [ "$OS" = "linux" ]; then
        apt_package_installed "$pkg"
    else
        return 1
    fi
}

# Install a package only if not already installed
install_package_if_needed() {
    local pkg="$1"
    local cmd_name="${2:-$pkg}"
    
    if package_installed "$pkg" "$cmd_name"; then
        info "$pkg is already installed, skipping"
        return 0
    fi
    
    info "Installing $pkg..."
    install_package "$pkg"
}
