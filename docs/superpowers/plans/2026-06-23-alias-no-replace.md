# Alias No-Replace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all alias-over-system-binary replacements from `shell/aliases.zsh`, keep `eza` short aliases under new (non-shadowing) names, add a tools cheatsheet, and lock the no-replacement principle in `CLAUDE.md`.

**Architecture:** Three-file edit. `shell/aliases.zsh` is sourced from `~/.zshrc` at interactive shell startup; deleting alias lines removes the shadowing on the next new shell. The cheatsheet is a plain markdown reference; `CLAUDE.md` records the principle for future maintainers.

**Tech Stack:** Zsh, Bash, Markdown. Existing bats-core test suite for regression check.

## Global Constraints

- Edit only three files: `shell/aliases.zsh`, `docs/tools-cheatsheet.md` (new), `CLAUDE.md`.
- Do NOT modify `install.sh`, `uninstall.sh`, `scripts/configs/manifest.sh`, or any `scripts/tools/*.sh`.
- The 9 alias replacements to remove: `ls`, `cat`, `less`, `find`, `grep`, `du`, `df`, `ps`, `top`/`htop`.
- Retain these `eza` short aliases (renamed-only, not shadowing): `l`, `ll`, `llm`, `la`, `lx`, `lt`, `llt`. They MUST be inside a `command -v eza` guard.
- Retain unrelated aliases unchanged: `python=python3`, `dus`/`dud` (use system `du`), all git/tmux/navigation/editor aliases, and all macOS/Linux platform sections.
- Verification gate: `zsh -n shell/aliases.zsh` passes AND `./scripts/tests/run_tests.sh` continues to show 53/53 passing.

---

### Task 1: Rewrite `shell/aliases.zsh` to remove replacement aliases

**Files:**
- Modify: `shell/aliases.zsh` (delete lines 27-111 of the current file's "Listing", "File Viewing", and "File System" sections; insert new "Modern Tool Short Aliases" block)

**Interfaces:**
- Consumes: nothing (root task)
- Produces: an `aliases.zsh` where typing `ps`/`grep`/`top`/`cat`/`find`/`du`/`df`/`less`/`ls` resolves to system binaries, and `l`/`ll`/`llm`/`la`/`lx`/`lt`/`llt` resolve to `eza` invocations when `eza` exists.

- [ ] **Step 1: Read the current file to confirm line ranges before editing**

Run: `cat -n shell/aliases.zsh | sed -n '25,115p'`
Expected: see the three sections to delete (Listing Aliases 27-57, File Viewing Aliases 59-72, File System Aliases 74-111).

- [ ] **Step 2: Replace the Listing/File-Viewing/File-System sections in one edit**

Use the Edit tool with `old_string` being the entire current block from line 23 through line 111 (the three section headers and their contents) and `new_string` being the rewritten block below.

`old_string` (exact text, including the section-header comment lines):

```zsh
# =============================================================================
# Listing Aliases (Modern Tools Priority)
# =============================================================================

# eza - modern ls replacement
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias l='eza -lbF --git --icons'
    alias ll='eza -lbGF --git --icons'
    alias llm='eza -lbGd --git --sort=modified'
    alias la='eza -lbhHigmuSa --time-style=long-iso --git --color-scale --icons'
    alias lx='eza -lbhHigmuSa@ --time-style=long-iso --git --color-scale --icons'
    alias lt='eza --tree --level=2 --icons'
    alias llt='eza -lah --tree --level=2 --icons'

# lsd - another modern ls replacement
elif command -v lsd &> /dev/null; then
    alias ls='lsd --group-dirs first'
    alias l='lsd -l'
    alias ll='lsd -lA'
    alias la='lsd -A'
    alias lt='lsd --tree --depth 2'
    alias lla='lsd -lA --tree --depth 2'

# Fallback to standard ls
else
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        alias ls='ls --color=auto --group-directories-first'
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        alias ls='ls -G'
    fi
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# =============================================================================
# File Viewing Aliases
# =============================================================================

# bat - cat with syntax highlighting
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never --style=plain'
    alias batp='bat --paging=never'
    alias less='bat --paging=always'
elif command -v batcat &> /dev/null; then
    # bat is named batcat on some Ubuntu/Debian systems
    alias cat='batcat --paging=never --style=plain'
    alias bat='batcat'
fi

# =============================================================================
# File System Aliases
# =============================================================================

# Find replacement (fd)
if command -v fd &> /dev/null; then
    alias find='fd'
fi

# Grep with ripgrep
if command -v rg &> /dev/null; then
    alias grep='rg --color=auto'
    alias rgf='rg --files-with-matches'
fi

# du replacement (dust)
if command -v dust &> /dev/null; then
    alias du='dust'
fi

# df replacement (duf)
if command -v duf &> /dev/null; then
    alias df='duf'
fi

# ps replacement (procs)
if command -v procs &> /dev/null; then
    alias ps='procs'
fi

# top replacement (btm or btop)
if command -v btm &> /dev/null; then
    alias top='btm'
    alias htop='btm'
elif command -v btop &> /dev/null; then
    alias top='btop'
    alias htop='btop'
fi
```

`new_string`:

```zsh
# =============================================================================
# Modern Tool Short Aliases (non-replacing)
# =============================================================================
# Modern CLI tools (eza, bat, fd, rg, dust, duf, procs, btm) are NOT aliased
# over system binaries. Call them by their real names: bat, fd, rg, dust, duf,
# procs, btm. The aliases below use NEW names that don't shadow `ls`.
# See docs/tools-cheatsheet.md for the full mapping.

if command -v eza &> /dev/null; then
    alias l='eza -lbF --git --icons'
    alias ll='eza -lbGF --git --icons'
    alias llm='eza -lbGd --git --sort=modified'
    alias la='eza -lbhHigmuSa --time-style=long-iso --git --color-scale --icons'
    alias lx='eza -lbhHigmuSa@ --time-style=long-iso --git --color-scale --icons'
    alias lt='eza --tree --level=2 --icons'
    alias llt='eza -lah --tree --level=2 --icons'
fi
```

- [ ] **Step 3: Verify syntax**

Run: `zsh -n shell/aliases.zsh`
Expected: no output, exit code 0.

- [ ] **Step 4: Verify replacement aliases are gone**

Run: `zsh -c 'source shell/aliases.zsh; for c in ls cat less find grep du df ps top htop; do alias $c >/dev/null 2>&1 && echo "STILL ALIASED: $c"; done; echo "done"'`
Expected: only `done` is printed. No `STILL ALIASED:` lines.

- [ ] **Step 5: Verify short aliases still resolve to eza (only when eza is installed)**

Run: `command -v eza >/dev/null && zsh -c 'source shell/aliases.zsh; alias ll' || echo "eza not installed, skipping"`
Expected on machines with eza: `ll='eza -lbGF --git --icons'`. On machines without eza: `eza not installed, skipping`.

- [ ] **Step 6: Verify unrelated aliases still load**

Run: `zsh -c 'source shell/aliases.zsh; alias g; alias dus; alias python'`
Expected: three alias lines printed (`g='git'`, `dus='du -sh'`, `python=python3`).

- [ ] **Step 7: Run the existing bats test suite**

Run: `./scripts/tests/run_tests.sh`
Expected: 53/53 tests pass (alias file is not under test, but this confirms no incidental regression).

- [ ] **Step 8: Commit**

```bash
git add shell/aliases.zsh
git commit -m "$(cat <<'EOF'
refactor(aliases): stop shadowing system binaries with modern tools

Remove alias replacements for ls/cat/less/find/grep/du/df/ps/top/htop.
Modern tools (eza/bat/fd/rg/dust/duf/procs/btm) are now invoked by their
real names. Keep ll/la/l/lt/llt/llm/lx as eza short aliases since they
don't shadow any system command.

Rationale: avoid silent flag/output drift between interactive shell and
scripts; preserve muscle memory for system commands.
EOF
)"
```

---

### Task 2: Create `docs/tools-cheatsheet.md`

**Files:**
- Create: `docs/tools-cheatsheet.md`

**Interfaces:**
- Consumes: nothing
- Produces: a user-facing reference linked from `CLAUDE.md` in Task 3.

- [ ] **Step 1: Write the cheatsheet file**

Use the Write tool to create `docs/tools-cheatsheet.md` with exactly the content below:

````markdown
# Modern CLI Tools Cheatsheet

This repository installs modern CLI tools but **does not** alias them over system commands. Call each tool by its real name.

## Tool ↔ system command mapping

| System command | Modern tool | Invoke as | Notes |
|----------------|-------------|-----------|-------|
| `ls`           | eza         | `eza`     | Short aliases `l`/`ll`/`llm`/`la`/`lx`/`lt`/`llt` provided |
| `cat`          | bat         | `bat`     | Syntax highlighting, line numbers |
| `less`         | bat         | `bat --paging=always` | Or keep using `less` |
| `find`         | fd          | `fd`      | Usage: `fd PATTERN` (recursive by default) |
| `grep`         | ripgrep     | `rg`      | Usage: `rg PATTERN` (recursive by default) |
| `du`           | dust        | `dust`    | Tree-style disk usage |
| `df`           | duf         | `duf`     | Pretty disk-free table |
| `ps`           | procs       | `procs`   | Colored process listing |
| `top` / `htop` | bottom      | `btm`     | Interactive TUI monitor |
| `cd`           | zoxide      | `z`       | Smart jump (`z foo` after first visit) |

## Common task comparison

| Task | System form | Modern form |
|------|-------------|-------------|
| Long-format listing       | `ls -alF`             | `ll` (alias) or `eza -lbGF --git --icons` |
| Find files by extension   | `find . -name '*.ts'` | `fd -e ts` or `fd '\.ts$'` |
| Search file contents      | `grep -rn "TODO" .`   | `rg TODO` |
| Inspect a process         | `ps aux \| grep node` | `procs node` (or keep the pipe — `ps` is system `ps`) |
| Per-directory disk usage  | `du -sh ./*`          | `dust -d 1` |
| System monitor            | `top`                 | `btm` |
| Jump to a directory       | `cd ~/projects/foo`   | `z foo` |

## Linux-specific naming

- `bat` is packaged as `batcat` on Debian/Ubuntu. The install scripts create `~/.local/bin/bat → batcat` so `bat` works everywhere.
- `fd` is packaged as `fdfind` on Debian/Ubuntu. The install scripts create `~/.local/bin/fd → fdfind` so `fd` works everywhere.
- See `scripts/tools/bat.sh` and `scripts/tools/fd.sh`.

## Commands that stay unaliased

`ps`, `grep`, `top`, `htop`, `cat`, `find`, `du`, `df`, `less`, `ls` — typing any of these invokes the **system** binary. This is intentional: it preserves muscle memory, keeps script behavior identical to interactive behavior, and avoids subtle flag/output drift.

## Reloading aliases after edits

Changes to `shell/aliases.zsh` only affect **new** shells. To refresh the current shell:

```sh
source ~/.zshrc
```
````

- [ ] **Step 2: Verify the file is well-formed markdown**

Run: `wc -l docs/tools-cheatsheet.md && head -5 docs/tools-cheatsheet.md`
Expected: file size > 30 lines, first line is `# Modern CLI Tools Cheatsheet`.

- [ ] **Step 3: Commit**

```bash
git add docs/tools-cheatsheet.md
git commit -m "$(cat <<'EOF'
docs: add modern CLI tools cheatsheet

Cross-reference for users learning the renamed tools after the alias
replacements were removed. Lists system↔modern mappings, common task
equivalents, Linux naming quirks, and the rationale for keeping system
commands unaliased.
EOF
)"
```

---

### Task 3: Update `CLAUDE.md` with the no-replacement principle

**Files:**
- Modify: `CLAUDE.md` (add one subsection under `## Architecture`, add one subsection under `## Important Notes`)

**Interfaces:**
- Consumes: `docs/tools-cheatsheet.md` (referenced by path)
- Produces: durable guidance for future maintainers and Claude sessions.

- [ ] **Step 1: Insert the Architecture subsection after `### Config Manifest`**

Use the Edit tool on `CLAUDE.md`.

`old_string`:

```markdown
### Config Manifest
- `scripts/configs/manifest.sh` — declarative symlink config, shared by install and uninstall
- Format: `"source_relative|target_path|platform[:flags]"`
- Single source of truth — eliminates sync issues between install/uninstall

### Key Directories
```

`new_string`:

```markdown
### Config Manifest
- `scripts/configs/manifest.sh` — declarative symlink config, shared by install and uninstall
- Format: `"source_relative|target_path|platform[:flags]"`
- Single source of truth — eliminates sync issues between install/uninstall

### Modern Tool Aliases
- Modern tools (eza/bat/fd/rg/dust/duf/procs/btm) **do not** alias over system commands — `ps`, `grep`, `top`, `cat`, `find`, `du`, `df`, `less`, `ls` all invoke the system binary
- Rationale: preserve muscle memory and avoid flag/output drift between scripts and interactive use
- Only `l`/`ll`/`llm`/`la`/`lx`/`lt`/`llt` are kept as `eza` short aliases (new names, not replacements), guarded by `command -v eza`
- User-facing reference: `docs/tools-cheatsheet.md`
- When adding a new tool: register it in `scripts/tools/<name>.sh`; **do not** add an alias in `shell/aliases.zsh` that shadows a system binary

### Key Directories
```

- [ ] **Step 2: Append the Important Notes subsection at the end of `## Important Notes`**

Use the Edit tool on `CLAUDE.md`.

`old_string`:

```markdown
### Powerlevel10k Icons
Requires Nerd Font — install via `brew install --cask font-meslo-lg-nerd-font` on macOS
```

`new_string`:

```markdown
### Powerlevel10k Icons
Requires Nerd Font — install via `brew install --cask font-meslo-lg-nerd-font` on macOS

### Modern CLI Tools
The installed modern tools (eza, bat, fd, rg, dust, duf, procs, btm) **do not** replace system commands. Call them by their real names. See `docs/tools-cheatsheet.md` for the mapping.
```

- [ ] **Step 3: Verify both edits landed**

Run: `grep -n "Modern Tool Aliases\|Modern CLI Tools\|tools-cheatsheet.md" CLAUDE.md`
Expected: at least 4 matching lines (Architecture subsection header, Important Notes subsection header, two `tools-cheatsheet.md` references).

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs(CLAUDE.md): document the no-replacement alias principle

Add an Architecture subsection and an Important Notes pointer so future
maintainers (and Claude) don't reintroduce alias-over-binary shims. Link
to the new docs/tools-cheatsheet.md as the user-facing reference.
EOF
)"
```

---

### Task 4: Final end-to-end verification

**Files:** none modified — verification only.

**Interfaces:**
- Consumes: deliverables of Tasks 1, 2, 3
- Produces: confidence that the change set is complete and non-regressive.

- [ ] **Step 1: Confirm git history shows three new commits**

Run: `git log --oneline -5`
Expected: top three commits are `docs(CLAUDE.md): ...`, `docs: add modern CLI tools cheatsheet`, `refactor(aliases): stop shadowing system binaries with modern tools` (most recent first).

- [ ] **Step 2: Syntax check on shell files**

Run: `zsh -n shell/aliases.zsh && zsh -n shell/zshrc && echo OK`
Expected: `OK`.

- [ ] **Step 3: Confirm no shadowing aliases anywhere in the file**

Run: `grep -nE "^[[:space:]]*alias[[:space:]]+(ls|cat|less|find|grep|du|df|ps|top|htop)=" shell/aliases.zsh || echo "none — good"`
Expected: `none — good`.

- [ ] **Step 4: Re-run the bats test suite**

Run: `./scripts/tests/run_tests.sh`
Expected: 53/53 tests pass.

- [ ] **Step 5: Spot-check the cheatsheet renders**

Run: `head -20 docs/tools-cheatsheet.md`
Expected: title plus the start of the "Tool ↔ system command mapping" table.

- [ ] **Step 6: Done — report status to user**

No commit needed for verification. If any step above failed, do not claim completion; fix the underlying issue and rerun the failed step.

---

## Self-Review Notes

- **Spec coverage:** Task 1 = spec §1 (aliases.zsh edits + retained guard + retained unrelated aliases). Task 2 = spec §2 (cheatsheet w/ replacement table, examples, Linux quirks, unaliased-commands list, reload hint). Task 3 = spec §3 (CLAUDE.md Architecture subsection + Important Notes addition). Task 4 covers spec "Verification" section. Spec §4 (uninstall unchanged) requires no work — explicitly out of scope.
- **Placeholder scan:** clean — all code blocks contain literal text; no TBD/TODO.
- **Type consistency:** alias names `l/ll/llm/la/lx/lt/llt` match between Task 1's `new_string` block, Task 2's cheatsheet, and Task 3's CLAUDE.md subsection.
- **Naming sanity:** the spec previously had a `lla` typo (fixed to `llt`); this plan uses `llt` throughout.
