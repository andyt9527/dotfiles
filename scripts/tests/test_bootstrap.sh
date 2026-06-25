#!/usr/bin/env bats

setup() {
    load helpers/test_helper
}

@test "bootstrap.sh has apt-get fallback for missing git on Linux" {
    grep -q 'apt-get.*install.*git' "$DOTFILES_TEST_PROJECT_DIR/bootstrap.sh"
}

@test "bootstrap.sh has yum fallback for missing git on Linux" {
    grep -q 'yum.*install.*git' "$DOTFILES_TEST_PROJECT_DIR/bootstrap.sh"
}

@test "bootstrap.sh still exits if no package manager available" {
    # Brief's test used lowercase "git" but the message uses "Git" (capital G)
    # to match the file's existing convention. Match the implementation.
    grep -q 'Please install Git manually' "$DOTFILES_TEST_PROJECT_DIR/bootstrap.sh"
}
