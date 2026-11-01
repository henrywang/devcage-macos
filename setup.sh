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

# Scans third-party agent skills before they are added to config/.claude/skills.
echo "==> Installing SkillSpector..."
if ! command -v skillspector &>/dev/null && [ ! -x "$HOME/.local/bin/skillspector" ]; then
    uv tool install "git+https://github.com/NVIDIA/skillspector.git@v2.13.2"
fi

echo "==> Installing Claude Code..."
if ! command -v claude &>/dev/null; then
    npm install -g @anthropic-ai/claude-code
fi

echo "==> Installing pi..."
if ! command -v pi &>/dev/null; then
    curl -fsSL https://pi.dev/install.sh | sh
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

# zed
mkdir -p "$HOME/.config/zed"
ln -sf  "$DOTFILES/config/zed/settings.json" "$HOME/.config/zed/settings.json"

# ghostty
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
ln -sf  "$DOTFILES/config/com.mitchellh.ghostty/config.ghostty" \
        "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

# claude code — global instructions, settings, agents, and skills
mkdir -p "$HOME/.claude/skills" "$HOME/.pi/agent/skills"
ln -sf  "$DOTFILES/config/.claude/.CLAUDE.md"   "$HOME/.claude/CLAUDE.md"
ln -sf  "$DOTFILES/config/.claude/settings.json" "$HOME/.claude/settings.json"
ln -sfn "$DOTFILES/config/.claude/agents"        "$HOME/.claude/agents"
# One symlink per skill, into both Claude and Pi. Linking the whole ~/.claude/skills
# into Pi would also pull in synced/, which Claude manages and which uses Claude-only tools.
for skill in "$DOTFILES"/config/.claude/skills/*/; do
    [ -d "$skill" ] || continue
    for skills_dir in "$HOME/.claude/skills" "$HOME/.pi/agent/skills"; do
        dest="$skills_dir/$(basename "$skill")"
        if [ -e "$dest" ] && [ ! -L "$dest" ]; then
            echo "    skipping $(basename "$skill"): $dest exists and is not a symlink"
        else
            ln -sfn "${skill%/}" "$dest"
        fi
    done
done

# pi — ~/.pi/agent/settings.json is rewritten by pi on upgrade, so it is left alone.
mkdir -p "$HOME/.pi/agent/prompts" "$HOME/.pi/agent/extensions" "$HOME/.pi/agent/skills"
ln -sf  "$DOTFILES/config/.claude/.CLAUDE.md" "$HOME/.pi/agent/AGENTS.md"

# ~/brain is a separate private repo (profile, current focus, knowledge base),
# so it is linked only when it has been cloned.
BRAIN="$HOME/brain"
if [ -d "$BRAIN" ]; then
    mkdir -p "$HOME/.claude/commands"
    ln -sfn "$BRAIN/skills/kb"        "$HOME/.claude/skills/kb"
    ln -sfn "$BRAIN/skills/kb"        "$HOME/.pi/agent/skills/kb"
    ln -sf  "$BRAIN/prompts/learn.md" "$HOME/.claude/commands/learn.md"
    ln -sf  "$BRAIN/prompts/learn.md" "$HOME/.pi/agent/prompts/learn.md"
fi

for ext in "$DOTFILES"/config/.pi/extensions/*.ts; do
    [ -e "$ext" ] || continue   # unmatched glob stays literal; set -e would abort on it
    ln -sf "$ext" "$HOME/.pi/agent/extensions/$(basename "$ext")"
done
# One symlink per skill, so skills installed by pi itself stay untouched.
for skill in "$DOTFILES"/config/.pi/skills/*/; do
    [ -d "$skill" ] || continue
    dest="$HOME/.pi/agent/skills/$(basename "$skill")"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        # Linking onto a real directory would nest the link inside it instead.
        echo "    skipping $(basename "$skill"): $dest exists and is not a symlink"
    else
        ln -sfn "${skill%/}" "$dest"
    fi
done

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
