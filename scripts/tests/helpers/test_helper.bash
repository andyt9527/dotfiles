# scripts/tests/helpers/test_helper.bash
# Source this in every test file via: load helpers/test_helper

# BATS_TEST_DIRNAME is the directory containing the .bats test file
# e.g. /path/to/dotfiles/scripts/tests — go up two levels to project root
PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

# Load bats-support and bats-assert
load "$PROJECT_ROOT/test/test_helper/bats-support/load"
load "$PROJECT_ROOT/test/test_helper/bats-assert/load"

# Export the project root for tests to source lib files
export DOTFILES_TEST_PROJECT_DIR="$PROJECT_ROOT"
