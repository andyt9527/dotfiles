# Design: Remove Replacement Aliases for Modern CLI Tools

**Date:** 2026-06-23
**Status:** Approved (brainstormed)
**Scope:** Single PR — alias file edit + new cheatsheet doc + CLAUDE.md note

## Motivation

本仓库通过 `shell/aliases.zsh` 用 alias 把 9 个系统命令替换成现代工具:

```
ls → eza       cat → bat      less → bat     find → fd
grep → rg      du → dust      df → duf       ps → procs
top/htop → btm/btop
```

**问题:** 替换破坏了用户对系统命令的肌肉记忆和脚本兼容性。`ps aux | grep node` 在交互 shell 里会变成 `procs aux | rg node`,两者 flag 完全不同,要么报错要么返回奇怪结果;在脚本里使用 `grep` 又会因交互 shell 是否加载 alias 而行为不一致。

**目标:** 新工具通过自己的原名调用(`rg`、`procs`、`btm`、`eza`),系统命令保持原意。

## Approach

**选定方案:最小手术式改动**

- 直接编辑 `shell/aliases.zsh`,删除所有替换型 alias
- 保留 `l/ll/llm/la/lx/lt/llt` 作为 `eza` 的短别名(新名字,非替换),加 `command -v eza` guard
- 新增 `docs/tools-cheatsheet.md` 速查表
- 在 `CLAUDE.md` 加两段说明,锁定"不替换"原则

**否决的方案:**
- 加 `dotfiles-tools` 速查命令 — 维护成本高于价值,速查表文件已够用
- 加配置开关让用户切回旧行为 — YAGNI,违背"易用性"目标

## Detailed Changes

### 1. `shell/aliases.zsh`

**删除以下段落:**

| 行号(当前) | 内容 |
|---|---|
| 27-57 | "Listing Aliases" 整段(包括 eza 分支、lsd 分支、fallback 分支) |
| 59-72 | "File Viewing Aliases" 整段(bat/batcat 替换 cat/less) |
| 78-81 | `alias find='fd'` |
| 83-87 | `alias grep='rg ...'`、`alias rgf=...` |
| 89-92 | `alias du='dust'` |
| 94-97 | `alias df='duf'` |
| 99-102 | `alias ps='procs'` |
| 104-111 | `alias top/htop='btm/btop'` |

**新增以下段落(放在原 "Listing Aliases" 位置):**

```zsh
# =============================================================================
# Modern Tool Short Aliases (non-replacing)
# =============================================================================
# These aliases use NEW names that don't shadow system binaries.
# They call eza directly; if eza is not installed, they are silently skipped.

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

**保留不动:**

- `alias python=python3` — 版本默认值,非工具替换
- `alias dus='du -sh'`、`alias dud='du -d 1 -h'` — 引用系统 `du`,语义符合预期
- 所有 git/tmux/navigation/编辑器/macOS/Linux 系统别名

### 2. `docs/tools-cheatsheet.md`(新建)

内容大纲:

- **替代关系一览表** — 系统命令 / 现代工具 / 直接调用名 / 备注
- **常用示例对照** — 系统写法 vs 现代写法(find / grep / ps / du / top / cd)
- **Linux 特殊处理** — `bat`/`batcat`、`fd`/`fdfind` 通过 `~/.local/bin` 符号链接统一为原名
- **显式不替换的命令清单** — `ps`/`grep`/`top`/`cat`/`find`/`du`/`df`/`less`/`ls`
- **重载提示** — 改动 aliases.zsh 后需 `source ~/.zshrc` 或重开 shell

### 3. `CLAUDE.md`

**在 `## Architecture` 下新增 `### Modern Tool Aliases` 子节(放在 `### Config Manifest` 之后):**

```markdown
### Modern Tool Aliases
- 现代工具(eza/bat/fd/rg/dust/duf/procs/btm)**不通过 alias 替换**系统命令 — `ps`、`grep`、`top`、`cat`、`find`、`du`、`df`、`less`、`ls` 全部调用系统原版
- 原因:保留肌肉记忆、避免不同 flag/输出格式在脚本和交互中产生差异
- 仅保留 `l/ll/llm/la/lx/lt/llt` 作为 `eza` 的短别名(非替换,只是新名字),并通过 `command -v eza` guard 保护
- 用户速查表:`docs/tools-cheatsheet.md`
- 添加新工具时:在 `scripts/tools/<name>.sh` 注册,**不要**在 `shell/aliases.zsh` 中加 alias 覆盖原 binary
```

**在 `## Important Notes` 章节末尾追加:**

```markdown
### 现代 CLI 工具
- 默认安装的现代工具(eza、bat、fd、rg、dust、duf、procs、btm)**不替换**系统命令,直接用工具原名调用
- 速查表见 `docs/tools-cheatsheet.md`
```

### 4. `uninstall.sh` — 无需改动

验证:
- `grep -i alias uninstall.sh` → 0 处匹配
- uninstall.sh 只读 `scripts/configs/manifest.sh`,该 manifest 未引用 alias

alias 的生命周期与 install/uninstall 解耦 — alias 在交互 shell 启动时由 `~/.zshrc → zshrc → source aliases.zsh` 加载。uninstall 删除 `~/.zshrc` symlink 后新 shell 自然不再加载,旧 shell 需用户自行重启。

## Verification

**实施后验证步骤:**

1. `zsh -n shell/aliases.zsh` — 语法检查
2. `zsh -c 'source shell/aliases.zsh; alias'` — 列出 alias,确认无 `ps`/`grep`/`top`/`cat`/`find`/`du`/`df`/`less`/`ls`
3. `zsh -c 'source shell/aliases.zsh; type ll la l lt'` — 确认短别名指向 eza
4. `zsh -c 'source shell/aliases.zsh; type ps grep top'` — 确认指向系统 binary
5. `./scripts/tests/run_tests.sh` — 现有 53/53 bats 测试不回归(预期不受影响,因为测试针对 lib/ 而非 aliases.zsh)
6. 手动:打开新 shell,跑 `ls`(应输出系统 ls)、`ll`(应输出 eza 长格式)、`procs`(应正常列出进程)

## Non-Goals

- **不**为替换 alias 提供切换开关(用户明确表示不要旧行为)
- **不**新增 shell 命令来打印速查表(文档文件已够)
- **不**重构 `aliases.zsh` 为多文件(超出本次范围)
- **不**改 `manifest.sh`、`install.sh`、`uninstall.sh`(与 alias 无关)

## Out of Scope (可单独提案)

- 为 `~/.zshrc.local` 提供示例段,允许用户**显式**重新启用某些替换(如个人偏好 `cat=bat`)
- 评估是否把 `alias tmux="tmux -2"` 改成 shell function 或删掉(本次不动)
