# Install-Flow Compat Fixes (Audit B+C+D) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 6 cross-platform install-flow bugs (1 Critical, 4 Important, 1 Minor) identified in `docs/superpowers/specs/2026-06-24-compat-audit-design.md` so `./install.sh` works on macOS, Ubuntu/Debian, Fedora, and Arch.

**Architecture:** Each fix is an independent task: write a failing bats test, fix the code, verify GREEN, commit. All new tests go into `scripts/tests/` following the existing `setup() { load helpers/test_helper; source ... }` pattern. Tool-install tests source `scripts/lib/*.sh` and override functions like `is_macos`/`is_linux`/`run_cmd`/`get_arch` to capture call arguments.

**Tech Stack:** Bash, bats-core, bats-support, bats-assert. Existing 53/53 suite must keep passing; new tests added incrementally.

## Global Constraints

- Edit only these files: `scripts/tools/lazygit.sh`, `scripts/tools/cc-switch.sh`, `scripts/tools/fzf.sh`, `install.sh`, `scripts/lib/package.sh`. New test files go under `scripts/tests/`.
- Do NOT touch `shell/`, `scripts/configs/manifest.sh`, `scripts/lib/os.sh`, `scripts/lib/symlink.sh`, `scripts/lib/log.sh`, `scripts/lib/github.sh`, `scripts/lib/assert.sh`, `bootstrap.sh`, `uninstall.sh`.
- All side-effect operations must go through `run_cmd()` so `--dry-run` works (audit Important #8).
- `install_packages_batch` must dispatch on apt/yum/pacman, mirroring `install_package` (audit Important #5).
- fzf install: macOS uses brew only; Linux prefers `apt-get install fzf`, falls back to git clone only when apt-get is unavailable.
- lazygit Linux asset filename must be `lazygit_<version-without-v>_Linux_<arch>.tar.gz` where `<arch>` is `x86_64` or `aarch64` from `get_arch`.
- cc-switch fix is conditional on verifying actual release asset naming — if assets use `aarch64`, no code change.
- Verification gate: `./scripts/tests/run_tests.sh` shows 53 + new tests all passing AND `bash -n install.sh scripts/lib/*.sh scripts/tools/*.sh` passes AND `./install.sh --dry-run` does not execute ctags build steps.
- Tests follow the existing pattern in `scripts/tests/test_package.sh` and `test_github.sh`: `setup()` loads `helpers/test_helper`, sources lib files, then individual tests override functions like `is_macos()`, `run_cmd()`, `command_exists()` to mock behavior.

---

### Task 1: Fix `scripts/tools/lazygit.sh` Linux asset filename

**Files:**
- Create: `scripts/tests/test_lazygit.sh`
- Modify: `scripts/tools/lazygit.sh:5-26` (the `install_lazygit` function)

**Interfaces:**
- Consumes (from `scripts/lib/`): `get_arch()`, `get_latest_release_tag()`, `download_github_release()`, `is_macos()`, `is_linux()`, `needs_install()`, `info()`, `success()`, `run_cmd()`.
- Produces: `install_lazygit()` constructs the asset filename as `lazygit_${version}_Linux_${arch}.tar.gz` (version with `v` prefix stripped) and passes it to `download_github_release`.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_lazygit.sh`:

```bash
#!/usr/bin/env bats
# scripts/tests/test_lazygit.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/github.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/tools/lazygit.sh"
}

@test "install_lazygit on Linux x86_64 constructs correct asset filename" {
    is_macos() { return 1; }
    is_linux() { return 0; }
    needs_install() { return 0; }
    get_arch() { echo "x86_64"; }
    get_latest_release_tag() { echo "v0.44.1"; return 0; }

    local captured_asset=""
    download_github_release() {
        captured_asset="$2"
        echo "v0.44.1"
        return 0
    }
    run_cmd() { return 0; }

    run install_lazygit
    [ "$status" -eq 0 ]
    [ "$captured_asset" = "lazygit_0.44.1_Linux_x86_64.tar.gz" ]
}

@test "install_lazygit on Linux aarch64 constructs correct asset filename" {
    is_macos() { return 1; }
    is_linux() { return 0; }
    needs_install() { return 0; }
    get_arch() { echo "aarch64"; }
    get_latest_release_tag() { echo "v0.44.1"; return 0; }

    local captured_asset=""
    download_github_release() {
        captured_asset="$2"
        echo "v0.44.1"
        return 0
    }
    run_cmd() { return 0; }

    run install_lazygit
    [ "$status" -eq 0 ]
    [ "$captured_asset" = "lazygit_0.44.1_Linux_aarch64.tar.gz" ]
}

@test "install_lazygit on macOS calls brew, not download_github_release" {
    is_macos() { return 0; }
    is_linux() { return 1; }
    needs_install() { return 0; }

    local brew_called=0
    local download_called=0
    run_cmd() {
        if [ "$1" = "brew" ] && [ "$2" = "install" ] && [ "$3" = "lazygit" ]; then
            brew_called=1
        fi
        return 0
    }
    download_github_release() { download_called=1; return 0; }

    run install_lazygit
    [ "$status" -eq 0 ]
    [ "$brew_called" -eq 1 ]
    [ "$download_called" -eq 0 ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./test/bats/bin/bats scripts/tests/test_lazygit.sh`
Expected: FAIL — the first two tests fail because `captured_asset` is `lazygit_x86_64.tar.gz` (current buggy pattern) instead of `lazygit_0.44.1_Linux_x86_64.tar.gz`. The third test may pass if `brew install lazygit` is the first `run_cmd` call, but verify.

- [ ] **Step 3: Fix the `install_lazygit` function**

Replace the entire `install_lazygit` function in `scripts/tools/lazygit.sh` with:

```bash
install_lazygit() {
    if ! needs_install lazygit; then
        info "lazygit already installed, skipping"
        return 0
    fi
    info "Installing lazygit..."
    if is_macos; then
        run_cmd brew install lazygit
    elif is_linux; then
        local arch tag version file
        arch=$(get_arch)
        tag=$(get_latest_release_tag "jesseduffield/lazygit") || return 1
        version="${tag#v}"
        file="lazygit_${version}_Linux_${arch}.tar.gz"
        if download_github_release "jesseduffield/lazygit" "$file" "/tmp/lazygit.tar.gz"; then
            run_cmd tar xf /tmp/lazygit.tar.gz lazygit
            run_cmd sudo mkdir -p /usr/local/bin
            run_cmd sudo install lazygit /usr/local/bin
            rm -f lazygit /tmp/lazygit.tar.gz
        fi
    fi
    success "lazygit installed"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./test/bats/bin/bats scripts/tests/test_lazygit.sh`
Expected: PASS — all 3 tests pass.

- [ ] **Step 5: Run full suite to verify no regression**

Run: `./scripts/tests/run_tests.sh`
Expected: 53 + 3 new tests = 56 passing.

- [ ] **Step 6: Commit**

```bash
git add scripts/tests/test_lazygit.sh scripts/tools/lazygit.sh
git commit -m "$(cat <<'EOF'
fix(lazygit): construct correct Linux asset filename with version and arch

The old pattern `lazygit_${arch}.tar.gz` omitted the version and the
`_Linux_` segment, producing a 404 URL. Fetch the tag separately, strip
the `v` prefix, and build `lazygit_<version>_Linux_<arch>.tar.gz` to
match lazygit's actual release assets. Also mkdir -p /usr/local/bin
before install in case it doesn't exist.
EOF
)"
```

---

### Task 2: Verify and fix `scripts/tools/cc-switch.sh` aarch64 asset naming

**Files:**
- Create (if fix needed): `scripts/tests/test_cc_switch.sh`
- Modify (if fix needed): `scripts/tools/cc-switch.sh:51-54` (the arch/file construction in the Linux branch)

**Interfaces:**
- Consumes: `get_arch()`, `get_latest_release_tag()`, `is_macos()`, `is_linux()`, `command_exists()`, `info()`, `error()`, `warning()`, `success()`, `run_cmd()`.
- Produces: `install_cc_switch()` constructs the .deb filename using the correct arch name (either `aarch64` or `arm64`, depending on verification result).

- [ ] **Step 1: Verify actual cc-switch release asset naming**

Run:
```bash
curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest | grep -o '"name":[[:space:]]*"[^"]*\.deb"' | head -5
```

Expected: a list of `.deb` asset names. Look for the Linux aarch64/ARM64 variant.

**Decision branch:**
- If the asset name contains `Linux_arm64.deb` → proceed to Step 2 (fix needed).
- If the asset name contains `Linux_aarch64.deb` → no fix needed. Skip to Step 5, but record the verification result in the commit message of Task 6's verification step.
- If the API call fails (no network) → mark this task as NEEDS_CONTEXT, skip the code change, and note in the progress ledger that cc-switch verification requires manual follow-up. Skip to Step 5.

- [ ] **Step 2: Write the failing test (only if Step 1 confirmed `arm64`)**

Create `scripts/tests/test_cc_switch.sh`:

```bash
#!/usr/bin/env bats
# scripts/tests/test_cc_switch.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/github.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/tools/cc-switch.sh"
}

@test "install_cc_switch on Linux aarch64 uses arm64 in asset filename" {
    is_macos() { return 1; }
    is_linux() { return 0; }
    command_exists() { return 1; }  # cc-switch not installed
    get_arch() { echo "aarch64"; }
    get_latest_release_tag() { echo "v1.2.3"; return 0; }

    local captured_url=""
    run_cmd() {
        # Capture the URL passed to curl (first arg after -fL -o file url)
        if [ "$1" = "curl" ]; then
            # args: curl -fL -o "$file" "$url"
            captured_url="${@: -1}"
        fi
        return 0
    }

    # Override the /Applications check and sudo apt-get
    [ -d "/Applications/CC Switch.app" ] && return

    run install_cc_switch
    [ "$status" -eq 0 ]
    # Verify the URL contains arm64, not aarch64
    [[ "$captured_url" == *"Linux-arm64.deb"* ]] || \
    [[ "$captured_url" == *"Linux_arm64.deb"* ]] || \
    [[ "$captured_url" == *"_arm64.deb"* ]]
}
```

Note: the exact URL pattern assertion depends on what Step 1 revealed. Adjust the `[[ ]]` conditions to match the actual asset naming. If the asset uses `CC-Switch-v1.2.3-Linux-arm64.deb`, the assertion `*"Linux-arm64.deb"*` will match.

- [ ] **Step 3: Run test to verify it fails (only if Step 2 was executed)**

Run: `./test/bats/bin/bats scripts/tests/test_cc_switch.sh`
Expected: FAIL — `captured_url` contains `aarch64` (current code), not `arm64`.

- [ ] **Step 4: Fix the arch mapping in `install_cc_switch` (only if Step 2 was executed)**

In `scripts/tools/cc-switch.sh`, find the Linux branch (around L51-54) and replace:

```bash
        local arch
        arch=$(get_arch)
        local file="CC-Switch-${latest_tag}-Linux-${arch}.deb"
```

with:

```bash
        local arch
        arch=$(get_arch)
        # cc-switch release assets use 'arm64' (Go convention), not 'aarch64'
        [[ "$arch" == "aarch64" ]] && arch="arm64"
        local file="CC-Switch-${latest_tag}-Linux-${arch}.deb"
```

- [ ] **Step 5: Run test to verify it passes (only if Step 2 was executed)**

Run: `./test/bats/bin/bats scripts/tests/test_cc_switch.sh`
Expected: PASS.

- [ ] **Step 6: Run full suite**

Run: `./scripts/tests/run_tests.sh`
Expected: 56 + 1 new test = 57 passing (if fix applied), or 56 (if no fix needed).

- [ ] **Step 7: Commit (only if fix was applied)**

```bash
git add scripts/tests/test_cc_switch.sh scripts/tools/cc-switch.sh
git commit -m "$(cat <<'EOF'
fix(cc-switch): remap aarch64 to arm64 for Linux .deb asset naming

cc-switch's release assets follow the Go convention (arm64), but
get_arch() returns 'aarch64' (uname convention). Remap before
constructing the filename so the download URL resolves.
EOF
)"
```

If no fix was needed (Step 1 confirmed `aarch64`), no commit. Record in the progress ledger: "Task 2: cc-switch assets use aarch64 — no code change, finding closed."

---

### Task 3: Fix `scripts/tools/fzf.sh` install paths

**Files:**
- Create: `scripts/tests/test_fzf.sh`
- Modify: `scripts/tools/fzf.sh:5-19` (the `install_fzf` function)

**Interfaces:**
- Consumes: `is_macos()`, `is_linux()`, `command_exists()`, `info()`, `success()`, `run_cmd()`.
- Produces: `install_fzf()` dispatches: macOS → brew only; Linux + apt-get → `sudo apt-get install -y fzf`; Linux without apt-get → git clone fallback.

- [ ] **Step 1: Write the failing test**

Create `scripts/tests/test_fzf.sh`:

```bash
#!/usr/bin/env bats
# scripts/tests/test_fzf.sh

setup() {
    load helpers/test_helper
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/log.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/assert.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/lib/os.sh"
    source "$DOTFILES_TEST_PROJECT_DIR/scripts/tools/fzf.sh"
}

@test "install_fzf skips when fzf command already exists" {
    command_exists() { [ "$1" = "fzf" ]; }
    is_macos() { return 0; }

    local run_cmd_calls=()
    run_cmd() { run_cmd_calls+=("$*"); }

    run install_fzf
    [ "$status" -eq 0 ]
    [ "${#run_cmd_calls[@]}" -eq 0 ]
}

@test "install_fzf on macOS calls brew install fzf, does not clone" {
    command_exists() { return 1; }  # fzf not installed
    [ -d "$HOME/.fzf" ] && rm -rf "$HOME/.fzf"  # ensure clean state
    is_macos() { return 0; }
    is_linux() { return 1; }

    local brew_called=0
    local clone_called=0
    run_cmd() {
        case "$1" in
            brew)
                if [ "$2" = "install" ] && [ "$3" = "fzf" ]; then
                    brew_called=1
                fi
                ;;
            git)
                if [ "$1" = "git" ] && [ "$2" = "clone" ]; then
                    clone_called=1
                fi
                ;;
        esac
        return 0
    }

    run install_fzf
    [ "$status" -eq 0 ]
    [ "$brew_called" -eq 1 ]
    [ "$clone_called" -eq 0 ]
}

@test "install_fzf on Linux with apt-get calls apt-get install, does not clone" {
    command_exists() { [ "$1" = "apt-get" ]; }  # apt-get exists, fzf does not
    [ -d "$HOME/.fzf" ] && rm -rf "$HOME/.fzf"
    is_macos() { return 1; }
    is_linux() { return 0; }

    local apt_called=0
    local clone_called=0
    run_cmd() {
        if [ "$1" = "sudo" ] && [ "$2" = "apt-get" ] && [ "$3" = "install" ]; then
            apt_called=1
        elif [ "$1" = "git" ] && [ "$2" = "clone" ]; then
            clone_called=1
        fi
        return 0
    }

    run install_fzf
    [ "$status" -eq 0 ]
    [ "$apt_called" -eq 1 ]
    [ "$clone_called" -eq 0 ]
}

@test "install_fzf on Linux without apt-get falls back to git clone" {
    command_exists() { return 1; }  # neither fzf nor apt-get
    [ -d "$HOME/.fzf" ] && rm -rf "$HOME/.fzf"
    is_macos() { return 1; }
    is_linux() { return 0; }

    local apt_called=0
    local clone_called=0
    run_cmd() {
        if [ "$1" = "sudo" ] && [ "$2" = "apt-get" ]; then
            apt_called=1
        elif [ "$1" = "git" ] && [ "$2" = "clone" ]; then
            clone_called=1
        fi
        return 0
    }

    run install_fzf
    [ "$status" -eq 0 ]
    [ "$apt_called" -eq 0 ]
    [ "$clone_called" -eq 1 ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./test/bats/bin/bats scripts/tests/test_fzf.sh`
Expected: FAIL — at least the macOS test fails because the current code clones `~/.fzf` after brew (`clone_called=1` when it should be 0). The Linux-with-apt test fails because current code clones instead of calling apt-get.

- [ ] **Step 3: Fix the `install_fzf` function**

Replace the entire `install_fzf` function in `scripts/tools/fzf.sh` with:

```bash
install_fzf() {
    if command -v fzf &>/dev/null || [ -d "$HOME/.fzf" ]; then
        info "fzf already installed, skipping"
        return 0
    fi
    info "Installing fzf..."
    if is_macos; then
        run_cmd brew install fzf
    elif is_linux; then
        if command_exists apt-get; then
            run_cmd sudo apt-get install -y fzf
        else
            # Fallback for non-Debian Linux without packaged fzf
            run_cmd git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
            run_cmd "$HOME/.fzf/install" --no-key-bindings --no-completion 2>/dev/null || true
        fi
    fi
    success "fzf installed"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./test/bats/bin/bats scripts/tests/test_fzf.sh`
Expected: PASS — all 4 tests pass.

- [ ] **Step 5: Run full suite**

Run: `./scripts/tests/run_tests.sh`
Expected: previous count + 4 new tests passing.

- [ ] **Step 6: Commit**

```bash
git add scripts/tests/test_fzf.sh scripts/tools/fzf.sh
git commit -m "$(cat <<'EOF'
fix(fzf): use brew on macOS, apt-get on Debian, clone as fallback only

The old code ran brew install AND unconditionally cloned ~/.fzf on macOS
(double install), and only supported git clone on Linux (ignoring the
apt-packaged fzf). Dispatch by platform: macOS → brew; Linux + apt-get →
sudo apt-get install -y fzf; Linux without apt-get → git clone fallback.
Also widen the already-installed check to command -v fzf so brew/apt
installs (which don't create ~/.fzf) are detected.
EOF
)"
```

---

### Task 4: Fix `install.sh` ctags dry-run leak

**Files:**
- Create: `scripts/tests/test_install_ctags.sh`
- Modify: `install.sh:234-240` (the ctags build block inside the install-universal-ctags section)

**Interfaces:**
- Consumes: `run_cmd()`, `apt_package_installed()`, `info()`, `warning()`, `success()`.
- Produces: all side-effect operations in the ctags build block go through `run_cmd()`, so `--dry-run` skips them.

- [ ] **Step 1: Write the failing test**

The ctags build logic is inlined in `install.sh` (not a separate function). The test uses a static check: grep the ctags block in install.sh and assert that every side-effect command is wrapped in `run_cmd`. This is more reliable than sourcing install.sh (which has many side effects at top level).

Create `scripts/tests/test_install_ctags.sh`:

```bash
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
    # Find lines with rm -rf — they must be prefixed by run_cmd
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
    # Match bare 'make' calls but not 'make install' which is already wrapped
    local offending
    offending=$(_ctags_block | grep -E '^[[:space:]]*make($|[[:space:]])' | grep -v 'run_cmd' || true)
    [ -z "$offending" ]
}

@test "ctags build block does not use unguarded cd" {
    # cd inside a subshell is fine; bare cd at function scope is the leak
    # Look for cd /tmp/ctags NOT inside a ( ... ) subshell — simplified check:
    # assert no bare 'cd /tmp/ctags' line exists outside of run_cmd
    local offending
    offending=$(_ctags_block | grep -E '^[[:space:]]*cd /tmp/ctags' | grep -v 'run_cmd' || true)
    [ -z "$offending" ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./test/bats/bin/bats scripts/tests/test_install_ctags.sh`
Expected: FAIL — `rm -rf`, `autogen.sh`, `./configure`, `make`, and `cd /tmp/ctags` all appear without `run_cmd` prefix in the current code.

- [ ] **Step 3: Fix the ctags build block**

In `install.sh`, find the block (around L234-240) that currently reads:

```bash
    local original_dir="$(pwd)"
    rm -rf /tmp/ctags
    run_cmd git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
    cd /tmp/ctags
    ./autogen.sh && ./configure --prefix=/usr/local && make && run_cmd sudo make install
    cd "$original_dir"
    rm -rf /tmp/ctags
```

Replace it with:

```bash
    local original_dir="$(pwd)"
    run_cmd rm -rf /tmp/ctags
    run_cmd git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
    (
        cd /tmp/ctags
        run_cmd ./autogen.sh
        run_cmd ./configure --prefix=/usr/local
        run_cmd make
        run_cmd sudo make install
    )
    cd "$original_dir"
    run_cmd rm -rf /tmp/ctags
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./test/bats/bin/bats scripts/tests/test_install_ctags.sh`
Expected: PASS — all 5 tests pass.

- [ ] **Step 5: Verify dry-run end-to-end**

Run: `./install.sh --dry-run 2>&1 | grep -E 'rm -rf /tmp/ctags|autogen|configure|make' || echo "no leakage"`
Expected: `no leakage` — under dry-run, none of these commands actually execute. The grep checks the command's stdout for real execution traces (the dry-run wrapper prints the command but does not execute it; if execution happened, autogen/configure/make would print their own output to stdout/stderr).

Note: if the grep finds lines that are just `run_cmd` echo-printing the command (dry-run preview), that's expected and not a leak. Distinguish by checking whether `./autogen.sh` actually created files — under dry-run, `/tmp/ctags/autogen.sh` output would not appear.

- [ ] **Step 6: Run full suite**

Run: `./scripts/tests/run_tests.sh`
Expected: previous count + 5 new tests passing.

- [ ] **Step 7: Commit**

```bash
git add scripts/tests/test_install_ctags.sh install.sh
git commit -m "$(cat <<'EOF'
fix(install): wrap all ctags build steps in run_cmd for dry-run safety

rm -rf /tmp/ctags, cd, ./autogen.sh, ./configure, and make were previously
executed even under --dry-run (only sudo make install was wrapped). Move
the build into a subshell to isolate the working directory and wrap each
side-effect step in run_cmd so dry-run previews without touching the
filesystem.
EOF
)"
```

---

### Task 5: Fix `scripts/lib/package.sh` batch function to support yum/pacman

**Files:**
- Modify: `scripts/tests/test_package.sh` (append new tests)
- Modify: `scripts/lib/package.sh:59-92` (the `install_packages_batch` function)

**Interfaces:**
- Consumes: `is_macos()`, `is_linux()`, `command_exists()`, `brew_package_installed()`, `apt_package_installed()`, `info()`, `success()`, `warning()`, `error()`, `run_cmd()`.
- Produces:
  - `install_packages_batch()` dispatches on apt/yum/pacman for Linux (previously apt-only).
  - New helper `_package_installed_linux(pkg, pm)` returns 0 if installed, 1 otherwise; `pm` is `apt`, `yum`, or `pacman`.

- [ ] **Step 1: Write the failing tests**

Append to `scripts/tests/test_package.sh` (after the existing last test):

```bash

# --- install_packages_batch (yum/pacman dispatch) ---

@test "install_packages_batch on Linux with yum calls yum install, not apt" {
    command_exists() {
        # apt-get missing, yum exists, pacman missing
        [ "$1" = "yum" ]
    }
    OS="linux"
    is_macos() { return 1; }
    is_linux() { return 0; }
    _package_installed_linux() { return 1; }  # nothing installed

    local yum_called=0
    local apt_called=0
    run_cmd() {
        if [ "$1" = "sudo" ] && [ "$2" = "yum" ]; then
            yum_called=1
        elif [ "$1" = "sudo" ] && [ "$2" = "apt-get" ]; then
            apt_called=1
        fi
        return 0
    }

    run install_packages_batch "pkg-a" "pkg-b"
    [ "$status" -eq 0 ]
    [ "$yum_called" -eq 1 ]
    [ "$apt_called" -eq 0 ]
}

@test "install_packages_batch on Linux with pacman calls pacman -S, not apt" {
    command_exists() {
        # apt-get and yum missing, pacman exists
        [ "$1" = "pacman" ]
    }
    OS="linux"
    is_macos() { return 1; }
    is_linux() { return 0; }
    _package_installed_linux() { return 1; }

    local pacman_called=0
    local apt_called=0
    run_cmd() {
        if [ "$1" = "sudo" ] && [ "$2" = "pacman" ]; then
            pacman_called=1
        elif [ "$1" = "sudo" ] && [ "$2" = "apt-get" ]; then
            apt_called=1
        fi
        return 0
    }

    run install_packages_batch "pkg-a"
    [ "$status" -eq 0 ]
    [ "$pacman_called" -eq 1 ]
    [ "$apt_called" -eq 0 ]
}

@test "install_packages_batch on Linux with no supported package manager returns 1" {
    command_exists() { return 1; }  # nothing exists
    OS="linux"
    is_macos() { return 1; }
    is_linux() { return 0; }

    run install_packages_batch "pkg-a"
    [ "$status" -eq 1 ]
}

@test "install_packages_batch on Linux with apt and all installed skips install" {
    command_exists() { [ "$1" = "apt-get" ]; }
    OS="linux"
    is_macos() { return 1; }
    is_linux() { return 0; }
    _package_installed_linux() { return 0; }  # all installed

    local install_called=0
    run_cmd() {
        if [ "$1" = "sudo" ] && [ "$2" = "apt-get" ] && [ "$3" = "install" ]; then
            install_called=1
        fi
        return 0
    }

    run install_packages_batch "pkg-a" "pkg-b"
    [ "$status" -eq 0 ]
    [ "$install_called" -eq 0 ]
}

# --- _package_installed_linux helper ---

@test "_package_installed_linux returns 0 for installed apt package" {
    apt_package_installed() { return 0; }
    run _package_installed_linux "git" "apt"
    [ "$status" -eq 0 ]
}

@test "_package_installed_linux returns 1 for missing yum package" {
    rpm() { return 1; }
    run _package_installed_linux "nonexistent" "yum"
    [ "$status" -eq 1 ]
}

@test "_package_installed_linux returns 0 for installed pacman package" {
    pacman() { return 0; }
    run _package_installed_linux "git" "pacman"
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `./test/bats/bin/bats scripts/tests/test_package.sh`
Expected: FAIL — the new `install_packages_batch` yum/pacman tests fail because the current function only handles apt. The `_package_installed_linux` tests fail because the function doesn't exist yet.

- [ ] **Step 3: Fix `install_packages_batch` and add `_package_installed_linux`**

In `scripts/lib/package.sh`, replace the entire `install_packages_batch` function (L59-92) with:

```bash
install_packages_batch() {
    local pkgs=("$@")
    if is_macos; then
        for pkg in "${pkgs[@]}"; do
            if brew_package_installed "$pkg"; then
                info "$pkg is already installed, skipping"
                continue
            fi
            info "Installing $pkg..."
            run_cmd brew install "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
        done
    elif is_linux; then
        local pm
        if command_exists apt-get; then
            pm="apt"
        elif command_exists yum; then
            pm="yum"
        elif command_exists pacman; then
            pm="pacman"
        else
            error "No supported package manager found (apt/yum/pacman)"
            return 1
        fi

        local needs_install=()
        for pkg in "${pkgs[@]}"; do
            if ! _package_installed_linux "$pkg" "$pm"; then
                needs_install+=("$pkg")
            else
                info "$pkg is already installed, skipping"
            fi
        done

        if [ ${#needs_install[@]} -eq 0 ]; then
            info "All packages already installed"
            return 0
        fi

        case "$pm" in
            apt)
                run_cmd sudo apt-get update
                for pkg in "${needs_install[@]}"; do
                    run_cmd sudo apt-get install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                done
                ;;
            yum)
                for pkg in "${needs_install[@]}"; do
                    run_cmd sudo yum install -y "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                done
                ;;
            pacman)
                run_cmd sudo pacman -Sy --noconfirm
                for pkg in "${needs_install[@]}"; do
                    run_cmd sudo pacman -S --noconfirm "$pkg" && success "$pkg installed" || warning "Failed to install $pkg"
                done
                ;;
        esac
    fi
}

_package_installed_linux() {
    local pkg="$1"
    local pm="$2"
    case "$pm" in
        apt)    apt_package_installed "$pkg" ;;
        yum)    rpm -q "$pkg" &>/dev/null ;;
        pacman) pacman -Q "$pkg" &>/dev/null ;;
        *)      return 1 ;;
    esac
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `./test/bats/bin/bats scripts/tests/test_package.sh`
Expected: PASS — all existing + 7 new tests pass.

- [ ] **Step 5: Run full suite**

Run: `./scripts/tests/run_tests.sh`
Expected: previous count + 7 new tests passing.

- [ ] **Step 6: Commit**

```bash
git add scripts/tests/test_package.sh scripts/lib/package.sh
git commit -m "$(cat <<'EOF'
fix(package): support yum and pacman in install_packages_batch

The batch function previously hardcoded apt on Linux, failing silently on
Fedora/Arch. Detect the package manager up front (apt/yum/pacman) and
dispatch the install loop accordingly. Extract _package_installed_linux
helper to check installed state across managers (dpkg/rpm/pacman -Q).
EOF
)"
```

---

### Task 6: Final end-to-end verification

**Files:** none modified — verification only.

- [ ] **Step 1: Confirm git history shows all fix commits**

Run: `git log --oneline -6`
Expected: commits for lazygit, cc-switch (if applied), fzf, install.sh ctags, package.sh (most recent first). Count should be 4-5 fix commits depending on cc-switch outcome.

- [ ] **Step 2: Syntax check all shell files**

Run: `bash -n install.sh scripts/lib/*.sh scripts/tools/*.sh && echo OK`
Expected: `OK` — no syntax errors.

- [ ] **Step 3: Run full test suite**

Run: `./scripts/tests/run_tests.sh`
Expected: 53 + new tests all passing (new test count: 3 lazygit + 0-1 cc-switch + 4 fzf + 5 ctags + 7 package = 19-20 new tests; total 72-73).

- [ ] **Step 4: Verify ctags dry-run is clean**

Run: `./install.sh --dry-run 2>&1 | grep -cE '^(\+|Running:|rm -rf /tmp/ctags|./autogen|./configure|make)' || true`
Expected: a small number (the dry-run preview prints commands but does not execute them). Then run: `ls /tmp/ctags 2>/dev/null && echo "LEAK" || echo "clean"`
Expected: `clean` — `/tmp/ctags` does not exist after a dry-run.

- [ ] **Step 5: Verify no files outside the allowed list were modified**

Run: `git diff --name-only <base-commit>..HEAD`
Expected: only `scripts/tests/test_lazygit.sh`, `scripts/tools/lazygit.sh`, `scripts/tests/test_cc_switch.sh` (if applied), `scripts/tools/cc-switch.sh` (if applied), `scripts/tests/test_fzf.sh`, `scripts/tools/fzf.sh`, `scripts/tests/test_install_ctags.sh`, `install.sh`, `scripts/tests/test_package.sh`, `scripts/lib/package.sh`. No `shell/`, no other lib files, no `bootstrap.sh`, no `uninstall.sh`.

- [ ] **Step 6: Done — report status to user**

No commit for verification. If any step above failed, do not claim completion; fix the underlying issue and rerun the failed step.

---

## Self-Review Notes

- **Spec coverage:**
  - Task 1 = spec Task 1 (lazygit Critical + Minor) ✓
  - Task 2 = spec Task 2 (cc-switch conditional) ✓
  - Task 3 = spec Task 3 (fzf three-platform dispatch) ✓
  - Task 4 = spec Task 4 (ctags dry-run leak) ✓
  - Task 5 = spec Task 5 (package.sh yum/pacman) ✓
  - Task 6 = spec Task 6 (final verification) ✓
- **Placeholder scan:** clean — all code blocks contain literal bash/zsh; no TBD/TODO. The cc-switch task has an explicit decision branch (Step 1) with concrete fallback paths for network failure.
- **Type consistency:** `_package_installed_linux` is used in Task 5's `install_packages_batch` and tested in Task 5's tests — same name, same signature `(pkg, pm)`. `install_lazygit`, `install_cc_switch`, `install_fzf` function names match across tests and source files. Test helper pattern (`setup() { load helpers/test_helper; source ... }`) matches existing `test_package.sh` and `test_github.sh`.
- **Test count math:** 53 existing + 3 (lazygit) + 0-1 (cc-switch) + 4 (fzf) + 5 (ctags) + 7 (package) = 72-73 total. Task 6 Step 3 reflects this range.
