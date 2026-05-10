# scripts/tests/helpers/test_helper.bash
# Source this in every test file via: load helpers/test_helper

# Resolve the directory of this file (works in bats)
PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"

# Load bats-support and bats-assert
load "$PROJECT_DIR/../../test/test_helper/bats-support/load"
load "$PROJECT_DIR/../../test/test_helper/bats-assert/load"

# Export project directory for tests
export DOTFILES_TEST_PROJECT_DIR="$PROJECT_DIR"
