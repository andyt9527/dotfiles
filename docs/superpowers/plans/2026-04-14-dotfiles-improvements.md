# Dotfiles Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve dotfiles install script with fast-path pre-checks, dependency validation, parallel installs for independent tools, and richer error context.

**Architecture:** Add `needs_install()` helper to utils.sh, then apply fast-path checks + error context to all install modules. In 07-tools.sh specifically, implement parallelization for independent tool installs.

**Tech Stack:** Bash shell scripts

---

## File Map

| File | Responsibility |
|------|----------------|
| `scripts/utils.sh` | Add `needs_install()` helper — fast command check |
| `scripts/install/07-tools.sh` | Main focus — all 4 improvements |
| `scripts/install/02-packages.sh` | Fast-path checks + error context |
| `scripts/install/03-modern-tools.sh` | Fast-path checks + error context |
| `scripts/install/05-tmux.sh` | Fast-path checks + error context |

---

## Task 1: Add `needs_install()` helper to utils.sh

**Files:**
- Modify: `scripts/utils.sh` (add after `command_exists()` function)

- [ ] **Step 1: Add `needs_install()` helper after `command_exists()`**

Find this block in `scripts/utils.sh`:
```bash
# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
```

Insert after:
```bash
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
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n scripts/utils.sh`
Expected: No output (success)

- [ ] **Step 3: Commit**

```bash
git add scripts/utils.sh
git commit -m "feat(install): add needs_install() helper for fast-path pre-checks"
```

---

## Task 2: Improve 07-tools.sh with all 4 improvements

**Files:**
- Modify: `scripts/install/07-tools.sh` (complete rewrite with all improvements)

- [ ] **Step 1: Read current 07-tools.sh**

Read `scripts/install/07-tools.sh` in full to understand current state.

- [ ] **Step 2: Add dependency array and check function at top**

After the `INSTALL_CC_SWITCH=${INSTALL_CC_SWITCH:-true}` lines, add:

```bash
# Dependencies for tools module
TOOLS_DEPS=(npm)

check_tools_dependencies() {
    for dep in "${TOOLS_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            error "Missing $dep — required for Claude Code / Codex installation"
            info "Install node via: brew install node (macOS) or sudo apt install nodejs (Linux)"
            return 1
        fi
    done
}
```

- [ ] **Step 3: Rewrite `install_tools()` with parallelization**

Replace the current `install_tools()` function with:

```bash
install_tools() {
    info "Installing tools..."

    check_tools_dependencies || return 1

    # Parallel installs for independent tools (no shared deps)
    install_lazygit &
    local lazygit_pid=$!

    install_lazydocker &
    local lazydocker_pid=$!

    install_cc_switch &
    local ccswitch_pid=$!

    # Wait for parallel installs
    local failed=0
    wait $lazygit_pid || ((failed++))
    wait $lazydocker_pid || ((failed++))
    wait $ccswitch_pid || ((failed++))

    # Sequential for npm-based tools (share npm)
    install_claude_code
    install_codex

    if [ $failed -gt 0 ]; then
        warning "$failed tool(s) failed to install — check errors above"
    fi

    success "Tools installed"
}
```

- [ ] **Step 4: Add fast-path to `install_lazygit()`**

Replace the existing `install_lazygit()` with:

```bash
install_lazygit() {
    if ! needs_install lazygit; then
        info "Lazygit already installed, skipping"
        return 0
    fi

    info "Installing Lazygit..."

    if [ "$OS" = "macos" ]; then
        if ! brew install lazygit 2>&1; then
            error "Failed to install lazygit via Homebrew"
            info "Try manually: brew install lazygit"
            return 1
        fi
    elif [ "$OS" = "linux" ]; then
        local ARCH
        case "$(uname -m)" in
            x86_64|amd64) ARCH="x86_64" ;;
            aarch64|arm64) ARCH="arm64" ;;
            *) ARCH="x86_64" ;;
        esac

        local LAZYGIT_VERSION
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -o 'v[0-9.]*' | head -1 | sed 's/v//')

        if [ -z "$LAZYGIT_VERSION" ]; then
            error "Failed to fetch lazygit version from GitHub API"
            return 1
        fi

        if ! curl -fL -o lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz" 2>&1; then
            error "Failed to download lazygit v${LAZYGIT_VERSION}"
            info "Check network connectivity and GitHub reachability"
            return 1
        fi

        tar xf lazygit.tar.gz lazygit
        if ! sudo install lazygit /usr/local/bin 2>&1; then
            error "Failed to install lazygit to /usr/local/bin"
            info "Check permissions — you may need sudo"
            rm -f lazygit lazygit.tar.gz
            return 1
        fi
        rm -f lazygit lazygit.tar.gz
    fi

    success "Lazygit installed"
}
```

- [ ] **Step 5: Add fast-path to `install_lazydocker()`**

Replace the existing `install_lazydocker()` with:

```bash
install_lazydocker() {
    if ! needs_install lazydocker; then
        info "Lazydocker already installed, skipping"
        return 0
    fi

    info "Installing Lazydocker..."

    if [ "$OS" = "macos" ]; then
        if ! brew install lazydocker 2>&1; then
            error "Failed to install lazydocker via Homebrew"
            info "Try manually: brew install lazydocker"
            return 1
        fi
    elif [ "$OS" = "linux" ]; then
        if ! curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh 2>&1 | bash; then
            error "Failed to install lazydocker"
            info "Try manually: curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
            return 1
        fi
    fi

    success "Lazydocker installed"
}
```

- [ ] **Step 6: Add fast-path to `install_claude_code()`**

Replace the existing `install_claude_code()` with:

```bash
install_claude_code() {
    if ! needs_install claude; then
        info "Claude Code already installed, skipping"
        return 0
    fi

    if ! command -v npm >/dev/null 2>&1; then
        error "npm is required for Claude Code installation"
        info "Install node via: brew install node (macOS) or sudo apt install nodejs (Linux)"
        return 1
    fi

    info "Installing Claude Code..."

    if ! npm install -g @anthropic-ai/claude-code 2>&1; then
        error "npm install failed for @anthropic-ai/claude-code"
        info "Try manually: npm install -g @anthropic-ai/claude-code --verbose"
        return 1
    fi

    if ! needs_install claude; then
        error "Claude Code command 'claude' not found after npm install"
        info "Check npm global bin path is in your PATH"
        return 1
    fi

    success "Claude Code installed"
}
```

- [ ] **Step 7: Add fast-path to `install_codex()`**

Replace the existing `install_codex()` with:

```bash
install_codex() {
    if ! needs_install codex; then
        info "Codex already installed, skipping"
        return 0
    fi

    if ! command -v npm >/dev/null 2>&1; then
        error "npm is required for Codex installation"
        info "Install node via: brew install node (macOS) or sudo apt install nodejs (Linux)"
        return 1
    fi

    info "Installing Codex..."

    if ! npm install -g @openai/codex 2>&1; then
        error "npm install failed for @openai/codex"
        info "Try manually: npm install -g @openai/codex --verbose"
        return 1
    fi

    if ! needs_install codex; then
        error "Codex command 'codex' not found after npm install"
        info "Check npm global bin path is in your PATH"
        return 1
    fi

    success "Codex installed"
}
```

- [ ] **Step 8: Rewrite `install_cc_switch()` with fast-path and error context**

Replace the existing `install_cc_switch()` with one that handles the macOS "app already exists" error:

```bash
install_cc_switch() {
    if ! needs_install cc-switch; then
        # Version check — skip if current version matches latest
        local latest_tag
        latest_tag=$(get_cc_switch_latest_tag 2>/dev/null)
        local installed_version
        installed_version=$(cc-switch --version 2>/dev/null | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//')

        if [ -n "$latest_tag" ] && [ -n "$installed_version" ]; then
            local latest_ver
            latest_ver=$(echo "$latest_tag" | sed 's/^v//')
            if [ "$installed_version" = "$latest_ver" ]; then
                info "cc-switch already installed (v${installed_version}), skipping"
                return 0
            else
                info "cc-switch v${installed_version} installed, latest is v${latest_ver} — updating..."
            fi
        else
            info "cc-switch already installed, skipping"
            return 0
        fi
    fi

    info "Installing cc-switch..."

    if [ "$OS" = "macos" ]; then
        # Handle "app already exists" error gracefully
        if ! brew install --cask farion1231/ccswitch/cc-switch 2>&1; then
            local install_output="$(
                brew install --cask farion1231/ccswitch/cc-switch 2>&1 || true
            )"
            if echo "$install_output" | grep -q "already an App at"; then
                info "cc-switch app already exists — skipping install"
                return 0
            else
                error "Failed to install cc-switch via Homebrew"
                info "Try manually: brew install --cask farion1231/ccswitch/cc-switch"
                return 1
            fi
        fi
    elif [ "$OS" = "linux" ]; then
        install_cc_switch_linux
    else
        info "cc-switch is not supported on this OS"
        return 0
    fi

    if needs_install cc-switch; then
        error "cc-switch command not found after installation"
        return 1
    fi

    success "cc-switch installed"
}
```

- [ ] **Step 9: Update `get_cc_switch_latest_tag()` to handle errors**

```bash
get_cc_switch_latest_tag() {
    local tag
    tag=$(curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest 2>/dev/null | jq -r '.tag_name')
    if [ "$tag" = "null" ] || [ -z "$tag" ]; then
        return 1
    fi
    echo "$tag"
}
```

- [ ] **Step 10: Verify syntax**

Run: `bash -n scripts/install/07-tools.sh`
Expected: No output

- [ ] **Step 11: Commit**

```bash
git add scripts/install/07-tools.sh
git commit -m "feat(install): improve 07-tools with fast-path checks, parallel installs, and error context"
```

---

## Task 3: Apply fast-path checks to 02-packages.sh

**Files:**
- Modify: `scripts/install/02-packages.sh`

- [ ] **Step 1: Read current 02-packages.sh**

Read `scripts/install/02-packages.sh` in full.

- [ ] **Step 2: Identify install functions to wrap**

Find each `install_X()` function that calls `brew install` or `apt-get install`. For each, add `needs_install` check at the top.

For example, wrapping `tmux` install:
```bash
install_tmux() {
    if ! needs_install tmux; then
        info "tmux already installed, skipping"
        return 0
    fi
    # ... existing install logic
}
```

Do this for: tmux, vim, git, tig, tree.

- [ ] **Step 3: Verify syntax**

Run: `bash -n scripts/install/02-packages.sh`
Expected: No output

- [ ] **Step 4: Commit**

```bash
git add scripts/install/02-packages.sh
git commit -m "feat(install): add fast-path checks to 02-packages"
```

---

## Task 4: Apply fast-path checks to 03-modern-tools.sh

**Files:**
- Modify: `scripts/install/03-modern-tools.sh`

- [ ] **Step 1: Read current 03-modern-tools.sh**

Read `scripts/install/03-modern-tools.sh` in full.

- [ ] **Step 2: Wrap each tool install with `needs_install`**

Apply fast-path checks to: fd, bat, eza, zoxide, fzf, ripgrep.

- [ ] **Step 3: Verify syntax**

Run: `bash -n scripts/install/03-modern-tools.sh`
Expected: No output

- [ ] **Step 4: Commit**

```bash
git add scripts/install/03-modern-tools.sh
git commit -m "feat(install): add fast-path checks to 03-modern-tools"
```

---

## Task 5: Apply fast-path checks to 05-tmux.sh

**Files:**
- Modify: `scripts/install/05-tmux.sh`

- [ ] **Step 1: Read current 05-tmux.sh**

Read `scripts/install/05-tmux.sh` in full.

- [ ] **Step 2: Wrap with `needs_install` if it installs anything**

Most tmux install is configuration (symlinks). If it calls `brew install tmux` or `apt-get install tmux`, wrap that.

- [ ] **Step 3: Verify syntax**

Run: `bash -n scripts/install/05-tmux.sh`
Expected: No output

- [ ] **Step 4: Commit**

```bash
git add scripts/install/05-tmux.sh
git commit -m "feat(install): add fast-path checks to 05-tmux"
```

---

## Task 6: Integration test

**Files:**
- Test: `scripts/install/07-tools.sh`

- [ ] **Step 1: Run install script with existing tools**

Run a subset of the install to verify fast-path works:

```bash
# This should skip instantly for already-installed tools
./install.sh --skip-packages
# or target a specific module
```

Expected: Tools that are already installed show "already installed, skipping" within milliseconds.

- [ ] **Step 2: Test error path (simulate missing dependency)**

```bash
# Temporarily rename npm to test error path
mv /usr/local/bin/npm /tmp/npm.bak 2>/dev/null || sudo mv /usr/local/bin/npm /tmp/npm.bak

# Run install — should fail with clear message
./install.sh --skip-packages

# Restore
mv /tmp/npm.bak /usr/local/bin/npm 2>/dev/null || sudo mv /tmp/npm.bak /usr/local/bin/npm
```

Expected: Clear error message about missing npm, not a cryptic npm error.

- [ ] **Step 3: Commit**

```bash
git add -m "test: verify install improvements work correctly"
```

---

## Spec Coverage Check

| Spec Requirement | Task |
|------------------|------|
| Fast-path pre-check | Task 1, 2, 3, 4, 5 |
| Dependency pre-flight | Task 2 (check_tools_dependencies) |
| Parallel installs | Task 2 (install_tools) |
| Rich error context | Task 2 (all install functions) |
| Idempotency (cc-switch "already exists") | Task 2 (install_cc_switch) |

All spec requirements covered.

---

**Plan complete and saved to `docs/superpowers/plans/2026-04-14-dotfiles-improvements.md`.**

Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
