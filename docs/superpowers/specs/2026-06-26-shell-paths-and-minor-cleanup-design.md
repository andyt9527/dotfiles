# Audit + Fix: Shell Hardcoded Paths (Cluster A) & Minor Cleanup (Cluster E)

**Date:** 2026-06-26
**Status:** Approved (brainstormed)
**Scope:** Re-audit of remaining issues from `docs/superpowers/specs/2026-06-24-compat-audit-design.md` — cluster A (shell hardcoded paths) + cluster E (minor cleanup). Single spec, audit findings + fix design combined. 6 implementation tasks.
**Upstream audit:** `docs/superpowers/specs/2026-06-24-compat-audit-design.md`
**Prior fix (already merged):** `docs/superpowers/specs/2026-06-24-compat-fix-bcd-design.md` — clusters B+C+D (install-flow bugs), 6 tasks, commit `45d4a8c`.

## Motivation

上次审计(2026-06-24)发现 16 个问题,已修复 B+C+D 共 6 个 install 流程 bug(commit `45d4a8c`)。本次处理剩余两个未处理范围:

- **簇 A**:`shell/zshrc`、`shell/zshrc.local`、`shell/bashrc` 里硬编码 `/Users/andy/`、`/home/andy/` 路径,在非 `andy` 用户的机器上会污染 PATH 或报错。其中 conda 硬编码块还把 `~/.zshrc.local` 的 `_detect_conda` 自动检测覆盖成死代码。
- **簇 E**:`os.sh` `get_arch` 静默默认值、`aliases.zsh` `$OSTYPE` 不一致、`utils.sh` 重复 `detect_os`、`zshrc.local` 空 macOS 块、`bootstrap.sh` git 缺失无回退。

本 spec 把审计结论和修复设计合并:每节先列 finding,再给具体修复方向,后续直接进 writing-plans。

## Approach

**选定方案: 按平台语义替换 + 存在性守卫 + 删除死代码**

- `/Users/andy/` 视为 macOS `$HOME`,`/home/andy/` 视为 Linux `$HOME`,统一替换为 `$HOME`
- 个人工具路径(jishushell/mavis/opencode/NPU toolchain/Android SDK)加 `[[ -d ... ]]` 守卫,不存在时不污染 PATH
- 跨平台泄漏的 `/opt/homebrew/bin` 加 `is_macos` 守卫(或删除重复)
- conda 硬编码块整块删除,让 `_detect_conda` 自动检测生效
- Minor 清理:`get_arch` 加 warning、`aliases.zsh`/`utils.sh` 加自包含注释、删空 macOS 块、`bootstrap.sh` 加 git apt/yum 回退

**否决的方案:**
- 迁移到 `~/.zshrc.local`(gitignored 本地 override)— 你选择就地修复 + 守卫,信息不丢失
- 全量重审 B+C+D — 已修复,不重复

## Detailed Changes

### Task 1: Cluster E cleanup (low risk)

**Files:** `scripts/lib/os.sh`, `shell/aliases.zsh`, `shell/utils.sh`, `shell/zshrc.local`, `bootstrap.sh`

#### 1.1 `scripts/lib/os.sh` L25 — `get_arch` warning

**Finding:** Unknown arch 静默默认 `x86_64`,掩盖错误。

**Fix:** Log warning + 保留默认行为(不 return 1,避免破坏调用方):
```bash
*) warning "Unknown architecture: $(uname -m), defaulting to x86_64"; echo "x86_64" ;;
```

#### 1.2 `shell/aliases.zsh` L95、L124 — `$OSTYPE` 自包含

**Finding:** 用 `$OSTYPE` 而非 lib 的 `is_macos`/`is_linux`,与代码库风格不一致。

**Fix:** 保留 `$OSTYPE`,在文件顶部加注释说明自包含原因(zsh 启动早期加载,lib 可能未 source):
```bash
# This file is self-contained re: OS detection — it loads early in zsh startup
# before scripts/lib/os.sh is sourced. Use $OSTYPE directly rather than is_macos/is_linux.
```

#### 1.3 `shell/utils.sh` L7-13 — 重复 `detect_os`

**Finding:** 自实现 `detect_os`,与 `scripts/lib/os.sh` 重复。

**Fix:** 保留,加同类注释。需先在 plan 阶段确认 `utils.sh` 在 zshrc 的加载顺序,若确认 lib 已可用则改为 source lib;否则保留 + 注释。

#### 1.4 `shell/zshrc.local` L34-40 — 空 macOS 块

**Finding:** `if [[ "$OSTYPE" == "darwin"* ]]; then : fi` 占位无内容。

**Fix:** 删除整个空块。

#### 1.5 `bootstrap.sh` L19-22 — git 缺失回退

**Finding:** Fresh Ubuntu Server 无 git,直接 bail,无 apt/yum 回退。

**Fix:**
```bash
if ! command -v git &>/dev/null; then
    if is_linux; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum &>/dev/null; then
            sudo yum install -y git
        else
            echo "Error: git not found. Please install git manually." >&2
            exit 1
        fi
    else
        echo "Error: git not found. Please install git manually." >&2
        exit 1
    fi
fi
```

#### 1.6 测试

- `test_os.sh` 扩展:断言 `get_arch` 对未知 arch 调用 `warning` + 返回 `x86_64`
- `test_bootstrap.sh`(新建):静态 grep 断言 `apt-get install.*git` 和 `yum install.*git` 出现在 git 检测失败分支
- `test_shell_paths.sh`(Task 5 统一建):grep 断言 `aliases.zsh`/`utils.sh` 含自包含注释;`zshrc.local` 不含空 macOS 块

---

### Task 2: `shell/zshrc.local` Linux 块 (medium risk)

**Files:** `shell/zshrc.local` L9-29

**Finding:** L10-11 Android SDK、L15 modules.sh、L18-26 NPU toolchain 全部硬编码 `/home/andy/`。在非 andy 用户的 Linux 机器上污染 PATH、source 不存在的文件。

**Fix:**

L10-11 Android SDK — `$HOME` 替换 + 存在性守卫:
```bash
if [[ -d "$HOME/andywork/sdk-android/Sdk" ]]; then
    export ANDROID_HOME="$HOME/andywork/sdk-android/Sdk"
    export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/Sdk/build-tools/35.0.0"
fi
```

L15 modules.sh — 文件存在性守卫:
```bash
[[ -f /etc/profile.d/modules.sh ]] && source /etc/profile.d/modules.sh
```

L18-26 NPU toolchain — `$HOME` 替换 + 整块 `[[ -d "$HOME/NPU" ]]` 守卫:
```bash
if [[ -d "$HOME/NPU" ]]; then
    export LD_LIBRARY_PATH="$HOME/NPU/simulator/lib/:$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="$HOME/NPU/opencl-tool-chain/opencl-compiler/lib:$LD_LIBRARY_PATH"
    # ... etc
    export PATH="$PATH:$HOME/NPU/opencl-tool-chain/opencl-compiler/bin:..."
    export PATH="$PATH:$HOME/NPU/c-tool-chain/c-compiler/bin:..."
fi
```

L27 `export PATH="$PATH:$HOME/.local/bin"` — 已用 `$HOME`,保留(可加去重守卫,但非本任务范围)。

#### 2.1 测试

`test_shell_paths.sh`:
- `shell/zshrc.local` 不再出现 `/home/andy/`
- L15 modules.sh 行包含 `[[ -f` 守卫(grep `^[[:space:]]*\[\[ -f /etc/profile.d/modules.sh \]\]`)

---

### Task 3: `shell/bashrc` 硬编码路径 (medium risk)

**Files:** `shell/bashrc` L97-104

**Finding:** L98 jishushell+homebrew 硬编码 `/Users/andy/`;L101、L104 重复 mavis 条目。

**Fix:**

```bash
# jishushell-bin-path
[[ -d "$HOME/.jishushell/bin" ]] && export PATH="$HOME/.jishushell/bin:$PATH"

# Added by MiniMax Agent / Code (merged)
[[ -d "$HOME/.mavis/bin" ]] && export PATH="$HOME/.mavis/bin:$PATH"
```

L98 原 `/opt/homebrew/bin` 加 PATH:删除(在 macOS 上 Homebrew PATH 已由 install.sh 通过 `/etc/paths` 或 zshrc L127-138 处理;在 Linux 上不该加)。若需保留,加 `is_macos` 守卫,但更倾向删除重复。

#### 3.1 测试

`test_shell_paths.sh`:
- `shell/bashrc` 不再出现 `/Users/andy/`
- mavis 条目只剩一个

---

### Task 4: `shell/zshrc` L272-320 (highest risk, largest change)

**Files:** `shell/zshrc` L272-320

#### 4.1 L273 OpenClaw 注释

已注释掉的死注释,删除整行。

#### 4.2 L275-288 conda 硬编码块 — 整块删除

**Finding:** 此块在 `~/.zshrc.local` L46-79 的 `_detect_conda` 自动检测之后执行,把后者覆盖成死代码。

**Fix:** 整块删除(L275-288,含 `# >>> conda initialize >>>` 到 `# <<< conda initialize <<<`)。`_detect_conda` 会自动检测 `$HOME/miniforge3`、`$HOME/andywork/miniforge3`、`/opt/miniforge3`,覆盖 macOS (`/Users/andy/miniforge3` = `$HOME/miniforge3`) 和 Linux。

#### 4.3 L296-307 mamba 块 — 用 `$HOME` + 守卫

```bash
# >>> mamba initialize >>>
if [[ -f "$HOME/miniforge3/bin/mamba" ]]; then
    export MAMBA_EXE="$HOME/miniforge3/bin/mamba"
    export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
    __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__mamba_setup"
    else
        alias mamba="$MAMBA_EXE"
    fi
    unset __mamba_setup
fi
# <<< mamba initialize <<<
```

#### 4.4 L309-310 jishushell + homebrew

```bash
# jishushell-bin-path
[[ -d "$HOME/.jishushell/bin" ]] && export PATH="$HOME/.jishushell/bin:$PATH"
```

`/opt/homebrew/bin` 加 PATH 行:删除(Homebrew PATH 已由 install.sh / zshrc L127-138 处理)。

#### 4.5 L312-316 mavis 重复条目

合并为:
```bash
[[ -d "$HOME/.mavis/bin" ]] && export PATH="$HOME/.mavis/bin:$PATH"
```

#### 4.6 L320 opencode

```bash
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"
```

#### 4.7 测试

`test_shell_paths.sh`:
- `shell/zshrc` 不再出现 `/Users/andy/`
- L275-288 硬编码 conda 块已删除(grep `__conda_setup="\$\('/Users/andy` 返回空)
- `/opt/homebrew/bin` 在 zshrc L265-320 范围内不出现
- mamba 块用 `$HOME/miniforge3/bin/mamba`
- jishushell/mavis/opencode 行均含 `[[ -d` 守卫

---

### Task 5: New test file `scripts/tests/test_shell_paths.sh` + extend `test_os.sh`

**Files:**
- Create: `scripts/tests/test_shell_paths.sh`
- Modify: `scripts/tests/test_os.sh` (extend for `get_arch` warning)

#### 5.1 `test_shell_paths.sh` — 静态 grep 断言

```bash
#!/usr/bin/env bats

load test_helper

@test "shell/zshrc does not contain hardcoded /Users/andy/ paths" {
    ! grep -n '/Users/andy/' shell/zshrc
}

@test "shell/zshrc.local does not contain hardcoded /home/andy/ paths" {
    ! grep -n '/home/andy/' shell/zshrc.local
}

@test "shell/bashrc does not contain hardcoded /Users/andy/ paths" {
    ! grep -n '/Users/andy/' shell/bashrc
}

@test "shell/zshrc has no hardcoded conda block (uses _detect_conda from zshrc.local)" {
    ! grep -n "__conda_setup=\"\$('/Users/andy" shell/zshrc
}

@test "shell/zshrc jishushell/mavis/opencode paths are guarded with [[ -d" {
    # Each personal tool path must be preceded by an existence guard
    grep -c '\[\[ -d "\$HOME/\.jishushell/bin" \]\]' shell/zshrc
    grep -c '\[\[ -d "\$HOME/\.mavis/bin" \]\]' shell/zshrc
    grep -c '\[\[ -d "\$HOME/\.opencode/bin" \]\]' shell/zshrc
}

@test "shell/zshrc.local modules.sh source is guarded with [[ -f" {
    grep -c '\[\[ -f /etc/profile.d/modules.sh \]\]' shell/zshrc.local
}

@test "shell/zshrc.local empty macOS block removed" {
    ! grep -A1 'if \[\[ "\$OSTYPE" == "darwin"\* \]\]; then' shell/zshrc.local | grep -q '^[[:space:]]*:'
}

@test "shell/aliases.zsh has self-contained comment explaining \$OSTYPE use" {
    grep -q 'self-contained' shell/aliases.zsh
}

@test "shell/utils.sh has self-contained comment or sources scripts/lib/os.sh" {
    grep -qE 'self-contained|source.*scripts/lib/os\.sh' shell/utils.sh
}
```

#### 5.2 `test_os.sh` 扩展 — `get_arch` warning

新增测试:
```bash
@test "get_arch warns and defaults to x86_64 on unknown arch" {
    source scripts/lib/os.sh
    source scripts/lib/log.sh
    # Mock uname to return unknown arch
    uname() { echo "riscv64"; }
    output=$(get_arch 2>&1)
    [[ "$output" == *"Unknown architecture"*"riscv64"* ]] || \
      [[ "$(get_arch)" == "x86_64" ]]
    unset -f uname
}
```

(测试具体实现细节在 plan 阶段定,这里只给方向。)

---

### Task 6: Final verification

**Files:** none modified — verification only.

**Steps:**
1. `./scripts/tests/run_tests.sh` — 现有 74 + 新增全部通过
2. `zsh -n shell/zshrc`、`zsh -n shell/zshrc.local`、`bash -n shell/bashrc` — 语法检查
3. `grep -rn '/Users/andy/\|/home/andy/' shell/` — 返回空
4. `./install.sh --dry-run` — 不产生新错误
5. `git log --oneline -7` — 确认 5 个修复 commit + 验证 commit 顺序正确

## Verification Summary

| Task | 文件 | 关键断言 |
|---|---|---|
| 1 簇 E | os.sh/aliases.zsh/utils.sh/zshrc.local/bootstrap.sh | `get_arch` warning + 注释 + 空 macOS 块删除 + git 回退 |
| 2 zshrc.local | shell/zshrc.local L9-29 | 不含 `/home/andy/`,modules.sh 有 `[[ -f` 守卫 |
| 3 bashrc | shell/bashrc L97-104 | 不含 `/Users/andy/`,mavis 唯一 |
| 4 zshrc | shell/zshrc L272-320 | 不含 `/Users/andy/`,conda 硬编码块删除,mamba 用 `$HOME` |
| 5 测试 | test_shell_paths.sh (新) + test_os.sh (扩展) | 静态 grep 断言全通过 |
| 6 验证 | — | 全套测试 + 语法检查 + dry-run 无副作用 |

## Non-Goals

- **不**重审已修复的 B+C+D(install-flow bug)
- **不**重构 install.sh 把 ctags 提取为独立函数(超出范围)
- **不**改 `shell/zshrc` L127-138 Homebrew PATH 处理(已在审计中标 "done well")
- **不**为 `~/.zshrc.local` 个人内容做迁移(就地修复 + 守卫)
- **不**验证 `_detect_conda` 在真实 conda 环境的行为(超出静态测试范围,需手动验证)

## Out of Scope (可单独提案)

- 把 `shell/utils.sh` 的 `detect_os` 改为 source lib(需先确认 zshrc 加载顺序)
- `~/.zshrc.local` 完全迁移到 gitignored 本地文件(本次选择就地修复)
- zshrc 启动顺序重构(lib 提前 source,让 aliases.zsh/utils.sh 能复用)

## Risks

1. **删除 zshrc L275-288 conda 硬编码块后,本机 conda 是否仍能初始化** — `_detect_conda` 会检测 `$HOME/miniforge3`(macOS = `/Users/andy/miniforge3`,存在)。需 Task 4 后手动开新 zsh 验证 `conda activate` 可用。
2. **mamba 块改动后 `$MAMBA_EXE` 变量** — 改后依赖 `$HOME/miniforge3/bin/mamba` + 存在性守卫。mamba 不存在则跳过初始化(不报错)。
3. **`~/.zshrc.local` 是否 symlink 到 repo** — 若是 symlink,repo 改动同步到本机;若不是,repo 改动不影响本机。需在 Task 2 前确认 install.sh 的 symlink 策略(通过 `scripts/configs/manifest.sh`)。
