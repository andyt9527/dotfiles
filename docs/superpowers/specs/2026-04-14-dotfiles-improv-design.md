# Dotfiles Improvements Design

**Date:** 2026-04-14
**Status:** Approved

## Goals

Improve the dotfiles install script across four dimensions:
- **Reliability:** Idempotent installs that skip already-present tools
- **Performance:** Fast-path pre-checks avoid unnecessary package manager lookups
- **Parallelization:** Independent tool installs run concurrently
- **Error clarity:** Rich context when failures occur

## 1. Fast-Path Pre-Check

Add `needs_install()` helper to `scripts/utils.sh`:

```bash
needs_install() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 && return 1
  return 0
}
```

Each install function wraps with:

```bash
install_lazygit() {
  if ! needs_install lazygit; then
    info "lazygit already available"
    return
  fi
  # ... actual install
}
```

This skips already-installed tools instantly — no brew/apt lookup at all.

## 2. Dependency Pre-Flight

Add `check_dependencies()` and per-module dependency checks:

```bash
# In 07-tools.sh
TOOLS_DEPS=(npm)

check_tools_dependencies() {
  for dep in "${TOOLS_DEPS[@]}"; do
    command -v "$dep" >/dev/null 2>&1 || {
      error "Missing $dep — required for tools installation"
      info "Install node/npm to continue"
      return 1
    }
  done
}
```

Run `check_tools_dependencies` at the start of `install_tools()` before any install attempt.

## 3. Parallel Installs for Independent Tools

In `07-tools.sh`, run independent tool installs concurrently:

```bash
install_tools() {
  check_tools_dependencies || return 1

  install_lazygit &
  install_lazydocker &
  install_cc_switch &
  wait

  install_claude_code  # requires npm, run sequentially
  install_codex        # requires npm, run sequentially
}
```

Note: `claude_code` and `codex` via npm are sequential since they share `npm`.

## 4. Rich Error Context

Replace bare `error()` calls with contextual ones:

```bash
# Before
error "npm is required to install Claude Code"

# After
error "npm is required for Claude Code installation"
info "Install node via: brew install node (macOS) or sudo apt install nodejs (Linux)"
```

For failed commands:

```bash
install_claude_code() {
  if ! needs_install claude; then
    info "Claude Code already installed"
    return
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
}
```

## 5. Module Structure

Each install module follows this pattern:

```bash
# 1. Dependencies
TOOLS_DEPS=(npm)

# 2. Pre-flight check
check_tools_dependencies() { ... }

# 3. Main install (calls pre-flight, parallel where safe)
install_tools() { ... }

# 4. Individual installers (fast-path + error context)
install_lazygit() { ... }
install_lazydocker() { ... }
# etc.
```

## Files to Modify

- `scripts/utils.sh` — Add `needs_install()` helper
- `scripts/install/07-tools.sh` — Apply all four improvements
- Other modules in `scripts/install/` — Apply fast-path checks incrementally

## Scope

This design does NOT include:
- Dry-run mode
- Task runner / Makefile
- Separate `check` and `install` commands

These can be considered in a future iteration if needed.
