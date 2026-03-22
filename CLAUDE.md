# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Cross-platform dotfiles repository for Ubuntu and macOS featuring Oh My Zsh with Powerlevel10k theme. Provides automated installation and configuration of shell environments, terminal tools, and editors.

## Common Commands

### Installation
```bash
./install.sh                    # Basic install
./install.sh --with-all          # Full install with all optional tools
./install.sh --skip-packages     # Skip package installation
./install.sh --help              # Show all options
```

### Update
```bash
./scripts/update.sh
```

### Uninstall
```bash
./uninstall.sh
```

## Architecture

### Directory Structure
- `install.sh` - Main installer (delegates to modular scripts)
- `scripts/utils.sh` - Cross-platform utility functions (OS detection, colors, package checks)
- `scripts/install/` - Modular installation scripts (executed in order):
  - `01-prerequisites.sh` - git, curl, wget, node
  - `02-packages.sh` - tmux, vim, git, tig, tree
  - `03-modern-tools.sh` - fd, bat, eza, zoxide, fzf, ripgrep
  - `04-shell.sh` - Oh My Zsh + Powerlevel10k
  - `05-tmux.sh` - Tmux + TPM
  - `06-vim.sh` - space-vim
  - `07-tools.sh` - lazygit, lazydocker, claude, codex, cc-switch
  - `08-configs.sh` - Symlink all config files
- `shell/` - Zsh configuration (zshrc, aliases.zsh, exports.zsh, utils.sh)
- `config/default/` - Application configs (claude.json, codex.json, p10k.zsh, lazygit.yml)
- `config/personal/` - Personal overrides (not tracked in git)
- `skills/` - Claude Code and Codex CLI skills
- `git/gitconfig` - Git configuration with URL rewrites
- `tmux/tmux.conf` - Tmux configuration (Ctrl+a prefix)
- `space-vim/` - Vim distribution as Git submodule

### Installation Flow
1. `install.sh` detects OS (macOS/Linux) via `scripts/utils.sh`
2. Sources all modular scripts from `scripts/install/` in order
3. Each module handles a specific installation area
4. Modules can be skipped via `--skip-*` flags

### Cross-Platform Patterns
- `$OS` variable determines platform-specific behavior
- Package installations check if already installed before proceeding
- `brew_package_installed()` / `apt_package_installed()` for platform-specific checks
- `check_command()` for verifying command availability
- Shell-agnostic utilities in `shell/utils.sh` (sourced by both bash and zsh)

### Local Overrides
- `config/personal/claude.json` - Claude Code personal settings
- `config/personal/codex.json` - Codex CLI personal settings
- `~/.zshrc.local` - Zsh local settings (sourced at end of zshrc)
- `~/.p10k.zsh` - Powerlevel10k configuration
- `~/.vimrc.bundle` - space-vim layer configuration
- `git/gitconfig.local` - Environment-specific git settings (included via `[include]`)

## Key Features

### Shell (Zsh + Oh My Zsh + Powerlevel10k)
- Plugins: git, zsh-autosuggestions, zsh-syntax-highlighting, zsh-history-substring-search
- Platform plugins: brew/macos on macOS
- Modern aliases: eza → ls, bat → cat, fd → find, zoxide → cd
- Functions: mkcd, up, extract, ff, fs, fcd, fe, fkill

### Tmux
- Prefix: `Ctrl+a`
- Pane navigation: vim keys (h/j/k/l)
- Plugins: tmux-resurrect, tmux-continuum, tmux-yank

### Vim (space-vim)
- Leader: Space
- Key bindings: SPC f f (find files), SPC b b (buffers), SPC p s (search), SPC g s (git status)

### Git
- Aliases: lg, lol, st, co, ci, pf, pr, etc.
- URL rewrites for GitHub SSH and internal git mirrors
- LFS configuration for internal artifacts

### Claude Code & Codex CLI
- Config in `config/default/` with personal overrides in `config/personal/`
- Skills symlinked to `~/.claude/skills/` and `~/.cc-switch/skills/`
