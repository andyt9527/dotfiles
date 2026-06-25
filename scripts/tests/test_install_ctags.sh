#!/usr/bin/env bats
# scripts/tests/test_install_ctags.sh

setup() {
    load helpers/test_helper
}

# Extract the ctags build block from install.sh for analysis.
# The block starts at "Installing Universal Ctags from source" and ends
# at the next closing brace or the success/warning check.
_ctags_block() {
    sed -n '/Installing Universal Ctags from source/,/^    success "Universal Ctags installed"/p' \
        "$DOTFILES_TEST_PROJECT_DIR/install.sh"
}

@test "ctags build block wraps rm -rf in run_cmd" {
    local offending
    offending=$(_ctags_block | grep -E '^[[:space:]]*rm -rf' | grep -v 'run_cmd' || true)
    [ -z "$offending" ]
}

@test "ctags build block wraps autogen.sh in run_cmd" {
    local offending
    offending=$(_ctags_block | grep -E 'autogen\.sh' | grep -v 'run_cmd' || true)
    [ -z "$offending" ]
}

@test "ctags build block wraps configure in run_cmd" {
    local offending
    offending=$(_ctags_block | grep -E '\./configure' | grep -v 'run_cmd' || true)
    [ -z "$offending" ]
}

@test "ctags build block wraps make in run_cmd" {
    local offending
    offending=$(_ctags_block | grep -E '^[[:space:]]*make($|[[:space:]])' | grep -v 'run_cmd' || true)
    [ -z "$offending" ]
}

@test "ctags build block does not use unguarded cd" {
    # cd inside a subshell is fine; bare cd at function scope is the leak.
    # Anchor to exactly 4 spaces (function-body indent) so a deeper-indented
    # cd inside a ( ... ) subshell is not flagged.
    local offending
    offending=$(_ctags_block | grep -E '^    cd /tmp/ctags' | grep -v 'run_cmd' || true)
    [ -z "$offending" ]
}
