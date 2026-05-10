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
