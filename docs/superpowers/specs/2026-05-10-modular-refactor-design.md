# Dotfiles Modular Refactor Design

**Date:** 2026-05-10
**Status:** Draft

## Problem

The dotfiles install scripts have accumulated technical debt:

1. **Cross-platform inconsistencies:** `uninstall.sh` uses `$OSTYPE` while all other scripts use `$OS`; unsupported platforms silently do nothing instead of warning; architecture detection (`uname -m`) is duplicated in `07-tools.sh`.
2. **Code duplication:** brew/apt install loops copy-pasted 5+ times across 3 scripts; ~30 lines of ctags build-from-source duplicated verbatim in `02-packages.sh`; `command_exists()` and `check_command()` are functionally identical; `install_package_if_needed()` exists but is never called.
3. **Modularity gaps:** `07-tools.sh` is 308 lines covering 5 unrelated tools; adding a new tool requires editing 4-5 files (`install.sh`, the tool script, `08-configs.sh`, `uninstall.sh`, possibly `update.sh`); symlink config is ad-hoc with a divergent list in `uninstall.sh`.
4. **No testability:** zero test infrastructure; scripts are sourced (not executed) and cannot run in isolation; no dry-run mode.

## Design Decision

**Approach: Tool Registry + Platform Abstraction Layer** (Option A)

Structural reorganization with a tool-per-file convention, shared function library, declarative config manifest, and bats testing framework. No backward compatibility required.

## Architecture

### Directory Structure

```
scripts/
  lib/                        # Shared function library (each file independently sourceable/testable)
    os.sh                     # detect_os(), is_macos(), is_linux(), get_arch(), assert_supported_os()
    package.sh                # install_package(), install_packages_batch(), package_installed()
    log.sh                    # info(), success(), warning(), error()
    symlink.sh                # link_config(), backup_file()
    github.sh                 # get_latest_release_tag(), download_github_release()
    assert.sh                 # needs_install(), command_exists()

  tools/                      # One file per tool, convention over configuration
    _template.sh              # Template for new tools
    fd.sh, bat.sh, eza.sh, zoxide.sh, fzf.sh, ripgrep.sh
    duf.sh, dust.sh, procs.sh, bottom.sh
    lazygit.sh, lazydocker.sh, claude-code.sh, codex.sh, cc-switch.sh
    tmux.sh                   # Includes TPM
    vim.sh                    # Includes space-vim submodule

  configs/
    manifest.sh               # Declarative symlink config (shared by install + uninstall)

  tests/                      # bats-core tests
    helpers/test_helper.bash
    test_os.sh
    test_package.sh
    test_symlink.sh
    test_github.sh
    test_manifest.sh
    test_install_cli.sh

install.sh                    # Main entry: scans tools/, calls by phase
uninstall.sh                  # Rewritten to use manifest.sh
scripts/update.sh             # Uses lib/ functions
```

### Platform Abstraction Layer (`lib/`)

**`lib/os.sh`** -- Unified OS detection:
- `detect_os()` returns `"macos"` | `"linux"` | `"unsupported"`
- `is_macos()` / `is_linux()` shorthand tests
- `get_arch()` maps `uname -m` to `x86_64` | `aarch64` (unifying arm64/aarch64)
- `assert_supported_os()` exits with error on unsupported platforms

**`lib/package.sh`** -- Unified package management:
- `install_package <pkg>` routes to brew / apt-get / yum / pacman
- `install_packages_batch <pkg1> <pkg2>...` handles "skip if installed" loop internally
- `package_installed <pkg>` cross-platform check
- Eliminates 5+ duplicated brew/apt install loops

**`lib/log.sh`** -- Unified logging:
- `info()`, `success()`, `warning()`, `error()` with consistent colors
- Replaces duplicate definitions in `scripts/utils.sh` and `space-vim/install.sh`

**`lib/symlink.sh`** -- Config linking:
- `link_config <source_relative> <target_absolute>` handles backup + symlink
- `backup_file <path>` shared backup logic

**`lib/github.sh`** -- GitHub Release downloads:
- `get_latest_release_tag <repo>` fetches latest tag via GitHub API
- `download_github_release <repo> <asset_pattern> <output_path>` downloads and extracts
- Eliminates duplicated download logic across lazygit, lazydocker, cc-switch

**`lib/assert.sh`** -- Command checks:
- `needs_install <cmd>` returns 0 if command is missing
- `command_exists <cmd>` returns 0 if command exists
- Merges the two existing identical functions (`command_exists` and `check_command`)

### Tool File Convention

Each file in `scripts/tools/` follows this pattern:

```bash
#!/usr/bin/env bash
# tools/lazygit.sh
TOOL_NAME="lazygit"

install_lazygit() {
  if ! needs_install "$TOOL_NAME"; then
    info "$TOOL_NAME already installed, skipping"
    return 0
  fi

  if is_macos; then
    run_cmd brew install lazygit && success "$TOOL_NAME installed"
  elif is_linux; then
    local arch
    arch=$(get_arch)
    download_github_release "jesseduffield/lazygit" "lazygit_${arch}.tar.gz" /tmp/lazygit.tar.gz
    run_cmd tar xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
    success "$TOOL_NAME installed"
  fi
}
```

Adding a new tool: copy `_template.sh`, edit install function, done. No need to touch `install.sh`, `uninstall.sh`, or any other file.

### Config Manifest

`scripts/configs/manifest.sh` is the single source of truth for config file mappings:

```bash
# Format: "source_relative|target|platform[:flags]"
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

Both `install.sh` (link_all_configs) and `uninstall.sh` read from this manifest. Platform field handles macOS/Linux config path differences. `skip_existing` flag handles conditional links (e.g., `zshrc.local`).

### Install Flow

```bash
main() {
  source_all_libs
  parse_args "$@"
  assert_supported_os

  # Phase 1: Base environment (functions defined in install.sh, not tool files)
  install_prerequisites        # git, curl, wget, node
  install_core_packages        # tmux, vim, tig, tree, ctags

  # Phase 2: Tools (on demand)
  for tool in $ENABLED_TOOLS; do
    "install_${tool}"
  done

  # Phase 3: Shell and editors
  install_ohmyzsh
  install_powerlevel10k
  install_fzf_integration

  # Phase 4: Config symlinks
  link_all_configs             # Reads manifest.sh
}
```

Tools are auto-discovered from `scripts/tools/`. The `$ENABLED_TOOLS` list is built from CLI args.

### New CLI Interface

```bash
./install.sh                     # Install everything
./install.sh --tools fd,bat,eza  # Install only specified tools
./install.sh --skip-tools procs  # Skip specified tools
./install.sh --list-tools        # List all available tools
./install.sh --dry-run           # Show what would be done without executing
./install.sh --help              # Show usage
```

Replaces the current `--with-*` / `--skip-*` flags.

### Uninstall Rewrite

- Sources `configs/manifest.sh`
- Iterates `CONFIGS` array in reverse (remove symlinks, restore backups)
- Uses `$OS` consistently (replaces `$OSTYPE`)
- Uses `lib/` functions

### Dry-Run Mode

A `run_cmd` wrapper in `lib/log.sh`:

```bash
run_cmd() {
  if [ "$DRY_RUN" = "1" ]; then
    info "[DRY-RUN] $*"
    return 0
  fi
  "$@"
}
```

All side-effect operations (`brew install`, `apt-get install`, `ln -sf`, `tar xzf`, `git clone`) go through `run_cmd`. In dry-run mode, commands are printed but not executed.

### Testing

**Framework:** bats-core with bats-assert and bats-mock plugins.

**Scope:**
- `lib/` modules: unit tests with mocked external commands (`brew`, `apt-get`, `uname`, `curl`)
- Config manifest: parsing, platform filtering, path expansion
- CLI: argument parsing, dry-run behavior, tool listing
- Tool files: not directly tested (system-dependent), validated via dry-run

**Test structure:**
```
scripts/tests/
  helpers/test_helper.bash     # Common setup/teardown, source lib modules
  test_os.sh                   # detect_os, is_macos, is_linux, get_arch
  test_package.sh              # install_packages_batch (mock brew/apt)
  test_symlink.sh              # link_config, backup_file
  test_github.sh               # get_latest_release_tag (mock curl)
  test_manifest.sh             # Config manifest parsing, platform filtering
  test_install_cli.sh          # Arg parsing, --dry-run, --list-tools
```

**Run:** `bats scripts/tests/`

## Migration Notes

- Old `scripts/install/01-08` files are replaced entirely
- Old `scripts/utils.sh` and `shell/utils.sh` are replaced by `lib/` modules
- `shell/utils.sh` may be kept as a thin wrapper for interactive shell use (aliases, exports)
- `space-vim/install.sh` is a git submodule -- leave as-is, but `tools/vim.sh` wraps it
- Bootstrap script (`bootstrap.sh`) unchanged
- Update `CLAUDE.md` to reflect new structure after migration

## Linux-Specific Handling (Preserved)

- `fd` installed as `fdfind`, symlinked to `~/.local/bin/fd`
- `bat` installed as `batcat`, symlinked to `~/.local/bin/bat`
- Rust-based tools (`eza`, `zoxide`, `dust`, `duf`, `procs`, `bottom`) via `cargo` on Linux
- Universal Ctags built from source when unavailable
- ARM64 support for lazygit, cc-switch
