#!/usr/bin/env bash
# scripts/lib/log.sh
# Colored logging and dry-run command wrapper

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

run_cmd() {
    if [ "${DRY_RUN:-0}" = "1" ]; then
        info "[DRY-RUN] $*"
        return 0
    fi
    "$@"
}
