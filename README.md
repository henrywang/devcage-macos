# devcage-macos

MacBook Air setup — dotfiles and configuration for a fresh macOS install.

## Prerequisites

Install these manually from the **App Store** before running the setup script:

| App | Purpose |
|-----|---------|
| **1Password** | Password manager |
| **Xcode** | iOS / macOS development (optional) |

Xcode Command Line Tools are handled automatically by `setup.sh`.

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/henrywang/devcage-macos.git ~/devcage-macos

# 2. Run the setup script
cd ~/devcage-macos
bash setup.sh
```

Then open a new shell for all changes to take effect.

## What Gets Installed

### Homebrew packages (`Brewfile`)

| Package | Type | Purpose |
|---------|------|---------|
| vim | CLI | Text editor |
| gh | CLI | GitHub CLI |
| fzf | CLI | Fuzzy finder |
| lsd | CLI | Modern `ls` replacement |
| ripgrep | CLI | Fast recursive search |
| starship | CLI | Cross-shell prompt |
| node | CLI | JavaScript runtime |
| firefox | App | Web browser |
| ghostty | App | Terminal emulator |
| zed | App | Code editor |
| obsidian | App | Knowledge base / notes |
| rectangle | App | Window manager |
| stats | App | System stats in menu bar |
| font-jetbrains-mono-nerd-font | Font | Terminal font with icons |

### Other tools

| Tool | Installer | Purpose |
|------|-----------|---------|
| Rust + rustfmt + clippy | rustup | Systems programming |
| Claude Code | npm | AI coding assistant |

### Zsh plugins (cloned into `config/zsh/`)

- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)

## Repository Layout

```
devcage-macos/
├── Brewfile                              # Homebrew packages
├── setup.sh                             # Setup automation
└── config/
    ├── com.mitchellh.ghostty/
    │   └── config.ghostty               # Ghostty terminal config
    ├── git/
    │   ├── config                       # Git config (aliases, colors, credential helpers)
    │   ├── gitignore_global             # Global gitignore
    │   └── ignore                       # Additional global ignores
    ├── starship/
    │   └── starship.toml                # Starship prompt config
    ├── vim/
    │   ├── vimrc                        # Vim config (vim-plug, coc.nvim, airline)
    │   ├── colors/                      # Custom color schemes
    │   └── ftplugin/                    # Filetype-specific settings
    └── zsh/
        ├── .zshenv                      # Sets ZDOTDIR, sources Cargo env
        └── .zshrc                       # Shell config, aliases, history, plugins
```

## Symlinks

`setup.sh` creates the following symlinks so macOS config paths point into this repo:

| Symlink | Points to |
|---------|-----------|
| `~/.zshenv` | `config/zsh/.zshenv` |
| `~/.config/zsh` | `config/zsh/` |
| `~/.config/git` | `config/git/` |
| `~/.config/vim` | `config/vim/` |
| `~/.config/starship` | `config/starship/` |
| `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` | `config/com.mitchellh.ghostty/config.ghostty` |

Zsh uses XDG-style config via `ZDOTDIR=$HOME/.config/zsh` (set in `~/.zshenv`).

## SSH Key

Copy your existing `id_ed25519` and `id_ed25519.pub` into `~/.ssh` before running `setup.sh`. The script will load the key into the macOS Keychain via `ssh-add --apple-use-keychain`.
