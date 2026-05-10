#!/usr/bin/env bash
# scripts/tools/codex.sh
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
