# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform dotfiles repository for Ubuntu and macOS featuring Oh My Zsh with Powerlevel10k theme. Provides automated installation and configuration of shell environments, terminal tools, and editors.

## Common Commands

### Installation
```bash
./install.sh                     # Full installation (default — all optional tools)
./install.sh --with-all          # Explicitly enable all optional tools
./install.sh --with-lazygit      # Enable individual optional tools (--with-modern-tools, --with-cc-switch, etc.)
./install.sh --skip-packages     # Skip packages + all TUI/CLI tools
./install.sh --skip-ohmyzsh      # Skip Oh My Zsh installation
./install.sh --skip-p10k         # Skip Powerlevel10k installation
./install.sh --help              # Show all options
```

> **Note:** There are no `--without-*` flags. To skip individual tools, edit `install.sh` and set the corresponding `INSTALL_*` variable to `false`.

### Bootstrap (new machine)
```bash
curl -fsSL https://raw.githubusercontent.com/andyt9527/dotfiles/main/bootstrap.sh | bash
```

### Update
```bash
./scripts/update.sh              # Update all plugins and dotfiles
```

### Uninstall
```bash
./uninstall.sh                   # Remove dotfiles and restore backups
```

### Verification (during development)
```bash
./install.sh --help
bash -n install.sh
bash -n scripts/utils.sh
bash -n scripts/install/*.sh
zsh -n shell/zshrc
```

## Architecture

### Modular Installation Scripts
`scripts/install/` scripts are sourced in order and can be skipped via `--skip-*` flags:
- `01-prerequisites.sh` — git, curl, wget, node
- `02-packages.sh` — tmux, vim, git, tig, tree, universal-ctags
- `03-modern-tools.sh` — fd, bat, eza, zoxide, fzf, ripgrep, duf, dust, procs, bottom
- `04-shell.sh` — Oh My Zsh + Powerlevel10k
- `05-tmux.sh` — Tmux + TPM
- `06-vim.sh` — space-vim (git submodule)
- `07-tools.sh` — lazygit, lazydocker, claude, codex, cc-switch
- `08-configs.sh` — Symlink all config files

**Important:** `main()` in `install.sh` calls individual tool functions (`install_lazygit`, `install_lazydocker`, etc.). The `install_tools()` wrapper inside `07-tools.sh` exists for organizational purposes but is **not** invoked by `main()`.

### Key Directories
- `shell/` — Zsh configuration (zshrc, aliases.zsh, exports.zsh, utils.sh)
- `config/` — Application configs (p10k.zsh, lazygit.yml, lazydocker.yml)
- `scripts/utils.sh` — Cross-platform utilities (colors, package checks); sources `shell/utils.sh` for OS detection and command checks
- `docs/superpowers/` — Design specs and implementation plans

### Cross-Platform Patterns
- `$OS` variable (set by `detect_os()`) controls platform-specific behavior: `macos` or `linux`
- `needs_install(cmd)` — fast-path helper: returns `0` if `cmd` is missing, `1` if present
- `brew_package_installed(pkg)` / `apt_package_installed(pkg)` check installed packages
- `check_command()` / `command_exists()` verify command availability
- Linux ARM64 supported for lazygit, cc-switch

### Linux-Specific Tool Handling
- `fd` is installed as `fdfind`; symlinked to `~/.local/bin/fd`
- `bat` is installed as `batcat`; symlinked to `~/.local/bin/bat`
- Rust-based tools (`eza`, `zoxide`, `dust`, `duf`, `procs`, `bottom`) install via `cargo` when available

### Installation Patterns
- **Fast-path checks:** Most installers use `needs_install` to skip already-installed tools
- **Parallel installs:** In `07-tools.sh`, lazygit, lazydocker, and cc-switch install in parallel background jobs; npm-based tools (Claude Code, Codex) install sequentially
- **Version-aware skipping:** cc-switch checks installed version against latest GitHub release and skips if up-to-date; also detects `/Applications/CC Switch.app` (DMG install)

### Local Overrides
- `~/.zshrc.local` — Zsh local settings (sourced at end of zshrc)
- `~/.p10k.zsh` — Powerlevel10k configuration (run `p10k configure` to regenerate)
- `~/.vimrc.bundle` — space-vim layer configuration
- `git/gitconfig.local` — Environment-specific git settings (included via `[include]`)

## Development & Troubleshooting

### When modifying install scripts
- Keep `set -e` safety in mind; use `return 0/1` inside functions, not `continue` (which breaks in sourced scripts)
- Fast-path pre-checks should use `needs_install` first, then package-manager checks
- For macOS brew failures, consider graceful fallbacks (e.g., `brew postinstall tmux`)

### Known platform quirks
- **tmux on macOS:** Brew install may fail; script falls back to `brew postinstall tmux`
- **Universal Ctags on Linux:** Builds from source if `ctags` is missing or not Universal Ctags
- **cc-switch on macOS:** Handles both Homebrew cask and existing DMG app installs

## Important Notes

### space-vim is a Git Submodule
Clone with `--recursive` or run `git submodule update --init --recursive`

### Universal Ctags Required
space-vim requires Universal Ctags, not BSD/exuberant ctags. On macOS: `brew install universal-ctags`. On Linux, the install script builds from source if unavailable.

### Powerlevel10k Icons
Requires Nerd Font — install via `brew install --cask font-meslo-lg-nerd-font` on macOS
