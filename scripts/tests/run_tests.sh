#!/usr/bin/env bash
# scripts/tests/run_tests.sh
set -e

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Running bats tests..."
"$TEST_DIR/../../test/bats/bin/bats" "$TEST_DIR"/test_*.sh "$@"
