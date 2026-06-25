# Shell Hardcoded Paths + Minor Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove hardcoded `/Users/andy/` and `/home/andy/` paths from shell configs (cluster A) and clean up minor audit findings (cluster E), with full TDD test coverage.

**Architecture:** Inline replacement: `/Users/andy/` → `$HOME` (macOS), `/home/andy/` → `$HOME` (Linux). Add `[[ -d ... ]]` / `[[ -f ... ]]` existence guards for personal tool paths. Delete the hardcoded conda block in `shell/zshrc` so `_detect_conda` in `~/.zshrc.local` becomes load-bearing. Cluster E: add `warning` to `get_arch`, add self-contained comments to `aliases.zsh`/`utils.sh`, delete empty macOS block, add git apt/yum fallback to `bootstrap.sh`.

**Tech Stack:** Bash, Zsh, bats-core tests, static grep assertions.

## Global Constraints

- **No hardcoded user paths:** After all tasks, `grep -rn '/Users/andy/\|/home/andy/' shell/` must return empty.
- **Existence guards:** Every personal tool path (jishushell, mavis, opencode, NPU toolchain, Android SDK) must be preceded by `[[ -d "$HOME/..." ]]` guard.
- **`/opt/homebrew/bin` not in PATH unguarded:** Any reference in `shell/zshrc` L265-320 or `shell/bashrc` L90-105 must either be removed or wrapped in `is_macos`.
- **`_detect_conda` becomes load-bearing:** The hardcoded conda block in `shell/zshrc` L275-288 must be deleted; conda init must come solely from `~/.zshrc.local` L46-79.
- **`shell/zshrc.local` is symlinked to `~/.zshrc.local`** (manifest `skip_existing`) — repo edits sync to user's home if no prior local file.
- **TDD:** Every task writes failing test first, then implements, then commits.
- **Test suite must pass:** After every task, `./scripts/tests/run_tests.sh` shows all green. Final count: existing 74 + new ≈ 12-15 = ~86-89.
- **Syntax check:** After every shell file change, `zsh -n` or `bash -n` must be clean.
- **Commit message style:** `<type>(<scope>): <subject>` — e.g., `fix(zshrc): replace hardcoded /Users/andy paths with $HOME + existence guards`.

---

## File Structure

- `scripts/lib/os.sh` — `get_arch` gains `warning` on unknown arch (Task 1).
- `shell/aliases.zsh` — Add self-contained comment at top (Task 1).
- `shell/utils.sh` — Add self-contained comment above `detect_os` (Task 1).
- `shell/zshrc.local` — L9-29 Linux block: replace `/home/andy/` → `$HOME`, add guards; L34-40 empty macOS block: delete (Tasks 1 + 2).
- `bootstrap.sh` — L19-22: add apt/yum fallback for missing git (Task 1).
- `shell/bashrc` — L97-104: replace `/Users/andy/` → `$HOME`, add guards, merge duplicate mavis (Task 3).
- `shell/zshrc` — L272-320: delete OpenClaw comment, delete conda hardcoded block, rewrite mamba block, add guards to jishushell/mavis/opencode, drop unguarded `/opt/homebrew/bin` (Task 4).
- `scripts/tests/test_shell_paths.sh` — NEW, static grep assertions (Task 5).
- `scripts/tests/test_os.sh` — Extend with `get_arch` warning test (Task 5).
- `scripts/tests/test_bootstrap.sh` — NEW, static grep assertions for git fallback (Task 5).

---

### Task 1: Cluster E cleanup (low risk)

**Files:**
- Modify: `scripts/lib/os.sh:21-27`
- Modify: `shell/aliases.zsh:1-5`
- Modify: `shell/utils.sh:1-13`
- Modify: `shell/zshrc.local:34-40`
- Modify: `bootstrap.sh:18-22`

**Interfaces:**
- Consumes: `warning()` from `scripts/lib/log.sh` (already defined).
- Produces: `get_arch()` now emits a warning on unknown arch before defaulting to `x86_64`. Callers unaffected (still get `x86_64`).

- [ ] **Step 1: Write failing tests**

Append to `scripts/tests/test_os.sh`:

```bash
@test "get_arch warns on unknown architecture" {
    # Source log.sh so warning() is defined
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    uname() { echo "riscv64"; }
    run get_arch
    [ "$status" -eq 0 ]
    [ "$output" = "x86_64" ]
    # Re-run capturing stderr to check warning
    output=$(get_arch 2>&1 1>/dev/null)
    [[ "$output" == *"Unknown architecture"*"riscv64"* ]]
    unset -f uname
}
```

Create `scripts/tests/test_bootstrap.sh`:

```bash
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
    grep -q 'Please install git manually' "$DOTFILES_TEST_PROJECT_DIR/bootstrap.sh"
}
```

Add to `scripts/tests/test_shell_paths.sh` (create file, will be extended in Task 5):

```bash
#!/usr/bin/env bats

setup() {
    load helpers/test_helper
}

@test "shell/aliases.zsh has self-contained comment for OSTYPE use" {
    grep -q 'self-contained' "$DOTFILES_TEST_PROJECT_DIR/shell/aliases.zsh"
}

@test "shell/utils.sh has self-contained comment or sources scripts/lib/os.sh" {
    grep -qE 'self-contained|source.*scripts/lib/os\.sh' "$DOTFILES_TEST_PROJECT_DIR/shell/utils.sh"
}

@test "shell/zshrc.local empty macOS block removed" {
    # The "if [[ "$OSTYPE" == "darwin"* ]]; then" block should not be followed by just ":"
    ! grep -A1 'if \[\[ "\$OSTYPE" == "darwin"\* \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local" | grep -q '^[[:space:]]*:'
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./test/bats/bin/bats scripts/tests/test_os.sh scripts/tests/test_bootstrap.sh scripts/tests/test_shell_paths.sh`
Expected: FAIL — new tests fail because:
- `get_arch` doesn't call `warning`
- `bootstrap.sh` has no apt/yum fallback
- `aliases.zsh` / `utils.sh` have no `self-contained` comment
- `zshrc.local` still has empty macOS block

- [ ] **Step 3: Fix `scripts/lib/os.sh` — add warning to `get_arch`**

Replace L21-27 of `scripts/lib/os.sh`:

```bash
get_arch() {
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *)
            # Log a warning so unknown archs are visible; default to x86_64
            # for forward-compat (callers expect a value, not an error).
            if command -v warning &>/dev/null; then
                warning "Unknown architecture: $arch, defaulting to x86_64"
            fi
            echo "x86_64"
            ;;
    esac
}
```

Note: `command -v warning` guard ensures no error if `log.sh` not sourced (e.g., bare `os.sh` use).

- [ ] **Step 4: Fix `shell/aliases.zsh` — add self-contained comment**

Replace L1-5 of `shell/aliases.zsh`:

```zsh
#!/usr/bin/env zsh
# =============================================================================
# Aliases Configuration
# Cross-platform Zsh Aliases for Ubuntu and macOS
#
# This file is self-contained re: OS detection — it loads early in zsh startup
# before scripts/lib/os.sh is sourced. Use $OSTYPE directly rather than
# is_macos/is_linux to avoid an implicit load-order dependency.
# =============================================================================
```

- [ ] **Step 5: Fix `shell/utils.sh` — add self-contained comment**

Replace L1-13 of `shell/utils.sh`:

```sh
#!/usr/bin/env sh
# =============================================================================
# Shell utility functions (for interactive shell use)
#
# This file is self-contained re: OS detection — it loads early in zsh startup
# before scripts/lib/os.sh is available. Re-implements detect_os locally rather
# than sourcing the lib to avoid a load-order dependency.
# =============================================================================

# Detect OS type
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        *)          echo "unknown" ;;
    esac
}
```

- [ ] **Step 6: Fix `shell/zshrc.local` — delete empty macOS block**

Delete L31-40 of `shell/zshrc.local`:

```zsh
# =============================================================================
# macOS specific configurations
# =============================================================================
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Add macOS-specific configurations here
    # Example:
    # export HOMEBREW_PREFIX="/opt/homebrew"
    # export PATH="$HOMEBREW_PREFIX/bin:$PATH"
    :
fi
```

(Leave the Linux block L6-29 and common config L42+ untouched for now — Task 2 handles Linux block.)

- [ ] **Step 7: Fix `bootstrap.sh` — add git apt/yum fallback**

Replace L18-22 of `bootstrap.sh`:

```bash
# Check prerequisites — install git if missing on Linux
if ! command -v git &>/dev/null; then
    if [ "$(uname -s)" = "Linux" ]; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get update
            sudo apt-get install -y git
        elif command -v yum &>/dev/null; then
            sudo yum install -y git
        else
            echo "Git is required but not installed, and no supported package manager (apt/yum) found. Please install Git manually." >&2
            exit 1
        fi
    else
        echo "Git is required but not installed. Please install Git manually." >&2
        exit 1
    fi
fi
```

Note: `bootstrap.sh` cannot source `scripts/lib/os.sh` (it runs before the repo is cloned), so use `uname -s` directly.

- [ ] **Step 8: Run tests to verify they pass**

Run: `./test/bats/bin/bats scripts/tests/test_os.sh scripts/tests/test_bootstrap.sh scripts/tests/test_shell_paths.sh`
Expected: PASS — all new tests green.

Then run full suite: `./scripts/tests/run_tests.sh`
Expected: All passing (previous 74 + new tests).

- [ ] **Step 9: Syntax check**

Run:
```bash
bash -n scripts/lib/os.sh
bash -n bootstrap.sh
zsh -n shell/aliases.zsh
sh  -n shell/utils.sh
zsh -n shell/zshrc.local
```
Expected: no output (clean).

- [ ] **Step 10: Commit**

```bash
git add scripts/lib/os.sh shell/aliases.zsh shell/utils.sh shell/zshrc.local bootstrap.sh \
        scripts/tests/test_os.sh scripts/tests/test_bootstrap.sh scripts/tests/test_shell_paths.sh
git commit -m "fix(cluster-e): warn on unknown arch, document self-contained OS detection, delete empty macOS block, add git apt/yum fallback in bootstrap"
```

---

### Task 2: `shell/zshrc.local` Linux block — replace `/home/andy/` with `$HOME` + guards

**Files:**
- Modify: `shell/zshrc.local:9-29`

**Interfaces:**
- Consumes: none new.
- Produces: `shell/zshrc.local` Linux block uses `$HOME` and existence guards — other shells/users don't get PATH pollution from non-existent paths.

- [ ] **Step 1: Write failing tests**

Append to `scripts/tests/test_shell_paths.sh`:

```bash
@test "shell/zshrc.local does not contain hardcoded /home/andy/ paths" {
    ! grep -n '/home/andy/' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local modules.sh source is guarded with [[ -f" {
    grep -q '\[\[ -f /etc/profile.d/modules.sh \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local NPU block is guarded with [[ -d \$HOME/NPU" {
    grep -q '\[\[ -d "\$HOME/NPU" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}

@test "shell/zshrc.local Android SDK block is guarded with [[ -d" {
    grep -q '\[\[ -d "\$HOME/andywork/sdk-android/Sdk" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc.local"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./test/bats/bin/bats scripts/tests/test_shell_paths.sh`
Expected: FAIL — the 4 new tests fail because `/home/andy/` still present, no `[[ -f` / `[[ -d` guards.

- [ ] **Step 3: Replace Linux block in `shell/zshrc.local`**

Replace L9-29 (the entire `if [[ "$OSTYPE" == "linux-gnu"* ]]; then ... fi` block) with:

```zsh
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Android SDK
    if [[ -d "$HOME/andywork/sdk-android/Sdk" ]]; then
        export ANDROID_HOME="$HOME/andywork/sdk-android/Sdk"
        export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/Sdk/build-tools/35.0.0"
    fi

    set -o nonomatch

    [[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
    #export AARCH64_GCC_CROSS_COMPILE=/opt/gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf/bin/aarch64-none-elf-

    # NPU toolchain
    if [[ -d "$HOME/NPU" ]]; then
        export LD_LIBRARY_PATH="$HOME/NPU/simulator/lib/:$LD_LIBRARY_PATH"
        export LD_LIBRARY_PATH="$HOME/NPU/opencl-tool-chain/opencl-compiler/lib:$LD_LIBRARY_PATH"
        export LD_LIBRARY_PATH="$HOME/NPU/opencl-tool-chain/opencl-debugger/lib:$LD_LIBRARY_PATH"
        export LD_LIBRARY_PATH="$HOME/NPU/c-tool-chain/c-compiler/lib:$LD_LIBRARY_PATH"
        export LD_LIBRARY_PATH="$HOME/NPU/c-tool-chain/c-debugger/lib:$LD_LIBRARY_PATH"
        #export LD_LIBRARY_PATH=/usr/local/cuda-12.1/lib64:$LD_LIBRARY_PATH

        export PATH="$PATH:$HOME/NPU/opencl-tool-chain/opencl-compiler/bin:$HOME/NPU/opencl-tool-chain/opencl-debugger/bin"
        export PATH="$PATH:$HOME/NPU/c-tool-chain/c-compiler/bin:$HOME/NPU/c-tool-chain/c-debugger/bin"
    fi

    export PATH="$PATH:$HOME/.local/bin"
    #export PATH=/usr/local/cuda-12.1/bin:$PATH
fi
```

Key changes:
- `/home/andy/` → `$HOME` everywhere
- Android SDK block wrapped in `[[ -d "$HOME/andywork/sdk-android/Sdk" ]]`
- `source /etc/profile.d/modules.sh` → `[[ -f /etc/profile.d/modules.sh ]] && source ...`
- NPU block wrapped in `[[ -d "$HOME/NPU" ]]`

- [ ] **Step 4: Run tests to verify they pass**

Run: `./test/bats/bin/bats scripts/tests/test_shell_paths.sh`
Expected: PASS — all 4 new tests green.

Run: `./scripts/tests/run_tests.sh`
Expected: all passing.

- [ ] **Step 5: Syntax check**

Run: `zsh -n shell/zshrc.local`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add shell/zshrc.local scripts/tests/test_shell_paths.sh
git commit -m "fix(zshrc.local): replace /home/andy with \$HOME and add existence guards in Linux block"
```

---

### Task 3: `shell/bashrc` — replace `/Users/andy/` with `$HOME` + guards + merge duplicate mavis

**Files:**
- Modify: `shell/bashrc:97-104`

**Interfaces:**
- Consumes: none new.
- Produces: `shell/bashrc` personal tool paths guarded.

- [ ] **Step 1: Write failing tests**

Append to `scripts/tests/test_shell_paths.sh`:

```bash
@test "shell/bashrc does not contain hardcoded /Users/andy/ paths" {
    ! grep -n '/Users/andy/' "$DOTFILES_TEST_PROJECT_DIR/shell/bashrc"
}

@test "shell/bashrc jishushell path is guarded" {
    grep -q '\[\[ -d "\$HOME/\.jishushell/bin" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/bashrc"
}

@test "shell/bashrc mavis path is guarded and not duplicated" {
    local count
    count=$(grep -c '\[\[ -d "\$HOME/\.mavis/bin" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/bashrc")
    [ "$count" -eq 1 ]
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./test/bats/bin/bats scripts/tests/test_shell_paths.sh`
Expected: FAIL — `/Users/andy/` still present, no `[[ -d` guards, mavis duplicated.

- [ ] **Step 3: Replace personal tool block in `shell/bashrc`**

Replace L97-104 of `shell/bashrc`:

```bash
# jishushell-bin-path
[[ -d "$HOME/.jishushell/bin" ]] && export PATH="$HOME/.jishushell/bin:$PATH"

# Added by MiniMax Agent / Code (merged)
[[ -d "$HOME/.mavis/bin" ]] && export PATH="$HOME/.mavis/bin:$PATH"
```

Key changes:
- `/Users/andy/` → `$HOME`
- `/opt/homebrew/bin` removed from jishushell line (Homebrew PATH handled elsewhere; not appropriate for Linux)
- Two mavis entries merged into one
- Both lines guarded with `[[ -d ... ]]`

- [ ] **Step 4: Run tests to verify they pass**

Run: `./test/bats/bin/bats scripts/tests/test_shell_paths.sh`
Expected: PASS.

Run: `./scripts/tests/run_tests.sh`
Expected: all passing.

- [ ] **Step 5: Syntax check**

Run: `bash -n shell/bashrc`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add shell/bashrc scripts/tests/test_shell_paths.sh
git commit -m "fix(bashrc): replace /Users/andy with \$HOME, add existence guards, merge duplicate mavis entries"
```

---

### Task 4: `shell/zshrc` L272-320 — delete conda block, rewrite mamba, guard personal paths

**Files:**
- Modify: `shell/zshrc:272-320`

**Interfaces:**
- Consumes: `_detect_conda` from `~/.zshrc.local` (already loaded at L270 before this block).
- Produces: conda initialization now solely driven by `_detect_conda`; `MAMBA_EXE` / `MAMBA_ROOT_PREFIX` use `$HOME` + existence guard.

- [ ] **Step 1: Write failing tests**

Append to `scripts/tests/test_shell_paths.sh`:

```bash
@test "shell/zshrc does not contain hardcoded /Users/andy/ paths" {
    ! grep -n '/Users/andy/' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc"
}

@test "shell/zshrc hardcoded conda block is removed (uses _detect_conda)" {
    ! grep -q "__conda_setup=\"\$('\/Users/andy" "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc"
}

@test "shell/zshrc mamba block uses \$HOME/miniforge3 and is guarded" {
    grep -q '\[\[ -f "\$HOME/miniforge3/bin/mamba" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc"
    grep -q 'export MAMBA_EXE="\$HOME/miniforge3/bin/mamba"' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc"
}

@test "shell/zshrc jishushell path is guarded" {
    grep -q '\[\[ -d "\$HOME/\.jishushell/bin" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc"
}

@test "shell/zshrc mavis path is guarded and not duplicated" {
    local count
    count=$(grep -c '\[\[ -d "\$HOME/\.mavis/bin" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc")
    [ "$count" -eq 1 ]
}

@test "shell/zshrc opencode path is guarded" {
    grep -q '\[\[ -d "\$HOME/\.opencode/bin" \]\]' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc"
}

@test "shell/zshrc L265-320 does not add /opt/homebrew/bin to PATH unguarded" {
    # In the Local Customizations section (L265-320), /opt/homebrew/bin must not appear unguarded
    local section
    section=$(sed -n '265,320p' "$DOTFILES_TEST_PROJECT_DIR/shell/zshrc")
    ! echo "$section" | grep -q '/opt/homebrew/bin'
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `./test/bats/bin/bats scripts/tests/test_shell_paths.sh`
Expected: FAIL — `/Users/andy/` still present, conda block still there, mamba still hardcoded, no guards, `/opt/homebrew/bin` still in L309-310.

- [ ] **Step 3: Replace `shell/zshrc` L272-320**

Replace L272-320 of `shell/zshrc` with:

```zsh
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
if [[ -f "$HOME/miniforge3/bin/mamba" ]]; then
    export MAMBA_EXE="$HOME/miniforge3/bin/mamba"
    export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__mamba_setup"
    else
        alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
    fi
    unset __mamba_setup
fi
# <<< mamba initialize <<<

# jishushell-bin-path
[[ -d "$HOME/.jishushell/bin" ]] && export PATH="$HOME/.jishushell/bin:$PATH"

# Added by MiniMax Agent / Code (merged)
[[ -d "$HOME/.mavis/bin" ]] && export PATH="$HOME/.mavis/bin:$PATH"

export PATH="$HOME/.dotnet:$PATH"

# opencode
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"
```

Key changes from original L272-320:
- L273 OpenClaw dead comment: **DELETED** entirely.
- L275-288 hardcoded conda block: **DELETED**. `_detect_conda` in `~/.zshrc.local` (sourced at L270) now drives conda init.
- L296-307 mamba block: wrapped in `[[ -f "$HOME/miniforge3/bin/mamba" ]]`, paths use `$HOME`.
- L309-310 jishushell + `/opt/homebrew/bin`: jishushell guarded with `[[ -d ... ]]`; `/opt/homebrew/bin` line dropped (Homebrew PATH handled at L127-138).
- L312-316 duplicate mavis: merged into single guarded line.
- L317 dotnet: kept as-is (already uses `$HOME`).
- L320 opencode: guarded with `[[ -d ... ]]`, path uses `$HOME`.

Note: The `# ~/.local/bin` block at L291-294 (already using `$HOME`) sits between the deleted conda block and the mamba block. After deletion it remains in place — verify line numbers in the file after edit.

- [ ] **Step 4: Run tests to verify they pass**

Run: `./test/bats/bin/bats scripts/tests/test_shell_paths.sh`
Expected: PASS — all new tests green.

Run: `./scripts/tests/run_tests.sh`
Expected: all passing.

- [ ] **Step 5: Syntax check**

Run: `zsh -n shell/zshrc`
Expected: no output.

- [ ] **Step 6: Manual verification (if on user's machine)**

Open a new zsh terminal and verify:
- `conda activate` works (proves `_detect_conda` picked up `$HOME/miniforge3`)
- `mamba --version` works if mamba installed
- `echo $PATH | tr ':' '\n' | grep -E 'jishushell|mavis|opencode'` shows only existing dirs

If conda doesn't work, check `~/.zshrc.local` is the repo symlink (`ls -la ~/.zshrc.local`) and that `$HOME/miniforge3/bin/conda` exists.

- [ ] **Step 7: Commit**

```bash
git add shell/zshrc scripts/tests/test_shell_paths.sh
git commit -m "fix(zshrc): delete hardcoded conda block, use \$HOME for mamba, guard jishushell/mavis/opencode paths"
```

---

### Task 5: Finalize `test_shell_paths.sh` and verify test count

**Files:**
- Modify: `scripts/tests/test_shell_paths.sh` (already created in Task 1, extended in Tasks 2-4 — verify final state)

**Interfaces:**
- Consumes: `test_helper.bash` for `DOTFILES_TEST_PROJECT_DIR`.
- Produces: a single static-grep test file covering all shell path invariants.

- [ ] **Step 1: Verify `test_shell_paths.sh` final contents**

Read `scripts/tests/test_shell_paths.sh` and confirm it contains all these test cases (from Tasks 1-4):
- `shell/aliases.zsh has self-contained comment for OSTYPE use`
- `shell/utils.sh has self-contained comment or sources scripts/lib/os.sh`
- `shell/zshrc.local empty macOS block removed`
- `shell/zshrc.local does not contain hardcoded /home/andy/ paths`
- `shell/zshrc.local modules.sh source is guarded with [[ -f`
- `shell/zshrc.local NPU block is guarded with [[ -d $HOME/NPU`
- `shell/zshrc.local Android SDK block is guarded with [[ -d`
- `shell/bashrc does not contain hardcoded /Users/andy/ paths`
- `shell/bashrc jishushell path is guarded`
- `shell/bashrc mavis path is guarded and not duplicated`
- `shell/zshrc does not contain hardcoded /Users/andy/ paths`
- `shell/zshrc hardcoded conda block is removed`
- `shell/zshrc mamba block uses $HOME/miniforge3 and is guarded`
- `shell/zshrc jishushell path is guarded`
- `shell/zshrc mavis path is guarded and not duplicated`
- `shell/zshrc opencode path is guarded`
- `shell/zshrc L265-320 does not add /opt/homebrew/bin to PATH unguarded`

If any are missing, add them now.

- [ ] **Step 2: Run `test_shell_paths.sh` in isolation**

Run: `./test/bats/bin/bats scripts/tests/test_shell_paths.sh`
Expected: all tests pass.

- [ ] **Step 3: Run full suite**

Run: `./scripts/tests/run_tests.sh`
Expected: all passing. Note the final count (should be 74 + ~17 new = ~91).

- [ ] **Step 4: No commit needed if no changes**

If `test_shell_paths.sh` was already complete from Tasks 1-4, no commit needed. If extended, commit:

```bash
git add scripts/tests/test_shell_paths.sh
git commit -m "test(shell-paths): finalize static grep assertions for shell path invariants"
```

---

### Task 6: Final verification

**Files:** none modified — verification only.

- [ ] **Step 1: Full test suite**

Run: `./scripts/tests/run_tests.sh`
Expected: all passing, exit 0.

- [ ] **Step 2: Syntax checks**

Run:
```bash
bash -n scripts/lib/os.sh
bash -n bootstrap.sh
bash -n shell/bashrc
sh  -n shell/utils.sh
zsh -n shell/aliases.zsh
zsh -n shell/zshrc
zsh -n shell/zshrc.local
```
Expected: no output from any.

- [ ] **Step 3: Hardcoded path sweep**

Run: `grep -rn '/Users/andy/\|/home/andy/' shell/`
Expected: empty output.

Run: `grep -rn '/Users/andy/' shell/ scripts/ install.sh uninstall.sh bootstrap.sh 2>/dev/null`
Expected: empty output (full repo sweep).

- [ ] **Step 4: Dry-run install**

Run: `./install.sh --dry-run`
Expected: no new errors, ctags step skipped (already verified in prior B+C+D work).

- [ ] **Step 5: Commit log**

Run: `git log --oneline -7`
Expected: 5 fix commits + 1 spec commit + 1 plan commit visible, in correct order.

- [ ] **Step 6: Manual zsh verification (if on user's machine)**

Open a new zsh terminal. Verify:
- `conda activate` works (or prints "conda not found" cleanly if miniforge3 absent)
- `mamba --version` works if installed
- `echo $PATH` does not contain nonexistent directories
- No errors on startup

If all pass, Task 6 complete. No commit (verification only).
