# Design: Fix Install-Flow Compatibility Issues (Audit Clusters B+C+D)

**Date:** 2026-06-24
**Status:** Approved (brainstormed)
**Scope:** 6 issues from `docs/superpowers/specs/2026-06-24-compat-audit-design.md` — 1 Critical, 4 Important, 1 Minor. Single spec, 6 implementation tasks.
**Upstream:** Audit report at `docs/superpowers/specs/2026-06-24-compat-audit-design.md`

## Motivation

审计发现 install 流程中有 6 个跨平台 bug。本 spec 修复这些 bug,让 `./install.sh` 在 macOS、Ubuntu/Debian、Fedora、Arch 上都能正确安装工具。Shell 配置中的硬编码路径(审计簇 A)和 Minor 清理(审计簇 E)不在本次范围。

## Approach

**选定方案: 一个 spec,一个 plan,6 个 task(每个 issue 一个)**

- 每个 task 先写 bats 测试(TDD RED),再改代码(GREEN),最后 commit
- cc-switch task 第一步是验证实际 release asset 命名,再决定是否修代码
- 所有测试加入现有 `scripts/tests/` 目录,通过 `./scripts/tests/run_tests.sh` 运行

**否决的方案:**
- 按簇拆 3 个 spec(B/C/D 各一个)— 3 轮 brainstorm 开销,但 B+C+D 已作为一个范围,不必要
- 一个 PR 一个 commit — 失去逐 task TDD 的清晰度,审查困难

## Detailed Changes

### Task 1: Fix `scripts/tools/lazygit.sh` Linux asset filename

**Issue:** Audit Critical #4 — L17-18 asset pattern `lazygit_${arch}.tar.gz` 不含版本和 `_Linux_` 段,实际 asset 是 `lazygit_0.44.1_Linux_x86_64.tar.gz`,URL 404。L21 `/usr/local/bin` 假设存在(Minor #11)。

**Root cause:** `download_github_release` 在内部获取 tag,调用方无法用 tag 构造文件名。

**Fix:** 改用 cc-switch.sh 的模式 — 先 `get_latest_release_tag`,在调用方构造正确文件名。

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
        version="${tag#v}"  # strip v prefix
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

**Test:** 新建 `scripts/tests/test_lazygit.sh`。Mock `get_arch` → `x86_64`,mock `get_latest_release_tag` → `v0.44.1`,mock `download_github_release` 捕获第二参数(asset_pattern)。断言 asset_pattern == `lazygit_0.44.1_Linux_x86_64.tar.gz`。再加一个 aarch64 用例,mock arch → `aarch64`,断言 asset_pattern == `lazygit_0.44.1_Linux_aarch64.tar.gz`。

---

### Task 2: Verify and fix `scripts/tools/cc-switch.sh` aarch64 asset naming

**Issue:** Audit Important #6 — L53 `CC-Switch-${latest_tag}-Linux-${arch}.deb` 用 `get_arch` 返回 `aarch64`,但 cc-switch 实际 asset 可能用 `arm64`。

**Step 1 — 验证(在 plan 的 task 里执行):** 通过 `curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest | jq -r '.assets[].name'` 查实际命名。

**Step 2 — 条件修复:**
- 如果实际是 `arm64`:在 `install_cc_switch` Linux 分支加 arch 映射
  ```bash
  local arch
  arch=$(get_arch)
  [[ "$arch" == "aarch64" ]] && arch="arm64"
  local file="CC-Switch-${latest_tag}-Linux-${arch}.deb"
  ```
- 如果实际是 `aarch64`:不改代码,在 spec/plan 标注 finding 关闭
- 如果两种都有:优先 `aarch64`,下载失败时 fallback `arm64`

**Test:** 新建 `scripts/tests/test_cc_switch.sh`。Mock `get_arch` → `aarch64`,mock `get_latest_release_tag` → `v1.2.3`,断言构造的 `file` 变量匹配验证结果。如果验证后不需要改代码,这个测试文件不创建。

**Network-free fallback:** 执行环境无网络时,task 标记为"需人工验证",跳过代码改动,在 plan ledger 记录。

---

### Task 3: Fix `scripts/tools/fzf.sh` install paths

**Issue:** Audit Important #7 — L11-17 macOS 重复安装(brew + git clone),Linux 只走 git clone 没走 apt。

**Fix:** 三平台分支,优先系统包管理器。

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

**Key changes:**
1. macOS 只 brew,Linux 优先 apt-get,fallback 才 git clone
2. "已安装" 检查扩展为 `command -v fzf` 或 `~/.fzf` 目录 — 因为 brew/apt 安装不创建 `~/.fzf`,但 `fzf` 命令可用

**Test:** 新建 `scripts/tests/test_fzf.sh`,三个用例:
- macOS + fzf 已存在 → 不调用 brew,不 clone
- Linux (apt-get 可用) + 无 fzf → 调用 `sudo apt-get install -y fzf`,不 clone
- Linux (apt-get 不可用) + 无 fzf → 只 clone,不调用 apt

Mock `is_macos`/`is_linux`、`command_exists`、`run_cmd`(捕获调用参数)。

---

### Task 4: Fix `install.sh` ctags dry-run leak

**Issue:** Audit Important #8 — L234-240 `rm -rf /tmp/ctags`、`cd`、`./autogen.sh && ./configure && make` 都没走 `run_cmd`,`--dry-run` 下真执行。

**Fix:** 用子 shell 隔离工作目录,所有副作用步骤独立 `run_cmd`。

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

**Key changes:**
1. `rm -rf /tmp/ctags` 两次都包进 `run_cmd`
2. 子 shell `( cd ... )` 隔离工作目录,避免 dry-run 下 `cd` 切走但 `cd "$original_dir"` 没执行
3. `./autogen.sh`、`./configure`、`make` 独立 `run_cmd` — 失败时精确定位,不靠 `&&` 链
4. 顶层 `cd "$original_dir"` 保留(防御性)

**Test:** 新建 `scripts/tests/test_install_ctags.sh`,两个用例:
- `DRY_RUN=1` 模式 → stub `rm` 检查调用次数为 0;mock `run_cmd` 捕获调用,断言 `rm -rf /tmp/ctags`、`./autogen.sh`、`./configure`、`make` 不在调用列表
- 非 dry-run 模式 → mock `run_cmd` 断言 `git clone`、`./autogen.sh`、`./configure`、`make`、`sudo make install` 都被调用

**Test approach:** 把 ctags 构建逻辑(目前内联在 install.sh)测试时需要 source install.sh 或提取为函数。如果 install.sh 结构不允许直接 source,测试改为:用 `grep` 断言 install.sh 里 ctags 相关行都包在 `run_cmd` 里(静态检查),并补充一个 `--dry-run` 端到端测试跑 install.sh 确认无副作用。

---

### Task 5: Fix `scripts/lib/package.sh` batch function to support yum/pacman

**Issue:** Audit Important #5 — L59-92 `install_packages_batch` Linux 分支只支持 apt-get,单包函数 `install_package` 已支持 apt/yum/pacman。Fedora/Arch 上 batch 走到 `is_linux` 分支但假设 apt,行为未定义。

**Fix:** 镜像 `install_package` 的 dispatch,加 `_package_installed_linux` helper。

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

**Design decisions:**
- yum 不做单独 `yum update` — yum install 时自动刷新元数据
- pacman 需要 `-Sy` 显式刷新
- `_package_installed_linux` 下划线前缀,标记 lib 内部 helper

**Test:** 扩展 `scripts/tests/test_package.sh`,新增用例:
- `is_linux` + apt-get 可用 + 全部已装 → 不调用 `apt-get install`
- `is_linux` + apt-get 可用 + 有未装 → 调用 `apt-get update` + `apt-get install`
- `is_linux` + yum 可用(apt 不可用) + 有未装 → 调用 `yum install`,不调用 apt
- `is_linux` + pacman 可用(apt/yum 不可用) + 有未装 → 调用 `pacman -S`
- `is_linux` + 无包管理器 → 返回 1,打印错误

Mock `is_macos`/`is_linux`、`command_exists`、`run_cmd`、`apt_package_installed`、`rpm`、`pacman`。

---

### Task 6: Final verification

**Files:** none modified — verification only.

**Steps:**
1. `./scripts/tests/run_tests.sh` — 现有 53 + 新增测试全部通过
2. `bash -n install.sh scripts/lib/*.sh scripts/tools/*.sh` — 语法检查
3. `./install.sh --dry-run` — 手动确认 ctags 步骤被跳过
4. `git log --oneline -7` — 确认 5 个修复 commit + 验证 commit 顺序正确

## Verification Summary

| Task | 测试文件 | 关键断言 |
|---|---|---|
| 1 lazygit | test_lazygit.sh | asset_pattern = `lazygit_<ver>_Linux_<arch>.tar.gz` |
| 2 cc-switch | test_cc_switch.sh (条件) | arch 映射正确,或 finding 关闭 |
| 3 fzf | test_fzf.sh | 三平台分发,无重复安装 |
| 4 ctags | test_install_ctags.sh | dry-run 下 rm/autogen/configure/make 不执行 |
| 5 package | test_package.sh (扩展) | apt/yum/pacman dispatch 正确 |
| 6 verify | — | 全套测试通过 + dry-run 无副作用 |

## Non-Goals

- **不**修审计簇 A(shell 硬编码路径)— 后续单独 spec
- **不**修审计簇 E(Minor 清理)— 后续单独 spec
- **不**在真实 Linux 机器上跑 install.sh — 超出本次范围
- **不**验证 lazygit 下载是否真成功 — 只验证 URL 构造
- **不**验证 yum/pacman 命令在真实 Fedora/Arch 上的行为 — 只验证 dispatch 逻辑
- **不**重构 install.sh 把 ctags 提取为独立函数 — 超出修复范围,除非测试需要

## Out of Scope (可单独提案)

- 审计簇 A:`shell/zshrc`、`shell/zshrc.local`、`shell/bashrc` 的硬编码路径
- 审计簇 E:`os.sh` `get_arch` 默认值、`aliases.zsh` `$OSTYPE` 不一致、`utils.sh` `detect_os` 重复、`bootstrap.sh` git 安装回退、`zshrc.local` 空 macOS 块
- 把 ctags 构建逻辑提取为 `scripts/tools/ctags.sh`(独立 tool 脚本)
