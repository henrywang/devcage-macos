#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/devcage-macos"

echo "==> Checking Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    echo "    Install Xcode CLT, then re-run this script."
    exit 1
fi

echo "==> Installing Homebrew..."
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add /opt/homebrew/bin to PATH for the rest of this script.
    # On Apple Silicon, Homebrew lives at /opt/homebrew instead of /usr/local,
    # and the shell doesn't know about it until these exports are evaluated.
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

echo "==> Installing Homebrew packages..."
brew bundle --file="$DOTFILES/Brewfile"

echo "==> Installing Rust..."
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustup component add rustfmt clippy
fi

echo "==> Installing Claude Code..."
if ! command -v claude &>/dev/null; then
    npm install -g @anthropic-ai/claude-code
fi

echo "==> Installing instant-markdown-d (vim-instant-markdown daemon)..."
if ! command -v instant-markdown-d &>/dev/null; then
    npm install -g instant-markdown-d
fi

echo "==> Cloning zsh plugins..."
ZSH_DIR="$DOTFILES/config/zsh"
if [ ! -d "$ZSH_DIR/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_DIR/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_DIR/zsh-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_DIR/zsh-syntax-highlighting"
fi
if [ ! -d "$ZSH_DIR/zsh-history-substring-search" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search "$ZSH_DIR/zsh-history-substring-search"
fi

# Suppress "Last login: Tue Jun 23 00:34:09 on ttys001" when open ghostty terminal
echo "==> Suppressing last login message..."
touch "$HOME/.hushlogin"

echo "==> Creating symlinks..."
mkdir -p "$HOME/.config"

# zsh — ZDOTDIR is set to ~/.config/zsh via ~/.zshenv
ln -sf  "$DOTFILES/config/zsh/.zshenv"  "$HOME/.zshenv"
ln -sfn "$DOTFILES/config/zsh"          "$HOME/.config/zsh"

# git
ln -sfn "$DOTFILES/config/git"          "$HOME/.config/git"

# vim
mkdir -p "$HOME/.local/share/vim" "$HOME/.cache/vim/swap" "$HOME/.cache/vim/backup" "$HOME/.cache/vim/undo"
ln -sfn "$DOTFILES/config/vim"          "$HOME/.config/vim"

# starship
ln -sfn "$DOTFILES/config/starship"     "$HOME/.config/starship"

# ghostty
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
ln -sf  "$DOTFILES/config/com.mitchellh.ghostty/config.ghostty" \
        "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

# claude code — global instructions applied to every project
mkdir -p "$HOME/.claude"
ln -sf  "$DOTFILES/config/.claude/.CLAUDE.md"  "$HOME/.claude/CLAUDE.md"

echo "==> Adding SSH key..."
# Copy your existing id_ed25519 and id_ed25519.pub into ~/.ssh before running this.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/id_ed25519"
ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"

echo ""
echo "==> Done. Open a new shell for all changes to take effect."
echo "    App Store apps still need manual installation:"
echo "      - 1Password"
echo "      - Xcode (optional, for iOS/macOS development)"
