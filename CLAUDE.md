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
./install.sh                                              # Run after bootstrap
```

> Modern tool usage (eza/bat/fd/rg/dust/duf/procs/btm): see `docs/tools-cheatsheet.md`

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

### Modern Tool Aliases
- Modern tools (eza/bat/fd/rg/dust/duf/procs/btm) **do not** alias over system commands — `ps`, `grep`, `top`, `cat`, `find`, `du`, `df`, `less`, `ls` all invoke the system binary
- Rationale: preserve muscle memory and avoid flag/output drift between scripts and interactive use
- Only `l`/`ll`/`llm`/`la`/`lx`/`lt`/`llt` are kept as `eza` short aliases (new names, not replacements), guarded by `command -v eza`
- User-facing reference: `docs/tools-cheatsheet.md`
- When adding a new tool: register it in `scripts/tools/<name>.sh`; **do not** add an alias in `shell/aliases.zsh` that shadows a system binary

### Key Directories
- `shell/` — Zsh configuration (zshrc, aliases.zsh, exports.zsh, utils.sh)
- `git/` — Git configuration (gitconfig, gitconfig.local)
- `config/` — Application configs (p10k.zsh, lazygit.yml, lazydocker.yml)
- `tmux/` — Tmux configuration (tmux.conf)
- `tig/` — Tig configuration (tigrc, tigrc.theme)
- `scripts/lib/` — Shared function library
- `scripts/tools/` — Tool install scripts (one per tool)
- `scripts/configs/` — Declarative config mappings
- `scripts/tests/` — bats-core tests
- `test/` — bats-core, bats-support, bats-assert submodules
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
- `git/gitconfig.local` — Environment-specific git settings (gitignored; holds enterprise configs like Gerrit URL, LFS, `sslVerify`)

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

### Modern CLI Tools
The installed modern tools (eza, bat, fd, rg, dust, duf, procs, btm) **do not** replace system commands. Call them by their real names. See `docs/tools-cheatsheet.md` for the mapping.
