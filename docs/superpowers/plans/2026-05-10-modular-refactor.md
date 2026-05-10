# Dotfiles Modular Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure dotfiles install scripts into a tool-registry architecture with a shared platform abstraction layer, declarative config manifest, and bats testing framework.

**Architecture:** Each tool gets its own file in `scripts/tools/`. A shared `scripts/lib/` provides OS detection, package management, logging, symlink, GitHub release download, and command-check functions. A `scripts/configs/manifest.sh` is the single source of truth for config file mappings, shared by install and uninstall. All side-effect operations go through `run_cmd` for dry-run support.

**Tech Stack:** Bash, bats-core (testing), curl (GitHub API), brew/apt-get (package management)

**Spec:** `docs/superpowers/specs/2026-05-10-modular-refactor-design.md`

---

## File Map

### New files to create

| File | Responsibility |
|------|---------------|
| `scripts/lib/os.sh` | OS detection, arch mapping, platform assertions |
| `scripts/lib/log.sh` | Colored logging + `run_cmd` dry-run wrapper |
| `scripts/lib/assert.sh` | `needs_install`, `command_exists` |
| `scripts/lib/package.sh` | Cross-platform package install + batch install |
| `scripts/lib/symlink.sh` | `link_config`, `backup_file`, `lnif` |
| `scripts/lib/github.sh` | GitHub release tag fetch + asset download |
| `scripts/configs/manifest.sh` | Declarative symlink config array |
| `scripts/tools/_template.sh` | Template for new tools |
| `scripts/tools/fd.sh` | fd/fdfind install |
| `scripts/tools/bat.sh` | bat/batcat install |
| `scripts/tools/eza.sh` | eza install (brew / cargo) |
| `scripts/tools/zoxide.sh` | zoxide install (brew / script) |
| `scripts/tools/fzf.sh` | fzf install (brew / git clone) |
| `scripts/tools/ripgrep.sh` | ripgrep install (brew / apt) |
| `scripts/tools/duf.sh` | duf install (brew / cargo) |
| `scripts/tools/dust.sh` | dust install (brew / cargo) |
| `scripts/tools/procs.sh` | procs install (brew / cargo) |
| `scripts/tools/bottom.sh` | bottom install (brew / cargo) |
| `scripts/tools/lazygit.sh` | lazygit install (brew / GitHub release) |
| `scripts/tools/lazydocker.sh` | lazydocker install (brew / script) |
| `scripts/tools/claude-code.sh` | Claude Code CLI (npm) |
| `scripts/tools/codex.sh` | Codex CLI (npm) |
| `scripts/tools/cc-switch.sh` | cc-switch (brew cask / deb) |
| `scripts/tools/tmux.sh` | tmux + TPM install |
| `scripts/tools/vim.sh` | space-vim submodule + vim-plug |
| `scripts/tools/shell.sh` | Oh My Zsh + Powerlevel10k + chsh |
| `scripts/tests/helpers/test_helper.bash` | Common bats setup |
| `scripts/tests/test_os.sh` | Tests for lib/os.sh |
| `scripts/tests/test_log.sh` | Tests for lib/log.sh |
| `scripts/tests/test_assert.sh` | Tests for lib/assert.sh |
| `scripts/tests/test_package.sh` | Tests for lib/package.sh |
| `scripts/tests/test_symlink.sh` | Tests for lib/symlink.sh |
| `scripts/tests/test_github.sh` | Tests for lib/github.sh |
| `scripts/tests/test_manifest.sh` | Tests for configs/manifest.sh |
| `scripts/tests/test_install_cli.sh` | Tests for install.sh arg parsing |
| `scripts/tests/run_tests.sh` | Test runner script |

### Files to rewrite

| File | Change |
|------|--------|
| `install.sh` | New CLI (--tools, --skip-tools, --dry-run, --list-tools), new phases |
| `uninstall.sh` | Use manifest.sh + lib/ functions |
| `scripts/update.sh` | Use lib/ functions |

### Files to delete after migration

| File | Reason |
|------|--------|
| `scripts/install/01-prerequisites.sh` | Replaced by install.sh Phase 1 |
| `scripts/install/02-packages.sh` | Replaced by install.sh Phase 1 + tools/ |
| `scripts/install/03-modern-tools.sh` | Replaced by individual tools/ files |
| `scripts/install/04-shell.sh` | Replaced by tools/shell.sh |
| `scripts/install/05-tmux.sh` | Replaced by tools/tmux.sh |
| `scripts/install/06-vim.sh` | Replaced by tools/vim.sh |
| `scripts/install/07-tools.sh` | Replaced by individual tools/ files |
| `scripts/install/08-configs.sh` | Replaced by manifest.sh + lib/symlink.sh |
| `scripts/utils.sh` | Replaced by lib/ modules |
| `shell/utils.sh` | Kept as thin wrapper for interactive shell use |

---

### Task 1: Set up bats-core testing framework

**Files:**
- Create: `scripts/tests/helpers/test_helper.bash`
- Create: `scripts/tests/run_tests.sh`

- [ ] **Step 1: Install bats-core as a git submodule**

```bash
cd /Users/andy/dotfiles
git submodule add https://github.com/bats-core/bats-core.git test/bats
git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support
git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert
```

- [ ] **Step 2: Create test helper**

```bash
# scripts/tests/helpers/test_helper.bash
# Source this in every test file via: load helpers/test_helper

# Resolve the directory of this file (works in bats)
PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

# Load bats-support and bats-assert
load "$PROJECT_DIR/../../test/test_helper/bats-support/load"
load "$PROJECT_DIR/../../test/test_helper/bats-assert/load"

# Export project directory for tests
export DOTFILES_TEST_PROJECT_DIR="$PROJECT_DIR"
```

- [ ] **Step 3: Create test runner**

```bash
#!/usr/bin/env bash
# scripts/tests/run_tests.sh
set -e

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
BATS_BIN="$(cd "$(dirname "$0")/../../test/bats/bin" && pwd)"

echo "Running bats tests..."
"$TEST_DIR/../../test/bats/bin/bats" "$TEST_DIR" "$@"
```

- [ ] **Step 4: Verify bats runs**

```bash
chmod +x scripts/tests/run_tests.sh
./scripts/tests/run_tests.sh
```

Expected: bats runs with 0 tests (no test files yet), or shows "No test files found" — either is fine.

- [ ] **Step 5: Commit**

```bash
git add test/ scripts/tests/helpers/test_helper.bash scripts/tests/run_tests.sh
git commit -m "chore: add bats-core testing framework"
```

---

### Task 2: lib/os.sh — OS detection and architecture

**Files:**
- Create: `scripts/lib/os.sh`
- Create: `scripts/tests/test_os.sh`

- [ ] **Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# scripts/tests/test_os.sh

setup() {
    load helpers/test_helper
    # Source the module under test
    source "$DOTFILES_TEST_PROJECT_DIR/lib/os.sh"
}

@test "detect_os returns linux for Linux uname" {
    mock_uname() { echo "Linux"; }
    # Override uname in this shell
    uname() { mock_uname; }
    run detect_os
    [ "$output" = "linux" ]
}

@test "detect_os returns macos for Darwin uname" {
    mock_uname() { echo "Darwin"; }
    uname() { mock_uname; }
    run detect_os
    [ "$output" = "macos" ]
}

@test "detect_os returns unsupported for unknown" {
    mock_uname() { echo "FreeBSD"; }
    uname() { mock_uname; }
    run detect_os
    [ "$output" = "unsupported" ]
}

@test "is_macos returns 0 when OS=macos" {
    OS="macos"
    run is_macos
    [ "$status" -eq 0 ]
}

@test "is_macos returns 1 when OS=linux" {
    OS="linux"
    run is_macos
    [ "$status" -eq 1 ]
}

@test "is_linux returns 0 when OS=linux" {
    OS="linux"
    run is_linux
    [ "$status" -eq 0 ]
}

@test "is_linux returns 1 when OS=macos" {
    OS="macos"
    run is_linux
    [ "$status" -eq 1 ]
}

@test "get_arch returns x86_64 for x86_64" {
    _uname_m() { echo "x86_64"; }
    uname() { echo "x86_64"; }
    run get_arch
    [ "$output" = "x86_64" ]
}

@test "get_arch returns aarch64 for arm64" {
    uname() { echo "arm64"; }
    run get_arch
    [ "$output" = "aarch64" ]
}

@test "get_arch returns aarch64 for aarch64" {
    uname() { echo "aarch64"; }
    run get_arch
    [ "$output" = "aarch64" ]
}

@test "assert_supported_os exits with error on unsupported" {
    OS="unsupported"
    run assert_supported_os
    [ "$status" -ne 0 ]
}

@test "assert_supported_os succeeds on macos" {
    OS="macos"
    run assert_supported_os
    [ "$status" -eq 0 ]
}

@test "assert_supported_os succeeds on linux" {
    OS="linux"
    run assert_supported_os
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_os.sh
```

Expected: FAIL — `scripts/lib/os.sh` does not exist.

- [ ] **Step 3: Write implementation**

```bash
#!/usr/bin/env bash
# scripts/lib/os.sh
# OS detection, architecture mapping, and platform assertions

# Detect OS type
# Returns: "macos" | "linux" | "unsupported"
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        *)          echo "unsupported" ;;
    esac
}

# Shorthand: is this macOS?
is_macos() {
    [ "$OS" = "macos" ]
}

# Shorthand: is this Linux?
is_linux() {
    [ "$OS" = "linux" ]
}

# Get normalized architecture
# Maps uname -m to: "x86_64" | "aarch64"
get_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *)            echo "x86_64" ;;
    esac
}

# Assert current OS is supported; exit with error if not
assert_supported_os() {
    if [ "$OS" != "macos" ] && [ "$OS" != "linux" ]; then
        echo "[ERROR] Unsupported OS: $OS. This script supports macOS and Linux only." >&2
        return 1
    fi
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_os.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/os.sh scripts/tests/test_os.sh
git commit -m "feat: add lib/os.sh — OS detection and architecture mapping"
```

---

### Task 3: lib/log.sh — Logging and dry-run

**Files:**
- Create: `scripts/lib/log.sh`
- Create: `scripts/tests/test_log.sh`

- [ ] **Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# scripts/tests/test_log.sh

setup() {
    load helpers/test_helper
    DRY_RUN=0
    source "$DOTFILES_TEST_PROJECT_DIR/lib/log.sh"
}

@test "info prints [INFO] prefix with blue color" {
    run info "test message"
    [ "$output" = "$(printf '\033[0;34m[INFO]\033[0m test message')" ]
}

@test "success prints [OK] prefix with green color" {
    run success "done"
    [ "$output" = "$(printf '\033[0;32m[OK]\033[0m done')" ]
}

@test "warning prints [WARN] prefix with yellow color" {
    run warning "careful"
    [ "$output" = "$(printf '\033[1;33m[WARN]\033[0m careful')" ]
}

@test "error prints [ERROR] prefix with red color to stderr" {
    run error "broke"
    [ "$output" = "$(printf '\033[0;31m[ERROR]\033[0m broke')" ]
}

@test "run_cmd executes command when DRY_RUN=0" {
    run run_cmd echo "hello"
    [ "$output" = "hello" ]
    [ "$status" -eq 0 ]
}

@test "run_cmd prints [DRY-RUN] and does not execute when DRY_RUN=1" {
    DRY_RUN=1
    run run_cmd echo "hello"
    [[ "$output" == *"[DRY-RUN]"* ]]
    [[ "$output" != *"hello"* ]]
}

@test "run_cmd returns 0 in dry-run mode" {
    DRY_RUN=1
    run run_cmd false
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_log.sh
```

Expected: FAIL — `scripts/lib/log.sh` does not exist.

- [ ] **Step 3: Write implementation**

```bash
#!/usr/bin/env bash
# scripts/lib/log.sh
# Colored logging and dry-run command wrapper

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Execute a command, or print it in dry-run mode
# Usage: run_cmd <command> [args...]
run_cmd() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        info "[DRY-RUN] $*"
        return 0
    fi
    "$@"
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_log.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/log.sh scripts/tests/test_log.sh
git commit -m "feat: add lib/log.sh — colored logging and dry-run wrapper"
```

---

### Task 4: lib/assert.sh — Command existence checks

**Files:**
- Create: `scripts/lib/assert.sh`
- Create: `scripts/tests/test_assert.sh`

- [ ] **Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# scripts/tests/test_assert.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/lib/assert.sh"
}

@test "command_exists returns 0 for existing command" {
    run command_exists bash
    [ "$status" -eq 0 ]
}

@test "command_exists returns 1 for missing command" {
    run command_exists nonexistent_command_xyz_12345
    [ "$status" -eq 1 ]
}

@test "needs_install returns 0 for missing command" {
    run needs_install nonexistent_command_xyz_12345
    [ "$status" -eq 0 ]
}

@test "needs_install returns 1 for existing command" {
    run needs_install bash
    [ "$status" -eq 1 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_assert.sh
```

Expected: FAIL — `scripts/lib/assert.sh` does not exist.

- [ ] **Step 3: Write implementation**

```bash
#!/usr/bin/env bash
# scripts/lib/assert.sh
# Command existence checks

# Check if a command exists
# Returns: 0 if exists, 1 if not
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a command needs to be installed
# Returns: 0 if missing (needs install), 1 if present
needs_install() {
    command -v "$1" >/dev/null 2>&1 && return 1
    return 0
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_assert.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/assert.sh scripts/tests/test_assert.sh
git commit -m "feat: add lib/assert.sh — command existence checks"
```

---

### Task 5: lib/package.sh — Cross-platform package management

**Files:**
- Create: `scripts/lib/package.sh`
- Create: `scripts/tests/test_package.sh`

- [ ] **Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# scripts/tests/test_package.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/lib/package.sh"
    DRY_RUN=0
}

# --- brew_package_installed ---

@test "brew_package_installed returns 1 when brew not available" {
    brew() { return 1; }
    run brew_package_installed somepkg
    [ "$status" -eq 1 ]
}

@test "brew_package_installed returns 0 when brew list succeeds" {
    brew() { return 0; }
    run brew_package_installed git
    [ "$status" -eq 0 ]
}

# --- apt_package_installed ---

@test "apt_package_installed returns 1 when dpkg not available" {
    dpkg() { return 1; }
    run apt_package_installed somepkg
    [ "$status" -eq 1 ]
}

@test "apt_package_installed returns 0 when dpkg shows installed" {
    dpkg() {
        [ "$1" = "-l" ] && echo "ii  git  1:2.0  amd64  fast, scalable, distributed revision control system"
        return 0
    }
    grep() { return 0; }
    run apt_package_installed git
    [ "$status" -eq 0 ]
}

# --- package_installed ---

@test "package_installed returns 0 when command exists" {
    command_exists() { return 0; }
    run package_installed git
    [ "$status" -eq 0 ]
}

@test "package_installed falls back to brew on macos" {
    OS="macos"
    command_exists() { return 1; }
    brew_package_installed() { return 0; }
    run package_installed git
    [ "$status" -eq 0 ]
}

@test "package_installed falls back to apt on linux" {
    OS="linux"
    command_exists() { return 1; }
    apt_package_installed() { return 0; }
    run package_installed git
    [ "$status" -eq 0 ]
}

# --- install_package ---

@test "install_package calls brew on macos" {
    OS="macos"
    command_exists() { return 0; }
    local called=""
    brew() { called="$*"; }
    install_package git
    [ "$called" = "install git" ]
}

@test "install_package calls apt-get on linux" {
    OS="linux"
    command_exists() { return 0; }
    local called=""
    sudo() { called="$*"; }
    install_package git
    [[ "$called" == *"apt-get install"*"git"* ]]
}

# --- install_packages_batch ---

@test "install_packages_batch skips already-installed packages" {
    OS="macos"
    local installed=()
    brew_package_installed() { return 0; }
    brew() { installed+=("$*"); }
    run install_packages_batch git curl
    [ "${#installed[@]}" -eq 0 ]
}

@test "install_packages_batch installs missing packages" {
    OS="macos"
    local installed=()
    command_exists() { return 1; }
    brew_package_installed() { return 1; }
    command() { return 1; }
    brew() { installed+=("$2"); return 0; }
    DRY_RUN=0
    install_packages_batch git curl
    [ "${installed[0]}" = "git" ]
    [ "${installed[1]}" = "curl" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_package.sh
```

Expected: FAIL — `scripts/lib/package.sh` does not exist.

- [ ] **Step 3: Write implementation**

```bash
#!/usr/bin/env bash
# scripts/lib/package.sh
# Cross-platform package management

# Source dependencies
if [ -z "$DOTFILES_LIB_LOADED" ]; then
    return 0  # Functions defined but deps loaded by caller
fi

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

    if command_exists "$cmd_name"; then
        return 0
    fi

    if is_macos; then
        brew_package_installed "$pkg"
    elif is_linux; then
        apt_package_installed "$pkg"
    else
        return 1
    fi
}

# Install a single package via the appropriate package manager
install_package() {
    local pkg="$1"
    if is_macos; then
        if command_exists brew; then
            run_cmd brew install "$pkg"
        else
            error "Homebrew not installed. Please install Homebrew first."
            return 1
        fi
    elif is_linux; then
        if command_exists apt-get; then
            run_cmd sudo apt-get install -y "$pkg"
        elif command_exists yum; then
            run_cmd sudo yum install -y "$pkg"
        elif command_exists pacman; then
            run_cmd sudo pacman -S --noconfirm "$pkg"
        else
            error "No supported package manager found"
            return 1
        fi
    fi
}

# Install multiple packages, skipping already-installed ones
# Usage: install_packages_batch pkg1 pkg2 pkg3...
install_packages_batch() {
    local pkgs=("$@")

    if is_macos; then
        for pkg in "${pkgs[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
                continue
            fi
            info "Installing $pkg..."
            run_cmd brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
        done
    elif is_linux; then
        # Check if any package needs installing (to batch apt-get update)
        local needs_update=false
        for pkg in "${pkgs[@]}"; do
            if ! apt_package_installed "$pkg"; then
                needs_update=true
                break
            fi
        done

        if [ "$needs_update" = true ]; then
            run_cmd sudo apt-get update
            for pkg in "${pkgs[@]}"; do
                if apt_package_installed "$pkg"; then
                    info "$pkg is already installed, skipping"
                    continue
                fi
                info "Installing $pkg..."
                run_cmd sudo apt-get install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
            done
        else
            info "All packages already installed"
        fi
    fi
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_package.sh
```

Expected: All tests PASS. Some mock-related tests may need adjustment — fix as needed.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/package.sh scripts/tests/test_package.sh
git commit -m "feat: add lib/package.sh — cross-platform package management"
```

---

### Task 6: lib/symlink.sh — Config file linking

**Files:**
- Create: `scripts/lib/symlink.sh`
- Create: `scripts/tests/test_symlink.sh`

- [ ] **Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# scripts/tests/test_symlink.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/lib/symlink.sh"
    DRY_RUN=0

    # Create temp dirs for testing
    TEST_SRC="$(mktemp -d)"
    TEST_DST_DIR="$(mktemp -d)"
    BACKUP_DIR="$(mktemp -d)"
    DOTFILES_DIR="$TEST_SRC"
}

teardown() {
    rm -rf "$TEST_SRC" "$TEST_DST_DIR" "$BACKUP_DIR"
}

@test "lnif creates symlink when source exists" {
    echo "content" > "$TEST_SRC/testfile"
    local target="$TEST_DST_DIR/link"
    run lnif "$TEST_SRC/testfile" "$target"
    [ "$status" -eq 0 ]
    [ -L "$target" ]
}

@test "lnif skips when already correctly linked" {
    echo "content" > "$TEST_SRC/testfile"
    ln -sf "$TEST_SRC/testfile" "$TEST_DST_DIR/link"
    run lnif "$TEST_SRC/testfile" "$TEST_DST_DIR/link"
    [ "$status" -eq 0 ]
}

@test "lnif returns 1 when source does not exist" {
    run lnif "$TEST_SRC/nonexistent" "$TEST_DST_DIR/link"
    [ "$status" -eq 1 ]
}

@test "backup_file moves existing regular file to BACKUP_DIR" {
    echo "old" > "$TEST_DST_DIR/oldfile"
    run backup_file "$TEST_DST_DIR/oldfile"
    [ "$status" -eq 0 ]
    [ -f "$BACKUP_DIR/oldfile" ]
    [ ! -f "$TEST_DST_DIR/oldfile" ]
}

@test "backup_file skips symlinks" {
    echo "target" > "$TEST_SRC/target"
    ln -sf "$TEST_SRC/target" "$TEST_DST_DIR/link"
    run backup_file "$TEST_DST_DIR/link"
    [ "$status" -eq 0 ]
    [ -L "$TEST_DST_DIR/link" ]
}

@test "backup_file skips non-existent files" {
    run backup_file "$TEST_DST_DIR/nonexistent"
    [ "$status" -eq 0 ]
}

@test "link_config backs up and symlinks a config file" {
    mkdir -p "$TEST_SRC/shell"
    echo "config" > "$TEST_SRC/shell/zshrc"
    local target="$TEST_DST_DIR/.zshrc"
    run link_config "shell/zshrc" "$target"
    [ "$status" -eq 0 ]
    [ -L "$target" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_symlink.sh
```

Expected: FAIL.

- [ ] **Step 3: Write implementation**

```bash
#!/usr/bin/env bash
# scripts/lib/symlink.sh
# Config file symlinking and backup

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

# Back up an existing file (move to BACKUP_DIR)
# Skips symlinks and non-existent files
backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        info "Backing up $file"
        mv "$file" "$BACKUP_DIR/"
    fi
}

# Link a config file from dotfiles to target
# Handles backup + symlink
# Usage: link_config <source_relative_to_DOTFILES_DIR> <target_absolute_path>
link_config() {
    local src="$DOTFILES_DIR/$1"
    local target="$2"

    # Ensure parent directory exists
    mkdir -p "$(dirname "$target")"

    backup_file "$target"
    lnif "$src" "$target"
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_symlink.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/symlink.sh scripts/tests/test_symlink.sh
git commit -m "feat: add lib/symlink.sh — config file linking and backup"
```

---

### Task 7: lib/github.sh — GitHub release downloads

**Files:**
- Create: `scripts/lib/github.sh`
- Create: `scripts/tests/test_github.sh`

- [ ] **Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# scripts/tests/test_github.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/lib/github.sh"
    DRY_RUN=0
}

@test "get_latest_release_tag returns tag from GitHub API" {
    # Mock curl to return a JSON response
    curl() {
        if [ "$1" = "-fsSL" ] && [[ "$2" == *"api.github.com/repos/test/repo/releases/latest"* ]]; then
            echo '{"tag_name": "v1.2.3"}'
        fi
    }
    jq() {
        if [ "$1" = "-r" ] && [ "$2" = ".tag_name" ]; then
            echo "v1.2.3"
        fi
    }
    run get_latest_release_tag "test/repo"
    [ "$output" = "v1.2.3" ]
}

@test "get_latest_release_tag returns 1 on failure" {
    curl() { return 1; }
    run get_latest_release_tag "test/repo"
    [ "$status" -eq 1 ]
}

@test "download_github_release downloads and extracts tar.gz" {
    # Mock: create a fake tar.gz in /tmp
    curl() {
        # $3 is output file, $2 is URL
        echo "fake tar data" > "$3"
        return 0
    }
    tar() { return 0; }
    rm() { return 0; }

    run download_github_release "test/repo" "asset_x86_64.tar.gz" "/tmp/test_output.tar.gz"
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_github.sh
```

Expected: FAIL.

- [ ] **Step 3: Write implementation**

```bash
#!/usr/bin/env bash
# scripts/lib/github.sh
# GitHub release tag fetching and asset downloading

# Get the latest release tag for a GitHub repo
# Usage: get_latest_release_tag "owner/repo"
# Returns: tag string (e.g. "v1.2.3")
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

# Download a specific asset from the latest GitHub release
# Usage: download_github_release "owner/repo" "asset_pattern" "output_path"
# The asset_pattern is matched against release asset names using glob
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_github.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/github.sh scripts/tests/test_github.sh
git commit -m "feat: add lib/github.sh — GitHub release downloads"
```

---

### Task 8: configs/manifest.sh — Declarative config mapping

**Files:**
- Create: `scripts/configs/manifest.sh`
- Create: `scripts/tests/test_manifest.sh`

- [ ] **Step 1: Write the failing tests**

```bash
#!/usr/bin/env bats
# scripts/tests/test_manifest.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/configs/manifest.sh"
}

@test "CONFIGS array is not empty" {
    [ "${#CONFIGS[@]}" -gt 0 ]
}

@test "each CONFIGS entry has 3 pipe-delimited fields" {
    for entry in "${CONFIGS[@]}"; do
        local field_count
        field_count=$(echo "$entry" | awk -F'|' '{print NF}')
        [ "$field_count" -ge 3 ]
    done
}

@test "manifest contains .zshrc entry" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"shell/zshrc"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}

@test "manifest contains .tmux.conf entry" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"tmux/tmux.conf"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}

@test "manifest has macos-specific lazygit config" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"lazygit"*"macos"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}

@test "manifest has linux-specific lazygit config" {
    local found=false
    for entry in "${CONFIGS[@]}"; do
        if [[ "$entry" == *"lazygit"*"linux"* ]]; then
            found=true
            break
        fi
    done
    [ "$found" = "true" ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_manifest.sh
```

Expected: FAIL.

- [ ] **Step 3: Write implementation**

```bash
#!/usr/bin/env bash
# scripts/configs/manifest.sh
# Declarative config file mapping — single source of truth
# Shared by install.sh and uninstall.sh
#
# Format: "source_relative|target_path|platform[:flags]"
#   source_relative: path relative to DOTFILES_DIR
#   target_path: absolute path (supports ~ expansion)
#   platform: "all" | "macos" | "linux"
#   flags: "skip_existing" — only link if target doesn't exist

CONFIGS=(
    "shell/bashrc|~/.bashrc|all"
    "shell/zshrc|~/.zshrc|all"
    "shell/zshrc.local|~/.zshrc.local|all:skip_existing"
    "tmux/tmux.conf|~/.tmux.conf|all"
    "git/gitconfig|~/.gitconfig|all"
    "tig/tigrc|~/.tigrc|all"
    "tig/tigrc.theme|~/.tigrc.theme|all"
    "config/p10k.zsh|~/.p10k.zsh|all"
    "config/lazygit.yml|~/Library/Application Support/lazygit/config.yml|macos"
    "config/lazygit.yml|~/.config/lazygit/config.yml|linux"
    "config/lazydocker.yml|~/Library/Application Support/lazydocker/config.yml|macos"
    "config/lazydocker.yml|~/.config/lazydocker/config.yml|linux"
)
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
./scripts/tests/run_tests.sh scripts/tests/test_manifest.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/configs/manifest.sh scripts/tests/test_manifest.sh
git commit -m "feat: add configs/manifest.sh — declarative symlink config"
```

---

### Task 9: Tool template and brew-install tools (fd, bat, eza, ripgrep, duf, dust, procs, bottom)

**Files:**
- Create: `scripts/tools/_template.sh`
- Create: `scripts/tools/fd.sh`
- Create: `scripts/tools/bat.sh`
- Create: `scripts/tools/eza.sh`
- Create: `scripts/tools/ripgrep.sh`
- Create: `scripts/tools/duf.sh`
- Create: `scripts/tools/dust.sh`
- Create: `scripts/tools/procs.sh`
- Create: `scripts/tools/bottom.sh`

These are "brew on macOS, apt/cargo on Linux" tools that follow a common pattern.

- [ ] **Step 1: Create the tool template**

```bash
#!/usr/bin/env bash
# scripts/tools/_template.sh
# Template for creating new tool install scripts
# Copy this file and replace PLACEHOLDER with the tool name

# TOOL_NAME="PLACEHOLDER"

# install_PLACEHOLDER() {
#     if ! needs_install "$TOOL_NAME"; then
#         info "$TOOL_NAME already installed, skipping"
#         return 0
#     fi
#
#     if is_macos; then
#         run_cmd brew install "$TOOL_NAME"
#     elif is_linux; then
#         run_cmd sudo apt-get install -y "$TOOL_NAME"
#     fi
#
#     if command_exists "$TOOL_NAME"; then
#         success "$TOOL_NAME installed"
#     else
#         warning "$TOOL_NAME installation may have failed"
#     fi
# }
```

- [ ] **Step 2: Create fd.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/fd.sh
# fd — fast find alternative (fdfind on Ubuntu)

TOOL_NAME="fd"

install_fd() {
    if ! needs_install fd && ! needs_install fdfind; then
        info "fd already installed, skipping"
        return 0
    fi

    info "Installing fd..."

    if is_macos; then
        run_cmd brew install fd
    elif is_linux; then
        run_cmd sudo apt-get install -y fd-find
        # Create symlink for Ubuntu's fdfind → fd
        if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
        fi
    fi

    success "fd installed"
}
```

- [ ] **Step 3: Create bat.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/bat.sh
# bat — cat clone with syntax highlighting (batcat on Ubuntu)

TOOL_NAME="bat"

install_bat() {
    if ! needs_install bat && ! needs_install batcat; then
        info "bat already installed, skipping"
        return 0
    fi

    info "Installing bat..."

    if is_macos; then
        run_cmd brew install bat
    elif is_linux; then
        run_cmd sudo apt-get install -y bat
        # Create symlink for Ubuntu's batcat → bat
        if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        fi
    fi

    success "bat installed"
}
```

- [ ] **Step 4: Create eza.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/eza.sh
# eza — modern ls replacement (Rust-based, uses cargo on Linux)

TOOL_NAME="eza"

install_eza() {
    if ! needs_install eza; then
        info "eza already installed, skipping"
        return 0
    fi

    info "Installing eza..."

    if is_macos; then
        run_cmd brew install eza
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install eza
        else
            warning "cargo not found — skipping eza (install rustup first)"
            return 0
        fi
    fi

    success "eza installed"
}
```

- [ ] **Step 5: Create ripgrep.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/ripgrep.sh
# ripgrep — fast grep tool

TOOL_NAME="ripgrep"
TOOL_CMD="rg"

install_ripgrep() {
    if ! needs_install rg; then
        info "ripgrep already installed, skipping"
        return 0
    fi

    info "Installing ripgrep..."

    if is_macos; then
        run_cmd brew install ripgrep
    elif is_linux; then
        run_cmd sudo apt-get install -y ripgrep
    fi

    success "ripgrep installed"
}
```

- [ ] **Step 6: Create duf.sh, dust.sh, procs.sh, bottom.sh (cargo-on-Linux pattern)**

```bash
#!/usr/bin/env bash
# scripts/tools/duf.sh
TOOL_NAME="duf"

install_duf() {
    if ! needs_install duf; then
        info "duf already installed, skipping"
        return 0
    fi
    info "Installing duf..."
    if is_macos; then
        run_cmd brew install duf
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install duf
        else
            warning "cargo not found — skipping duf"
            return 0
        fi
    fi
    success "duf installed"
}
```

```bash
#!/usr/bin/env bash
# scripts/tools/dust.sh
TOOL_NAME="dust"

install_dust() {
    if ! needs_install dust; then
        info "dust already installed, skipping"
        return 0
    fi
    info "Installing dust..."
    if is_macos; then
        run_cmd brew install dust
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install du-dust
        else
            warning "cargo not found — skipping dust"
            return 0
        fi
    fi
    success "dust installed"
}
```

```bash
#!/usr/bin/env bash
# scripts/tools/procs.sh
TOOL_NAME="procs"

install_procs() {
    if ! needs_install procs; then
        info "procs already installed, skipping"
        return 0
    fi
    info "Installing procs..."
    if is_macos; then
        run_cmd brew install procs
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install procs
        else
            warning "cargo not found — skipping procs"
            return 0
        fi
    fi
    success "procs installed"
}
```

```bash
#!/usr/bin/env bash
# scripts/tools/bottom.sh
TOOL_NAME="bottom"
TOOL_CMD="btm"

install_bottom() {
    if ! needs_install btm; then
        info "bottom already installed, skipping"
        return 0
    fi
    info "Installing bottom..."
    if is_macos; then
        run_cmd brew install bottom
    elif is_linux; then
        if command_exists cargo; then
            run_cmd cargo install bottom
        else
            warning "cargo not found — skipping bottom"
            return 0
        fi
    fi
    success "bottom installed"
}
```

- [ ] **Step 7: Commit**

```bash
git add scripts/tools/_template.sh scripts/tools/fd.sh scripts/tools/bat.sh \
    scripts/tools/eza.sh scripts/tools/ripgrep.sh scripts/tools/duf.sh \
    scripts/tools/dust.sh scripts/tools/procs.sh scripts/tools/bottom.sh
git commit -m "feat: add brew/cargo tool installers (fd, bat, eza, ripgrep, duf, dust, procs, bottom)"
```

---

### Task 10: Remaining tools (zoxide, fzf, lazygit, lazydocker, claude-code, codex, cc-switch)

**Files:**
- Create: `scripts/tools/zoxide.sh`
- Create: `scripts/tools/fzf.sh`
- Create: `scripts/tools/lazygit.sh`
- Create: `scripts/tools/lazydocker.sh`
- Create: `scripts/tools/claude-code.sh`
- Create: `scripts/tools/codex.sh`
- Create: `scripts/tools/cc-switch.sh`

- [ ] **Step 1: Create zoxide.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/zoxide.sh
# zoxide — smart cd command

TOOL_NAME="zoxide"

install_zoxide() {
    if ! needs_install zoxide; then
        info "zoxide already installed, skipping"
        return 0
    fi

    info "Installing zoxide..."

    if is_macos; then
        run_cmd brew install zoxide
    elif is_linux; then
        run_cmd bash -c "$(curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)"
    fi

    success "zoxide installed"
}
```

- [ ] **Step 2: Create fzf.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/fzf.sh
# fzf — fuzzy finder (git clone for standalone install)

TOOL_NAME="fzf"

install_fzf() {
    if [ -d "$HOME/.fzf" ]; then
        info "fzf already installed, skipping"
        return 0
    fi

    info "Installing fzf..."

    if is_macos; then
        run_cmd brew install fzf
    fi

    # Also install standalone fzf via git clone (used by shell integration)
    if [ ! -d "$HOME/.fzf" ]; then
        run_cmd git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        run_cmd "$HOME/.fzf/install" --no-key-bindings --no-completion 2>/dev/null || true
    fi

    success "fzf installed"
}
```

- [ ] **Step 3: Create lazygit.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/lazygit.sh
# lazygit — TUI git client (brew / GitHub release)

TOOL_NAME="lazygit"

install_lazygit() {
    if ! needs_install lazygit; then
        info "lazygit already installed, skipping"
        return 0
    fi

    info "Installing lazygit..."

    if is_macos; then
        run_cmd brew install lazygit
    elif is_linux; then
        local arch
        arch=$(get_arch)
        local tag
        tag=$(download_github_release "jesseduffield/lazygit" \
            "lazygit_${arch}.tar.gz" "/tmp/lazygit.tar.gz")
        if [ $? -eq 0 ] && [ -n "$tag" ]; then
            run_cmd tar xf /tmp/lazygit.tar.gz lazygit
            run_cmd sudo install lazygit /usr/local/bin
            rm -f lazygit /tmp/lazygit.tar.gz
        fi
    fi

    success "lazygit installed"
}
```

- [ ] **Step 4: Create lazydocker.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/lazydocker.sh
# lazydocker — TUI docker client

TOOL_NAME="lazydocker"

install_lazydocker() {
    if ! needs_install lazydocker; then
        info "lazydocker already installed, skipping"
        return 0
    fi

    info "Installing lazydocker..."

    if is_macos; then
        run_cmd brew install lazydocker
    elif is_linux; then
        run_cmd bash -c "$(curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh)"
    fi

    success "lazydocker installed"
}
```

- [ ] **Step 5: Create claude-code.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/claude-code.sh
# Claude Code CLI — npm package

TOOL_NAME="claude-code"
TOOL_CMD="claude"

install_claude_code() {
    if ! needs_install claude; then
        info "Claude Code already installed, skipping"
        return 0
    fi

    info "Installing Claude Code..."

    if ! command_exists npm; then
        error "npm is required to install Claude Code"
        return 1
    fi

    run_cmd npm install -g @anthropic-ai/claude-code
    success "Claude Code installed"
}
```

- [ ] **Step 6: Create codex.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/codex.sh
# Codex CLI — npm package

TOOL_NAME="codex"

install_codex() {
    if ! needs_install codex; then
        info "Codex already installed, skipping"
        return 0
    fi

    info "Installing Codex..."

    if ! command_exists npm; then
        error "npm is required to install Codex"
        return 1
    fi

    run_cmd npm install -g @openai/codex
    success "Codex installed"
}
```

- [ ] **Step 7: Create cc-switch.sh**

```bash
#!/usr/bin/env bash
# scripts/tools/cc-switch.sh
# cc-switch — Claude Code account switcher (brew cask / deb)

TOOL_NAME="cc-switch"

install_cc_switch() {
    # Always fetch latest tag (needed for Linux install and version comparison)
    local latest_tag
    latest_tag=$(get_latest_release_tag "farion1231/cc-switch" 2>/dev/null || echo "")

    # Check if cc-switch is available via command
    if command -v cc-switch &>/dev/null; then
        local installed_version
        installed_version=$(cc-switch --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//')

        if [ -n "$latest_tag" ] && [ -n "$installed_version" ]; then
            local latest_ver
            latest_ver=$(echo "$latest_tag" | sed 's/^v//')
            if [ "$installed_version" = "$latest_ver" ]; then
                info "cc-switch already installed (v${installed_version})"
                return 0
            else
                info "cc-switch v${installed_version} installed, latest is v${latest_ver} — updating..."
            fi
        else
            info "cc-switch already installed"
            return 0
        fi
    fi

    # Check if cc-switch app exists (DMG install to /Applications)
    if [ -d "/Applications/CC Switch.app" ]; then
        info "cc-switch already installed (/Applications/CC Switch.app)"
        return 0
    fi

    info "Installing cc-switch..."

    if is_macos; then
        local brew_output
        brew_output=$(run_cmd brew install --cask farion1231/ccswitch/cc-switch 2>&1)
        local brew_status=$?

        if echo "$brew_output" | grep -q "already an App at"; then
            info "cc-switch already installed (macOS)"
            return 0
        fi

        if [ $brew_status -ne 0 ]; then
            error "Failed to install cc-switch via Homebrew"
            return 1
        fi
    elif is_linux; then
        if [ -z "$latest_tag" ]; then
            error "Failed to get latest cc-switch version"
            return 1
        fi

        local arch
        arch=$(get_arch)
        local file="CC-Switch-${latest_tag}-Linux-${arch}.deb"
        local url="https://github.com/farion1231/cc-switch/releases/download/${latest_tag}/${file}"

        info "Downloading $file"
        if ! run_cmd curl -fL -o "$file" "$url"; then
            error "Failed to download cc-switch ${latest_tag} for ${arch}"
            return 1
        fi

        run_cmd sudo apt-get install -y "./$file"
        rm -f "$file"
    fi

    if command -v cc-switch &>/dev/null; then
        success "cc-switch installed"
    else
        warning "cc-switch installation may have failed"
    fi
}
```

- [ ] **Step 8: Commit**

```bash
git add scripts/tools/zoxide.sh scripts/tools/fzf.sh scripts/tools/lazygit.sh \
    scripts/tools/lazydocker.sh scripts/tools/claude-code.sh scripts/tools/codex.sh \
    scripts/tools/cc-switch.sh
git commit -m "feat: add remaining tool installers (zoxide, fzf, lazygit, lazydocker, claude-code, codex, cc-switch)"
```

---

### Task 11: Special tools (shell, tmux, vim)

**Files:**
- Create: `scripts/tools/shell.sh`
- Create: `scripts/tools/tmux.sh`
- Create: `scripts/tools/vim.sh`

- [ ] **Step 1: Create shell.sh (Oh My Zsh + Powerlevel10k + chsh)**

```bash
#!/usr/bin/env bash
# scripts/tools/shell.sh
# Oh My Zsh, Powerlevel10k, fzf integration, and shell change

TOOL_NAME="shell"

install_shell() {
    info "Installing shell environment..."
    install_ohmyzsh
    install_powerlevel10k
    change_shell
    success "Shell environment installed"
}

install_ohmyzsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Oh My Zsh already installed"
        return 0
    fi

    info "Installing Oh My Zsh..."
    run_cmd bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        run_cmd git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        run_cmd git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    # zsh-history-substring-search
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
        run_cmd git clone https://github.com/zsh-users/zsh-history-substring-search.git \
            "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    fi

    success "Oh My Zsh installed"
}

install_powerlevel10k() {
    local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [ -d "$P10K_DIR" ]; then
        info "Powerlevel10k already installed"
        return 0
    fi

    info "Installing Powerlevel10k..."
    run_cmd git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    success "Powerlevel10k installed"
}

change_shell() {
    local zsh_path
    zsh_path=$(command -v zsh)

    if [ "$SHELL" = "$zsh_path" ]; then
        info "Shell is already zsh"
        return 0
    fi

    if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
        info "Adding zsh to /etc/shells"
        echo "$zsh_path" | run_cmd sudo tee -a /etc/shells 2>/dev/null || warning "Could not add zsh to /etc/shells"
    fi

    info "Changing default shell to zsh..."
    run_cmd chsh -s "$zsh_path" 2>/dev/null || warning "Could not change shell automatically (run: chsh -s $zsh_path)"
    success "Shell changed to zsh"
}
```

- [ ] **Step 2: Create tmux.sh (TPM install)**

```bash
#!/usr/bin/env bash
# scripts/tools/tmux.sh
# tmux + Tmux Plugin Manager (TPM)

TOOL_NAME="tmux"

install_tmux() {
    info "Installing tmux..."

    # Install tmux binary via package manager
    if ! needs_install tmux; then
        info "tmux already installed, skipping"
    else
        if is_macos; then
            if ! run_cmd brew install tmux; then
                info "Attempting brew postinstall tmux..."
                run_cmd brew postinstall tmux 2>/dev/null || warning "tmux postinstall failed"
            fi
        elif is_linux; then
            run_cmd sudo apt-get install -y tmux
        fi
    fi

    install_tpm
    success "tmux installed"
}

install_tpm() {
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        info "TPM already installed"
        return 0
    fi

    info "Installing Tmux Plugin Manager (TPM)..."
    run_cmd git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    success "TPM installed"
}
```

- [ ] **Step 3: Create vim.sh (space-vim submodule + vim-plug)**

```bash
#!/usr/bin/env bash
# scripts/tools/vim.sh
# space-vim (git submodule) + vim-plug

TOOL_NAME="vim"

install_vim() {
    info "Installing vim configuration..."

    local SPACEVIM_DIR="$DOTFILES_DIR/space-vim"

    # Initialize space-vim submodule if needed
    if [ ! -f "$SPACEVIM_DIR/init.vim" ]; then
        info "space-vim submodule not found, initializing..."
        local original_dir="$(pwd)"
        cd "$DOTFILES_DIR"
        run_cmd git submodule update --init --recursive
        cd "$original_dir"
    fi

    # Backup existing vimrc
    backup_file "$HOME/.vimrc"

    # Create vim directories
    mkdir -p "$HOME/.vim/undo"
    mkdir -p "$HOME/.vim/swap"
    mkdir -p "$HOME/.vim/autoload"

    # Install vim-plug
    if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
        info "Installing vim-plug..."
        run_cmd curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        success "vim-plug installed"
    fi

    # Create symlinks
    lnif "$SPACEVIM_DIR/init.vim" "$HOME/.vimrc"

    if [ ! -e "$HOME/.vimrc.bundle" ]; then
        lnif "$SPACEVIM_DIR/init.spacevim" "$HOME/.vimrc.bundle"
        success "Created ~/.vimrc.bundle"
    fi

    # Install vim plugins (non-interactive)
    if [ -d "$HOME/.vim/plugged" ] && [ "$(ls -A "$HOME/.vim/plugged" 2>/dev/null)" ]; then
        info "Vim plugins already installed, skipping"
    else
        info "Installing vim plugins via vim-plug..."
        vim -E -s -c "source $HOME/.vimrc" -c "PlugInstall --sync" -c "qa" 2>/dev/null || true
    fi

    success "space-vim configured"
}
```

- [ ] **Step 4: Commit**

```bash
git add scripts/tools/shell.sh scripts/tools/tmux.sh scripts/tools/vim.sh
git commit -m "feat: add special tool installers (shell, tmux, vim)"
```

---

### Task 12: Rewrite install.sh — new CLI and phase-based flow

**Files:**
- Modify: `install.sh` (full rewrite)

- [ ] **Step 1: Write the new install.sh**

```bash
#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installation Script for Ubuntu and macOS
# Tool Registry Architecture with Platform Abstraction Layer
# =============================================================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

# Source all lib modules
source "$SCRIPT_DIR/scripts/lib/os.sh"
source "$SCRIPT_DIR/scripts/lib/log.sh"
source "$SCRIPT_DIR/scripts/lib/assert.sh"
source "$SCRIPT_DIR/scripts/lib/symlink.sh"
source "$SCRIPT_DIR/scripts/lib/package.sh"
source "$SCRIPT_DIR/scripts/lib/github.sh"

# Set OS
export OS=${OS:-$(detect_os)}

# Source config manifest
source "$SCRIPT_DIR/scripts/configs/manifest.sh"

# Source all tool modules
for tool_file in "$SCRIPT_DIR/scripts/tools/"*.sh; do
    if [ -f "$tool_file" ] && [ "$(basename "$tool_file")" != "_template.sh" ]; then
        source "$tool_file"
    fi
done

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Track enabled tools
ALL_TOOLS=()
ENABLED_TOOLS=()
SKIP_TOOLS=()
SKIP_SHELL=false
SKIP_CONFIGS=false

# Discover all tools from tool files
discover_tools() {
    ALL_TOOLS=()
    for tool_file in "$SCRIPT_DIR/scripts/tools/"*.sh; do
        local name
        name=$(basename "$tool_file" .sh)
        if [ "$name" != "_template" ]; then
            ALL_TOOLS+=("$name")
        fi
    done
}

# Print banner
print_banner() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║           Dotfiles Installer (Ubuntu & macOS)                  ║
║           Tool Registry Edition                                ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF
    info "Detected OS: $OS"
    info "Dotfiles directory: $DOTFILES_DIR"
}

# Print usage
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --tools <list>      Install only specified tools (comma-separated)"
    echo "  --skip-tools <list> Skip specified tools (comma-separated)"
    echo "  --skip-shell        Skip Oh My Zsh and Powerlevel10k"
    echo "  --skip-configs      Skip config file symlinks"
    echo "  --dry-run           Show what would be done without executing"
    echo "  --list-tools        List all available tools"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          Full installation"
    echo "  $0 --tools fd,bat,eza       Install only specific tools"
    echo "  $0 --skip-tools procs,bottom  Skip specific tools"
    echo "  $0 --dry-run                Preview what would be installed"
    echo ""
    echo "Available tools:"
    for tool in "${ALL_TOOLS[@]}"; do
        echo "  $tool"
    done
}

# Parse CLI arguments
parse_args() {
    discover_tools

    # Default: enable all tools
    ENABLED_TOOLS=("${ALL_TOOLS[@]}")

    while [[ $# -gt 0 ]]; do
        case $1 in
            --tools)
                if [ -z "$2" ]; then
                    error "--tools requires a comma-separated list"
                    exit 1
                fi
                ENABLED_TOOLS=()
                IFS=',' read -ra ENABLED_TOOLS <<< "$2"
                shift 2
                ;;
            --skip-tools)
                if [ -z "$2" ]; then
                    error "--skip-tools requires a comma-separated list"
                    exit 1
                fi
                IFS=',' read -ra SKIP_TOOLS <<< "$2"
                shift 2
                ;;
            --skip-shell)
                SKIP_SHELL=true
                shift
                ;;
            --skip-configs)
                SKIP_CONFIGS=true
                shift
                ;;
            --dry-run)
                export DRY_RUN=1
                shift
                ;;
            --list-tools)
                for tool in "${ALL_TOOLS[@]}"; do
                    echo "$tool"
                done
                exit 0
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done

    # Remove skipped tools from enabled list
    if [ ${#SKIP_TOOLS[@]} -gt 0 ]; then
        local filtered=()
        for tool in "${ENABLED_TOOLS[@]}"; do
            local skip=false
            for s in "${SKIP_TOOLS[@]}"; do
                if [ "$tool" = "$s" ]; then
                    skip=true
                    break
                fi
            done
            if [ "$skip" = false ]; then
                filtered+=("$tool")
            fi
        done
        ENABLED_TOOLS=("${filtered[@]}")
    fi
}

# Phase 1: Install prerequisites (git, curl, wget, node)
install_prerequisites() {
    info "=== Phase 1: Prerequisites ==="

    if is_macos; then
        if ! command_exists brew; then
            info "Installing Homebrew..."
            run_cmd bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [ -d "/opt/homebrew/bin" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -d "/usr/local/bin" ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            info "Homebrew is already installed"
        fi
        install_packages_batch git curl wget node
    elif is_linux; then
        install_packages_batch git curl wget nodejs npm
    fi

    success "Prerequisites installed"
}

# Phase 2: Core packages (tmux, vim, tig, tree, ctags)
install_core_packages() {
    info "=== Phase 2: Core packages ==="

    if is_macos; then
        local pkgs=("tmux" "vim" "git" "tig" "tree" "universal-ctags" "jq" "yq" "httpie" "tldr" "the_silver_searcher")
        install_packages_batch "${pkgs[@]}"

        # tmux fallback
        if ! command_exists tmux; then
            info "Attempting brew postinstall tmux..."
            run_cmd brew postinstall tmux 2>/dev/null || warning "tmux postinstall failed"
        fi
    elif is_linux; then
        local pkgs=("tmux" "vim" "git" "tig" "tree" "jq" "httpie" "silversearcher-ag")
        install_packages_batch "${pkgs[@]}"
        install_universal_ctags
        install_build_essential
        install_tldr
    fi

    success "Core packages installed"
}

# Linux-only: build Universal Ctags from source
install_universal_ctags() {
    if ! is_linux; then return 0; fi

    # Already Universal Ctags?
    if command -v ctags &>/dev/null && ctags --version 2>/dev/null | grep -q "Universal"; then
        info "Universal Ctags already installed, skipping"
        return 0
    fi

    info "Installing Universal Ctags from source..."
    local build_deps=("build-essential" "autoconf" "automake" "pkg-config")
    for dep in "${build_deps[@]}"; do
        if ! apt_package_installed "$dep"; then
            run_cmd sudo apt-get install -y "$dep"
        fi
    done

    local original_dir="$(pwd)"
    rm -rf /tmp/ctags
    run_cmd git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
    cd /tmp/ctags
    ./autogen.sh && ./configure --prefix=/usr/local && make && run_cmd sudo make install
    cd "$original_dir"
    rm -rf /tmp/ctags

    if command -v /usr/local/bin/ctags &>/dev/null && /usr/local/bin/ctags --version | grep -q "Universal"; then
        success "Universal Ctags installed"
    else
        warning "Universal Ctags installation may have failed"
    fi
}

# Linux-only: build-essential
install_build_essential() {
    if ! is_linux; then return 0; fi
    if apt_package_installed "build-essential"; then
        info "build-essential already installed, skipping"
        return 0
    fi
    run_cmd sudo apt-get install -y build-essential && success "build-essential installed"
}

# Linux-only: tldr
install_tldr() {
    if ! is_linux; then return 0; fi
    if needs_install tldr; then
        info "Installing tldr..."
        run_cmd sudo apt-get install -y tldr || run_cmd npm install -g tldr 2>/dev/null || true
    fi
}

# Phase 4: Link all config files using manifest
link_all_configs() {
    info "=== Phase 4: Config symlinks ==="

    for entry in "${CONFIGS[@]}"; do
        IFS='|' read -r src target platform_flags <<< "$entry"
        local platform="${platform_flags%%:*}"
        local flags="${platform_flags#*:}"
        [ "$flags" = "$platform" ] && flags=""

        # Check platform filter
        if [ "$platform" != "all" ]; then
            if [ "$platform" = "macos" ] && ! is_macos; then continue; fi
            if [ "$platform" = "linux" ] && ! is_linux; then continue; fi
        fi

        # Expand ~ in target
        target="${target/#\~/$HOME}"

        # Handle skip_existing flag
        if [[ "$flags" == *"skip_existing"* ]] && [ -e "$target" ]; then
            info "Skipping $(basename "$target") (already exists)"
            continue
        fi

        # Ensure parent directory exists
        mkdir -p "$(dirname "$target")"

        backup_file "$target"
        if lnif "$DOTFILES_DIR/$src" "$target"; then
            info "Linked $src → $target"
        else
            warning "Failed to link $src (source may not exist)"
        fi
    done

    success "Configuration files linked"
}

# Post-installation message
post_install() {
    cat << 'EOF'

╔════════════════════════════════════════════════════════════════╗
║                   Installation Complete!                       ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Next steps:                                                   ║
║  1. Restart your terminal or run: source ~/.zshrc             ║
║  2. For tmux plugins, press 'prefix + I' in a tmux session    ║
║  3. To customize Powerlevel10k prompt: p10k configure          ║
║  4. space-vim is ready! Customize via ~/.vimrc.bundle         ║
║                                                                ║
║  Shell Configuration:                                          ║
║  • ~/.zshrc              - Main configuration (linked)        ║
║  • ~/.zshrc.local        - Local customizations               ║
║                                                                ║
║  Your original configs are backed up to:
EOF
    echo "║    $BACKUP_DIR"
    cat << 'EOF2'
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

EOF2
}

# Main installation flow
main() {
    parse_args "$@"
    assert_supported_os
    print_banner

    # Phase 1: Prerequisites
    install_prerequisites

    # Phase 2: Core packages
    install_core_packages

    # Phase 3: Tools (on demand)
    info "=== Phase 3: Tools ==="
    for tool in "${ENABLED_TOOLS[@]}"; do
        if [ "$tool" = "shell" ] || [ "$tool" = "tmux" ] || [ "$tool" = "vim" ]; then
            continue  # Skip special tools here, handled below
        fi
        local func="install_${tool//-/_}"
        if type -t "$func" &>/dev/null; then
            "$func"
        else
            warning "No install function found for tool: $tool (expected: $func)"
        fi
    done

    # Special tools (shell, tmux, vim) — always run unless explicitly skipped
    if [ "$SKIP_SHELL" != true ]; then
        local shell_in_tools=false
        for t in "${ENABLED_TOOLS[@]}"; do
            [ "$t" = "shell" ] && shell_in_tools=true
        done
        if [ "$shell_in_tools" = true ]; then
            install_shell
        fi
    fi

    for t in "${ENABLED_TOOLS[@]}"; do
        [ "$t" = "tmux" ] && install_tmux
        [ "$t" = "vim" ] && install_vim
    done

    # Phase 4: Config symlinks
    if [ "$SKIP_CONFIGS" != true ]; then
        link_all_configs
    fi

    post_install
}

main "$@"
```

- [ ] **Step 2: Syntax check**

```bash
bash -n install.sh
```

Expected: No output (no syntax errors).

- [ ] **Step 3: Verify --help output**

```bash
./install.sh --help
```

Expected: Usage info with all options listed and available tools shown.

- [ ] **Step 4: Verify --list-tools output**

```bash
./install.sh --list-tools
```

Expected: List of all tool names (one per line).

- [ ] **Step 5: Verify --dry-run works**

```bash
./install.sh --dry-run --tools fd 2>&1 | head -20
```

Expected: Output contains `[DRY-RUN]` lines showing what would be executed.

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat: rewrite install.sh with tool registry and new CLI"
```

---

### Task 13: Rewrite uninstall.sh

**Files:**
- Modify: `uninstall.sh` (full rewrite)

- [ ] **Step 1: Write the new uninstall.sh**

```bash
#!/usr/bin/env bash
# =============================================================================
# Dotfiles Uninstall Script
# Removes symbolic links using the shared config manifest
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# Source lib modules
source "$SCRIPT_DIR/scripts/lib/os.sh"
source "$SCRIPT_DIR/scripts/lib/log.sh"
source "$SCRIPT_DIR/scripts/lib/assert.sh"
source "$SCRIPT_DIR/scripts/lib/symlink.sh"

# Set OS
export OS=${OS:-$(detect_os)}

# Source config manifest (shared with install.sh)
source "$SCRIPT_DIR/scripts/configs/manifest.sh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Dotfiles Uninstaller                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Remove symlinks defined in manifest (reverse order)
info "Removing config symlinks..."

for (( i=${#CONFIGS[@]}-1; i>=0; i-- )); do
    entry="${CONFIGS[$i]}"
    IFS='|' read -r src target platform_flags <<< "$entry"
    local platform="${platform_flags%%:*}"

    # Check platform filter
    if [ "$platform" != "all" ]; then
        if [ "$platform" = "macos" ] && ! is_macos; then continue; fi
        if [ "$platform" = "linux" ] && ! is_linux; then continue; fi
    fi

    # Expand ~ in target
    target="${target/#\~/$HOME}"

    if [ -L "$target" ]; then
        info "Removing symlink: $target"
        rm "$target"
    elif [ -e "$target" ]; then
        warning "Not a symlink, skipping: $target"
    fi
done

# Remove vim symlinks (not in manifest, created by tools/vim.sh)
for vimfile in "$HOME/.vimrc" "$HOME/.vimrc.bundle"; do
    if [ -L "$vimfile" ]; then
        info "Removing symlink: $vimfile"
        rm "$vimfile"
    fi
done

# Clean up Powerlevel10k instant prompt cache
if [ -d "$HOME/.cache" ]; then
    info "Cleaning Powerlevel10k cache..."
    rm -f "$HOME/.cache/p10k-instant-prompt-"*".zsh" 2>/dev/null || true
fi

# Clean up vim-plug and plugins
if [ -d "$HOME/.vim/plugged" ]; then
    info "Note: ~/.vim/plugged contains vim plugins (not removed)"
fi

echo ""
echo "Uninstallation complete!"
echo ""
echo "Note: The following were not removed:"
echo "  - ~/.oh-my-zsh (Oh My Zsh installation)"
echo "  - ~/.oh-my-zsh/custom/themes/powerlevel10k (Powerlevel10k theme)"
echo "  - ~/.tmux/plugins (Tmux plugins)"
echo "  - ~/.fzf (FZF installation)"
echo "  - ~/.vim (Vim configuration and plugins)"
echo ""
echo "To completely remove everything, run:"
echo "  rm -rf ~/.oh-my-zsh ~/.tmux ~/.fzf ~/.vim ~/.cache/p10k-*"
echo ""
```

- [ ] **Step 2: Syntax check**

```bash
bash -n uninstall.sh
```

Expected: No output (no syntax errors).

- [ ] **Step 3: Commit**

```bash
git add uninstall.sh
git commit -m "feat: rewrite uninstall.sh using shared config manifest"
```

---

### Task 14: Update scripts/update.sh

**Files:**
- Modify: `scripts/update.sh`

- [ ] **Step 1: Rewrite update.sh to use lib/ functions**

```bash
#!/usr/bin/env bash
# =============================================================================
# Dotfiles Update Script
# Updates all plugins and configurations
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source lib modules
source "$SCRIPT_DIR/lib/os.sh"
source "$SCRIPT_DIR/lib/log.sh"
source "$SCRIPT_DIR/lib/assert.sh"

export OS=${OS:-$(detect_os)}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  Dotfiles Updater                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Update dotfiles repository
if command_exists git; then
    info "Updating dotfiles repository..."
    cd "$DOTFILES_DIR"
    git pull origin "$(git branch --show-current 2>/dev/null || echo main)"

    # Update submodules (space-vim)
    info "Updating submodules..."
    git submodule update --init --recursive
    git submodule update --remote
else
    warning "git not found, skipping dotfiles update"
fi

# Update Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    if command_exists omz; then
        info "Updating Oh My Zsh..."
        omz update || true
    fi

    # Update custom plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    for plugin_dir in "$ZSH_CUSTOM/plugins"/*; do
        if [ -d "$plugin_dir/.git" ]; then
            info "Updating plugin: $(basename "$plugin_dir")"
            cd "$plugin_dir" && git pull
        fi
    done
fi

# Update fzf
if [ -d "$HOME/.fzf" ]; then
    if command_exists git; then
        info "Updating fzf..."
        cd "$HOME/.fzf" && git pull && ./install --bin
    fi
fi

# Update Tmux plugins
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    if command_exists git; then
        info "Updating Tmux Plugin Manager..."
        cd "$HOME/.tmux/plugins/tpm" && git pull
    fi

    if [ -f "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]; then
        info "Updating Tmux plugins..."
        "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
    fi
fi

# Update Vim plugins
if command_exists vim && [ -f "$HOME/.vimrc" ]; then
    info "Updating Vim plugins..."
    vim +PlugUpdate +qall
fi

success "Update complete!"
echo ""
echo "You may need to restart your terminal or source your shell config."
```

- [ ] **Step 2: Syntax check**

```bash
bash -n scripts/update.sh
```

Expected: No output.

- [ ] **Step 3: Commit**

```bash
git add scripts/update.sh
git commit -m "feat: update scripts/update.sh to use lib/ functions"
```

---

### Task 15: Keep shell/utils.sh for interactive use, update CLAUDE.md, clean up old files

**Files:**
- Modify: `shell/utils.sh` (thin wrapper sourcing lib/)
- Modify: `CLAUDE.md`
- Delete: `scripts/install/01-prerequisites.sh`
- Delete: `scripts/install/02-packages.sh`
- Delete: `scripts/install/03-modern-tools.sh`
- Delete: `scripts/install/04-shell.sh`
- Delete: `scripts/install/05-tmux.sh`
- Delete: `scripts/install/06-vim.sh`
- Delete: `scripts/install/07-tools.sh`
- Delete: `scripts/install/08-configs.sh`
- Delete: `scripts/utils.sh`

- [ ] **Step 1: Update shell/utils.sh as thin wrapper**

```bash
#!/usr/bin/env sh
# =============================================================================
# Shell utility functions (for interactive shell use)
# Sources lib/ modules for shared functionality
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
```

This keeps `shell/utils.sh` minimal for interactive shell sourcing. The full implementations live in `scripts/lib/`.

- [ ] **Step 2: Update CLAUDE.md**

Replace the entire CLAUDE.md with updated content reflecting the new architecture:

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform dotfiles repository for Ubuntu and macOS featuring Oh My Zsh with Powerlevel10k theme. Uses a tool-registry architecture with a shared platform abstraction layer.

## Common Commands

### Installation
```bash
./install.sh                          # Full installation
./install.sh --tools fd,bat,eza       # Install only specified tools
./install.sh --skip-tools procs       # Skip specific tools
./install.sh --dry-run                # Preview without executing
./install.sh --list-tools             # List all available tools
./install.sh --help                   # Show usage
```

### Bootstrap (new machine)
```bash
curl -fsSL https://raw.githubusercontent.com/andyt9527/dotfiles/main/bootstrap.sh | bash
```

### Update
```bash
./scripts/update.sh                   # Update all plugins and dotfiles
```

### Uninstall
```bash
./uninstall.sh                        # Remove dotfiles symlinks (uses shared manifest)
```

### Testing
```bash
./scripts/tests/run_tests.sh          # Run all bats tests
./scripts/tests/run_tests.sh scripts/tests/test_os.sh  # Run specific test
```

### Verification (during development)
```bash
bash -n install.sh
bash -n scripts/lib/*.sh
bash -n scripts/tools/*.sh
zsh -n shell/zshrc
```

## Architecture

### Tool Registry Pattern
- `scripts/tools/` — one file per tool, each exports an `install_<tool>()` function
- `scripts/tools/_template.sh` — copy this to add a new tool
- Adding a new tool: copy `_template.sh`, edit install function, done
- Tools are auto-discovered from the `scripts/tools/` directory

### Platform Abstraction Layer (`scripts/lib/`)
- `os.sh` — `detect_os()`, `is_macos()`, `is_linux()`, `get_arch()`, `assert_supported_os()`
- `log.sh` — `info()`, `success()`, `warning()`, `error()`, `run_cmd()` (dry-run wrapper)
- `assert.sh` — `needs_install()`, `command_exists()`
- `package.sh` — `install_package()`, `install_packages_batch()`, `package_installed()`, `brew_package_installed()`, `apt_package_installed()`
- `symlink.sh` — `link_config()`, `backup_file()`, `lnif()`
- `github.sh` — `get_latest_release_tag()`, `download_github_release()`

### Config Manifest
- `scripts/configs/manifest.sh` — declarative symlink config, shared by install and uninstall
- Format: `"source_relative|target_path|platform[:flags]"`
- Single source of truth — eliminates sync issues between install/uninstall

### Key Directories
- `shell/` — Zsh configuration (zshrc, aliases.zsh, exports.zsh, utils.sh)
- `config/` — Application configs (p10k.zsh, lazygit.yml, lazydocker.yml)
- `tmux/` — Tmux configuration (tmux.conf)
- `tig/` — Tig configuration (tigrc, tigrc.theme)
- `scripts/lib/` — Shared function library
- `scripts/tools/` — Tool install scripts (one per tool)
- `scripts/configs/` — Declarative config mappings
- `scripts/tests/` — bats-core tests
- `docs/superpowers/` — Design specs and implementation plans

### Install Phases
1. **Prerequisites** — Homebrew (macOS), git, curl, wget, node
2. **Core packages** — tmux, vim, tig, tree, universal-ctags
3. **Tools** — Each tool from `scripts/tools/` (on demand via CLI)
4. **Shell** — Oh My Zsh + Powerlevel10k + chsh
5. **Config symlinks** — Reads manifest.sh

### Dry-Run Mode
All side-effect operations go through `run_cmd()`. Set `DRY_RUN=1` or use `--dry-run` flag to preview without executing.

### Cross-Platform Patterns
- `$OS` variable (`macos`/`linux`) controls platform behavior
- `is_macos` / `is_linux` for branching
- `get_arch()` normalizes `uname -m` to `x86_64`/`aarch64`
- `assert_supported_os()` guards against unsupported platforms

### Linux-Specific Handling
- `fd` installed as `fdfind`; symlinked to `~/.local/bin/fd`
- `bat` installed as `batcat`; symlinked to `~/.local/bin/bat`
- Rust-based tools via `cargo` when available
- Universal Ctags built from source when unavailable

### Local Overrides
- `~/.zshrc.local` — Zsh local settings (sourced at end of zshrc)
- `~/.p10k.zsh` — Powerlevel10k configuration
- `~/.vimrc.bundle` — space-vim layer configuration
- `git/gitconfig.local` — Environment-specific git settings

## Development

### When adding a new tool
1. Copy `scripts/tools/_template.sh` to `scripts/tools/<name>.sh`
2. Edit the `install_<name>()` function
3. If the tool has a config file, add an entry to `scripts/configs/manifest.sh`
4. No other files need editing

### When modifying lib/ modules
- Each lib module is independently sourceable and testable
- Write tests first in `scripts/tests/test_<module>.sh`
- Run `./scripts/tests/run_tests.sh` to verify

### Testing
- Uses bats-core with bats-support and bats-assert
- Tests live in `scripts/tests/`
- Focus on `lib/` module unit tests; tool files validated via `--dry-run`

## Important Notes

### space-vim is a Git Submodule
Clone with `--recursive` or run `git submodule update --init --recursive`

### Universal Ctags Required
space-vim requires Universal Ctags. On macOS: `brew install universal-ctags`. On Linux, installed from source automatically.

### Powerlevel10k Icons
Requires Nerd Font — install via `brew install --cask font-meslo-lg-nerd-font` on macOS
```

- [ ] **Step 3: Delete old install scripts**

```bash
rm scripts/install/01-prerequisites.sh
rm scripts/install/02-packages.sh
rm scripts/install/03-modern-tools.sh
rm scripts/install/04-shell.sh
rm scripts/install/05-tmux.sh
rm scripts/install/06-vim.sh
rm scripts/install/07-tools.sh
rm scripts/install/08-configs.sh
rm scripts/utils.sh
rmdir scripts/install 2>/dev/null || true
```

- [ ] **Step 4: Run full test suite**

```bash
./scripts/tests/run_tests.sh
```

Expected: All tests PASS.

- [ ] **Step 5: Verify install.sh still works end-to-end**

```bash
./install.sh --dry-run 2>&1 | head -30
```

Expected: Output shows dry-run of all install phases.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: complete modular refactor — remove old scripts, update CLAUDE.md"
```

---

## Self-Review

### Spec Coverage

| Spec Section | Task |
|---|---|
| Directory structure (lib/, tools/, configs/, tests/) | Tasks 1-15 |
| lib/os.sh | Task 2 |
| lib/log.sh + run_cmd | Task 3 |
| lib/assert.sh | Task 4 |
| lib/package.sh | Task 5 |
| lib/symlink.sh | Task 6 |
| lib/github.sh | Task 7 |
| configs/manifest.sh | Task 8 |
| Tool files (all 17) | Tasks 9, 10, 11 |
| install.sh rewrite (new CLI, phases) | Task 12 |
| uninstall.sh rewrite | Task 13 |
| update.sh update | Task 14 |
| Cleanup + CLAUDE.md | Task 15 |
| bats-core setup | Task 1 |
| Dry-run mode | Task 3 (run_cmd) + Task 12 (--dry-run flag) |
| Linux-specific handling preserved | Tasks 9 (fd/bat symlinks), 11 (cargo), 12 (ctags from source) |

### Placeholder Scan
No TBD, TODO, or vague steps found. All steps contain actual code.

### Type Consistency
- All tool files use `install_<toolname>()` function naming — matches `install.sh`'s `"install_${tool//-/_}"` call convention (hyphens replaced with underscores: `claude-code` → `install_claude_code`)
- `CONFIGS` array format `"src|target|platform[:flags]"` is consistent between manifest.sh and both install.sh and uninstall.sh parsing logic
- `BACKUP_DIR` used in `backup_file()` is set in both install.sh and symlink.sh tests
