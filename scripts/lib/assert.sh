#!/usr/bin/env bash
# scripts/lib/assert.sh
# Command existence checks

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

needs_install() {
    command -v "$1" >/dev/null 2>&1 && return 1
    return 0
}
