#!/usr/bin/env bash
# scripts/tools/claude-code.sh
TOOL_NAME="claude-code"

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
