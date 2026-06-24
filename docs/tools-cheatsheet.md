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
