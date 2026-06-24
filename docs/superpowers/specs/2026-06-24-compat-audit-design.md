# Cross-Platform Compatibility Audit — Linux & macOS

**Date:** 2026-06-24
**Scope:** Audit-only. No code changes proposed for execution; this document records findings and suggested fix directions for future planning.
**Method:** Static review of all platform-touching code paths — `scripts/lib/`, `scripts/tools/`, install/uninstall/update scripts, `shell/`, `scripts/configs/manifest.sh`, `scripts/tests/`, `bootstrap.sh`. Cross-referenced with test output (53/53 passing) and existing memory notes.

## Summary

**16 issues found** across 11 files.

| Severity | Count | Meaning |
|---|---|---|
| Critical | 4 | Breaks on the affected platform — install/run fails or path resolution breaks |
| Important | 7 | Works in the happy path but fragile — fails on non-default configs or under `--dry-run` |
| Minor | 5 | Inconsistencies or cosmetic issues with no behavioral impact |

| Platform affected | Critical | Important | Minor |
|---|---|---|---|
| Linux | 2 | 5 | 2 |
| macOS | 0 | 1 | 1 |
| Both | 2 | 1 | 2 |

**Top affected file:** `shell/zshrc` (L273-320) — hard-coded `/Users/andy/` paths run unguarded on both platforms, breaking for any non-`andy` user and polluting Linux PATH with macOS-only entries.

## Done Well

- **Platform abstraction layer** (`scripts/lib/os.sh`) — `detect_os`/`is_macos`/`is_linux`/`get_arch`/`assert_supported_os` are clean and reusable; no hard-coded paths.
- **Tool registry** — 17 tool install scripts consistently branch on `is_macos`/`is_linux`.
- **Linux naming quirks** — `bat.sh`/`fd.sh` correctly handle `batcat`/`fdfind` and symlink to `~/.local/bin/{bat,fd}`.
- **Rust tools on Linux** — `bottom.sh`/`dust.sh`/`duf.sh`/`eza.sh`/`procs.sh` use `cargo` with a fallback warning when unavailable.
- **Config manifest** — `lazygit.yml` and `lazydocker.yml` correctly split: `~/Library/Application Support/...` for macOS, `~/.config/...` for Linux.
- **Tests** — mock `OS` and `uname`, exercise both platform branches, no skips. `test_manifest.sh` asserts both macOS and Linux lazygit entries exist. 53/53 passing.
- **Homebrew bootstrap** in `install.sh` correctly handles Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) Macs.

## Findings

### `scripts/lib/package.sh`

- **L59-92** — `install_packages_batch` only supports `apt` on Linux, despite `install_package` (L36-57) supporting `yum`/`pacman`. The batch function is what `install_prerequisites`/`install_core_packages` actually call, so installs fail on Fedora/Arch. **Important, Linux.** *Suggested direction: extend the batch function to dispatch on detected package manager, mirroring `install_package`'s branch.*

### `scripts/lib/os.sh`

- **L25** — `get_arch` defaults unknown architectures to `x86_64`, masking errors on exotic CPUs (e.g., RISC-V, ppc64le). **Minor, Both.** *Suggested direction: return an error and let callers decide, or log a warning before defaulting.*

### `scripts/tools/lazygit.sh`

- **L17-18** — Asset pattern `lazygit_${arch}.tar.gz` omits the version and `_Linux_` segment that lazygit's actual release assets use (e.g. `lazygit_0.44.1_Linux_x86_64.tar.gz`). The constructed URL 404s on Linux. **Critical, Linux.** *Suggested direction: fetch the real asset name from the GitHub release API, or match the `lazygit_*_Linux_${arch}.tar.gz` pattern.*
- **L21** — `sudo install lazygit /usr/local/bin` assumes `/usr/local/bin` exists. **Minor, Linux.** *Suggested direction: `mkdir -p` or use `~/.local/bin`.*

### `scripts/tools/cc-switch.sh`

- **L53** — `CC-Switch-${latest_tag}-Linux-${arch}.deb` uses `get_arch`, which returns `aarch64` on ARM. If cc-switch's asset uses `arm64` (common convention), download breaks. **Important, Linux aarch64.** *Suggested direction: verify against actual release assets and remap `aarch64` → `arm64` if needed.*

### `scripts/tools/fzf.sh`

- **L11-17** — On macOS, runs `brew install fzf` AND unconditionally clones `~/.fzf` + runs `~/.fzf/install` → duplicate install. The `if is_macos` only guards the brew line; the clone block is unguarded and there is no `elif is_linux`. **Important, macOS.** *Suggested direction: `if is_macos; then brew...; elif is_linux; then clone...; fi` — brew and the git clone are alternatives, not additive.*

### `install.sh`

- **L234-238** — `rm -rf /tmp/ctags`, `cd /tmp/ctags`, `./autogen.sh && ./configure --prefix=/usr/local && make` are NOT wrapped in `run_cmd`, so they execute even under `--dry-run`. Only `sudo make install` is wrapped. **Important, Both.** *Suggested direction: wrap all side-effect steps in `run_cmd`, consistent with the rest of the dry-run discipline.*
- **L177-181** — Homebrew bootstrap correctly handles Apple Silicon and Intel Macs. Done well.

### `bootstrap.sh`

- **L19-22** — Requires git pre-installed and bails if absent. Fresh Ubuntu Server images don't have git. No `apt-get install git` fallback. **Minor, Linux.** *Suggested direction: detect package manager and offer to install git, or print instructions.*

### `shell/zshrc`

- **L273-320** — Hard-coded `/Users/andy/` paths, unguarded, run on BOTH platforms: conda (L277, L281-284), mamba (L298-299), jishushell (L310), mavis (L313, L316), opencode (L320). Breaks for any non-`andy` user on macOS and adds nonexistent dirs to PATH on Linux. **Critical, Both.** *Suggested direction: guard each block with existence checks (`[[ -d /path ]] &&`), use `$HOME` instead of `/Users/andy`, and add `is_macos`/`is_linux` guards where the tool is platform-specific.*
- **L275-288** — Hard-coded conda block runs before `zshrc.local`'s auto-detecting `_detect_conda` (L49-62), making that cross-platform detection dead code. **Important, Both.** *Suggested direction: delete the hard-coded block and rely on the `_detect_conda` function, or move the hard-coded block into a user-local override.*
- **L310** — Hard-codes `/opt/homebrew/bin` into PATH for ALL platforms (no `is_macos` guard), polluting Linux PATH. **Important, Linux.** *Suggested direction: wrap in `is_macos` or remove (Homebrew PATH is already handled at L127-138).*

### `shell/zshrc.local`

- **L10-11, L18-26** — Hard-coded `/home/andy/` paths (Android SDK, NPU toolchains) inside the Linux block. Breaks for any Linux user not named `andy`. **Critical, Linux.** *Suggested direction: use `$HOME` or env vars (`$ANDROID_HOME` already referenced elsewhere).*
- **L15** — Unguarded `source /etc/profile.d/modules.sh` — file doesn't exist on default Ubuntu Desktop/Server (it's an environment-modules thing). **Important, Linux.** *Suggested direction: `[[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh`.*
- **L34-40** — macOS block is empty (just `:`). **Minor, macOS.** *Suggested direction: remove the empty block or document why it's intentional.*

### `shell/bashrc`

- **L98-104** — Hard-coded `/Users/andy/.jishushell/bin`, `/opt/homebrew/bin`, `/Users/andy/.mavis/bin` unguarded by any OS check. **Critical, Both.** *Suggested direction: add existence checks and `is_macos` guards, mirroring the pattern in `shell/zshrc`.*

### `shell/aliases.zsh`

- **L95, L124** — Uses `$OSTYPE` checks while the rest of the codebase uses `is_macos`/`is_linux`. Functionally fine but inconsistent with the lib abstraction. **Minor, Both.** *Suggested direction: source `scripts/lib/os.sh` and use `is_macos`/`is_linux` for consistency, or document that `aliases.zsh` intentionally stays self-contained.*

### `shell/utils.sh`

- Defines its own `detect_os` (L7-13), duplicating `scripts/lib/os.sh`. **Minor, Both.** *Suggested direction: source `scripts/lib/os.sh` instead of re-implementing, or document why `utils.sh` stays self-contained (e.g. loaded before the lib path is resolved).*

## Recommended Priority (if future work follows)

1. **Critical first** — hard-coded `/Users/andy/` and `/home/andy/` paths in `zshrc`/`zshrc.local`/`bashrc`. These break for any other user and are the highest-blast-radius issue. Single-PR scope: replace with `$HOME` + existence checks + OS guards.
2. **Critical #2** — `lazygit.sh` Linux asset pattern. Quick fix, unblocks Linux installs of lazygit.
3. **Important cluster** — `package.sh` batch function (yum/pacman), `fzf.sh` macOS double-install, `install.sh` ctags dry-run leak, `zshrc.local` modules.sh source. Each is a small, focused PR.
4. **Important #5** — `cc-switch.sh` aarch64 asset name verification. Needs a live check against release assets before committing to a remap.
5. **Minor** — `get_arch` default, `OSTYPE` inconsistency, `utils.sh` duplication, empty macOS block. Batch into a single cleanup PR or skip.

## Non-Goals

- This document does NOT propose code changes for execution.
- This document does NOT prescribe exact diff content — suggested directions are one-line hints, not implementations.
- This document does NOT block on verifying cc-switch's actual asset naming (flagged for future investigation).
