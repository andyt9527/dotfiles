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
