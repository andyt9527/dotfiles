# Cross-Platform Dotfiles

A comprehensive dotfiles configuration for **Ubuntu** and **macOS**, featuring **Oh My Zsh** with **Powerlevel10k** theme.

## Features

- 🖥️ **Cross-Platform**: Works on both Ubuntu/Debian and macOS
- 🐚 **Oh My Zsh + Powerlevel10k**: Blazing fast, feature-rich Zsh setup
- ⚡ **Modern CLI Tools**: Support for `fd`, `bat`, `eza`, `zoxide`, `lazygit`, etc.
- 📟 **Tmux**: Feature-rich tmux configuration with Dracula theme
- 📝 **Vim**: [space-vim](https://github.com/andyt9527/space-vim) - Spacemacs-inspired Vim distribution
- 🔧 **Git**: Comprehensive Git and Tig configurations
- 🐳 **Docker**: Lazydocker configuration
- ⚡ **Easy Installation**: One-command installation with automatic backups

## Screenshots

```
# Powerlevel10k Prompt Example
~
❯ cd ~/projects/dotfiles

~/projects/dotfiles on main via  v20.11.0
❯

~/projects/dotfiles on main via  v20.11.0 took 3s
❯
```

## Prerequisites

### macOS

- macOS 10.15+ (Catalina or later)
- [Homebrew](https://brew.sh/) (will be auto-installed if missing)

### Ubuntu/Debian

- Ubuntu 20.04+ or Debian 11+
- `sudo` access for package installation

## Installation

### Quick Install (Basic)

```bash
git clone --recursive https://github.com/andyt9527/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

**Note:** The `--recursive` flag is required to clone the vimrc submodule.

### Full Install (With Modern Tools)

```bash
./install.sh --with-all
```

### Custom Install

```bash
./install.sh --with-lazygit --with-modern-tools
```

### Installation Options

```bash
./install.sh --help

Options:
  --skip-packages         Skip package installation
  --skip-ohmyzsh          Skip Oh My Zsh installation
  --skip-p10k             Skip Powerlevel10k installation
  --with-modern-tools     Install modern CLI tools (fd, bat, eza, etc.)
  --with-lazygit          Install Lazygit TUI
  --with-lazydocker       Install Lazydocker TUI
  --with-all              Install all optional tools
```

## What's Installed

### Core Packages

| Package | macOS | Ubuntu | Description |
|---------|-------|--------|-------------|
| zsh | ✅ | ✅ | Enhanced shell |
| oh-my-zsh | ✅ | ✅ | Zsh framework |
| powerlevel10k | ✅ | ✅ | Zsh theme |
| tmux | ✅ | ✅ | Terminal multiplexer |
| vim | ✅ | ✅ | Text editor |
| git | ✅ | ✅ | Version control |
| tig | ✅ | ✅ | Git TUI |
| fzf | ✅ | ✅ | Fuzzy finder |
| ripgrep | ✅ | ✅ | Fast grep replacement |

### Modern CLI Tools (Optional)

| Tool | Command | Description |
|------|---------|-------------|
| [fd](https://github.com/sharkdp/fd) | `fd` | User-friendly find alternative |
| [bat](https://github.com/sharkdp/bat) | `bat` | Syntax-highlighting cat clone |
| [eza](https://github.com/eza-community/eza) | `eza` | Modern ls replacement |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `z` | Smarter cd command |
| [lazygit](https://github.com/jesseduffield/lazygit) | `lazygit` | TUI for git |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | `lazydocker` | TUI for docker |
| [duf](https://github.com/muesli/duf) | `duf` | Modern df alternative |
| [dust](https://github.com/bootandy/dust) | `dust` | Modern du alternative |
| [procs](https://github.com/dalance/procs) | `procs` | Modern ps alternative |
| [bottom](https://github.com/ClementTsang/bottom) | `btm` | Modern top/htop alternative |

## Configuration Details

### Oh My Zsh + Powerlevel10k

#### Oh My Zsh Plugins

- `git` - Git aliases and completions
- `zsh-autosuggestions` - Fish-like suggestions
- `zsh-syntax-highlighting` - Command highlighting
- `zsh-history-substring-search` - Better history search
- `extract` - Archive extraction
- `sudo` - Press ESC twice for sudo
- `copypath`, `copyfile`, `copybuffer` - Copy utilities
- `web-search` - Search from terminal
- `brew`, `macos` (macOS only)

#### Powerlevel10k Features

- **Instant Prompt** - Blazing fast shell startup
- **Git Status** - Comprehensive repo information (branch, ahead/behind, stash, conflicts)
- **Tool Versions** - Shows versions for Node, Python, Go, Rust, Java, Ruby, etc.
- **Context Awareness** - Kubernetes, AWS, Azure, Docker context
- **Smart Directory** - Shortened path with anchor directories

**Customize Powerlevel10k:**
```bash
p10k configure
# or edit ~/.p10k.zsh directly
```

#### Aliases

**Navigation:**
```bash
..      # cd ..
...     # cd ../..
....    # cd ../../..
```

**Modern Tools (if installed):**
```bash
ls      # eza --icons --group-directories-first
ll      # eza -lbF --git --icons
lt      # eza --tree --level=2 --icons
cat     # bat --paging=never --style=plain
cd      # z (zoxide - smart cd)
find    # fd
```

**Git Shortcuts:**
```bash
g       # git
gst     # git status
gd      # git diff
gco     # git checkout
gp      # git push
glg     # git log --oneline --graph
lg      # lazygit (if installed)
```

**Tmux:**
```bash
t       # tmux
ta      # tmux attach
tl      # tmux ls
```

#### Functions

- `mkcd <dir>` - Create directory and cd into it
- `up <n>` - Go up n directories
- `extract <archive>` - Extract any archive format
- `ff <pattern>` - Find files (uses fd if available)
- `fs <pattern>` - Search in files (uses rg if available)
- `fcd` - FZF change directory
- `fe` - FZF edit file
- `fkill` - FZF kill process
- `weather [city]` - Show weather
- `serve [port]` - Quick HTTP server

### Tmux Configuration

**Prefix Key:** `Ctrl+a`

**Key Bindings:**

| Key | Action |
|-----|--------|
| `Ctrl+a + c` | Create new window |
| `Ctrl+a + \|` | Split vertically |
| `Ctrl+a + -` | Split horizontally |
| `Ctrl+a + h/j/k/l` | Navigate panes |
| `Ctrl+h/j/k/l` | Smart pane switch (no prefix) |
| `Ctrl+a + [` | Enter copy mode |
| `Ctrl+a + v` | Quick copy mode |
| `Ctrl+a + y` | Copy to clipboard |
| `Ctrl+a + z` | Zoom pane |
| `Ctrl+a + g` | Open lazygit popup |
| `Ctrl+a + R` | Reload configuration |

**Plugins:**
- `tmux-resurrect` - Save/restore sessions
- `tmux-continuum` - Automatic save/restore
- `tmux-yank` - Clipboard integration
- `tmux-copycat` - Regex search
- `tmux-fzf` - FZF integration
- `tmux-open` - Open URLs/files

### Vim Configuration

This dotfiles uses [space-vim](https://github.com/andyt9527/space-vim) as a Git submodule - a spacemacs-inspired Vim distribution optimized for Vim 8+.

**Leader Key:** `Space`

**Key Bindings:**

| Key | Action |
|-----|--------|
| `SPC f f` | Find files (fzf) |
| `SPC b b` | Buffers list (fzf) |
| `SPC p s` | Search in project (rg) |
| `SPC g s` | Git status (fugitive) |
| `SPC t t` | Toggle Tagbar |
| `SPC ?` | Show key bindings |
| `, c p` | Markdown preview |
| `Ctrl+h/j/k/l` | Navigate windows/tmux |

**Default Layers:**
- `better-defaults` - Enhanced Vim defaults
- `fzf` - Fuzzy finder integration
- `which-key` - Key binding popup
- `airline` - Status line
- `c-c++`, `python`, `markdown` - Language support
- `lsp` - LSP via coc.nvim
- `git` - Git integration
- `ctags` - Tag navigation
- `tmux` - Tmux integration

**Customization:**
Edit `~/.vimrc.bundle` to enable/disable layers and add custom plugins. The file is linked from `space-vim/init.spacevim`.

### Lazygit Configuration

Features:
- Dracula theme
- Delta integration for diffs
- Custom key bindings
- FZF integration

## Directory Structure

```
kimi_ubuntu_mac_dotfile/
├── README.md
├── install.sh              # Main installation script
├── uninstall.sh            # Uninstallation script
├── bootstrap.sh            # One-liner bootstrap
├── config/
│   ├── p10k.zsh            # Powerlevel10k configuration
│   ├── lazygit.yml         # Lazygit config
│   └── lazydocker.yml      # Lazydocker config
├── git/
│   ├── gitconfig           # Git configuration
│   ├── gitconfig-work.example
│   └── gitconfig-personal.example
├── oh-my-zsh/
│   └── patches/            # Oh My Zsh patches
├── scripts/
│   ├── utils.sh            # Utility functions
│   └── update.sh           # Update script
├── shell/
│   ├── bashrc              # Bash configuration
│   └── zshrc               # Zsh configuration (Oh My Zsh + Powerlevel10k)
├── tig/
│   ├── tigrc               # Tig configuration
│   └── tigrc.theme         # Tig color theme
├── tmux/
│   └── tmux.conf           # Tmux configuration
└── space-vim/              # Vim configuration (Git submodule)
    ├── init.vim            # space-vim entry point
    ├── init.spacevim       # Default layer configuration template
    ├── core/               # Core space-vim logic
    └── layers/             # Layer definitions
```

## Customization

### Local Overrides

Create these files for machine-specific settings:

- `~/.bashrc.local` - Bash local settings
- `~/.zshrc.local` - Zsh local settings
- `~/.vimrc.bundle` - space-vim layer configuration
- `~/.p10k.zsh` - Powerlevel10k configuration (auto-linked or run `p10k configure`)

### Customize Powerlevel10k

```bash
# Interactive configuration wizard
p10k configure

# Or manually edit the config
vim ~/.p10k.zsh
```

### Git Work/Personal Separation

```bash
# Create work directory and use different git identity
mkdir -p ~/work
cp ~/dotfiles/git/gitconfig-work.example ~/.gitconfig-work
# Edit ~/.gitconfig-work with your work email
```

## Updating

### Update Dotfiles

```bash
cd ~/dotfiles
./scripts/update.sh
```

### Update Individual Components

```bash
# Update Vim plugins
vim +PlugUpdate +qall

# Update space-vim submodule
cd ~/dotfiles && git submodule update --remote

# Update Tmux plugins
# Press 'prefix + U' in tmux

# Update Oh My Zsh
omz update

# Update Powerlevel10k
cd ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k && git pull
```

## Uninstallation

```bash
cd ~/dotfiles
./uninstall.sh
```

## Troubleshooting

### Zsh not default shell

```bash
chsh -s $(which zsh)
```

### Tmux clipboard not working on macOS

```bash
brew install reattach-to-user-namespace
```

### Powerlevel10k icons not showing

Install a [Nerd Font](https://www.nerdfonts.com/):

```bash
# macOS (no need to tap, fonts are in homebrew/cask now)
brew install --cask font-meslo-lg-nerd-font

# Or install other popular Nerd Fonts
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font

# Then set your terminal font to "MesloLGS NF"
```

### Vim colors not working

Ensure your terminal supports true color:

```bash
# Add to ~/.zshrc.local or ~/.bashrc.local
export TERM=xterm-256color
```

### Permission denied on scripts

```bash
chmod +x ~/dotfiles/*.sh ~/dotfiles/scripts/*.sh
```

### Vim ctags/tags not working

space-vim requires **Universal Ctags** (not the default BSD ctags on macOS or exuberant-ctags).

**macOS:**
```bash
brew install universal-ctags
```

**Ubuntu/Debian:**
```bash
# The script attempts to install from source if not available
# Manual installation:
git clone https://github.com/universal-ctags/ctags.git /tmp/ctags
cd /tmp/ctags
./autogen.sh && ./configure && make && sudo make install
```

### space-vim submodule not found

If you see "space-vim submodule not found", run:
```bash
cd ~/dotfiles
git submodule update --init --recursive
```

## Credits

- Based on [misc_config](https://github.com/andytian1991/misc_config) project
- Tmux config inspired by [k-tmux](https://github.com/wklken/k-tmux)
- Dracula theme for [various tools](https://draculatheme.com/)
- Powerlevel10k by [romkatv](https://github.com/romkatv/powerlevel10k)

## License

MIT License - Feel free to use and modify as needed.
