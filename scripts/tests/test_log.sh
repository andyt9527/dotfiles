#!/usr/bin/env bats
# scripts/tests/test_log.sh

setup() {
    load helpers/test_helper
    DRY_RUN=0
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
}

@test "info prints [INFO] prefix" {
    run info "test message"
    [[ "$output" == *"[INFO]"*"test message"* ]]
}

@test "success prints [OK] prefix" {
    run success "done"
    [[ "$output" == *"[OK]"*"done"* ]]
}

@test "warning prints [WARN] prefix" {
    run warning "careful"
    [[ "$output" == *"[WARN]"*"careful"* ]]
}

@test "error prints [ERROR] prefix" {
    run error "broke"
    [[ "$output" == *"[ERROR]"*"broke"* ]]
}

@test "run_cmd executes command when DRY_RUN=0" {
    run run_cmd echo "hello"
    [ "$output" = "hello" ]
    [ "$status" -eq 0 ]
}

@test "run_cmd prints [DRY-RUN] and does not execute when DRY_RUN=1" {
    DRY_RUN=1
    run run_cmd echo "hello"
    [[ "$output" == *"[DRY-RUN]"* ]]
    # Command is NOT executed — output should be the DRY-RUN line, not bare "hello"
    [ "$output" != "hello" ]
}

@test "run_cmd returns 0 in dry-run mode even for failing commands" {
    DRY_RUN=1
    run run_cmd false
    [ "$status" -eq 0 ]
}
