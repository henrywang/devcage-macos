# ZSH Configuration for Macbook Air M5

# ============================================================
# Plugins (loaded from ~/.config/zsh/)
# ============================================================
source "$HOME/.config/zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"
eval "$(starship init zsh)"

# ============================================================
# Shell History
# ============================================================
HISTFILE="$ZDOTDIR/.zsh_history"
setopt EXTENDED_HISTORY
SAVEHIST=5000
HISTSIZE=2000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# ============================================================
# Completion
# ============================================================
autoload -U colors && colors
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select

# ============================================================
# Options
# ============================================================
setopt AUTO_CD
setopt COMPLETE_ALIASES

# Vi mode
bindkey -v

# ============================================================
# Autosuggestion
# ============================================================
bindkey '^f' autosuggest-accept
ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ============================================================
# FZF Integration (env vars set via environment.d)
# ============================================================
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh

# ============================================================
# PATH
# ============================================================
export PATH="$HOME/bin:$PATH"

# ============================================================
# Agent workflow (see ~/devcage-macos/WORKFLOW.md)
# ============================================================
# One command to get to work: ensure the herdr server, ensure the inbox and its
# router pane, then attach. Every step is idempotent, so on a warm machine this
# just reattaches to what was already running.
work() {
  case "$(herdr status server 2>/dev/null || true)" in
    *"status: running"*) ;;
    *)
      (herdr server >/dev/null 2>&1 &)
      until herdr status server 2>/dev/null | grep -q 'status: running'; do sleep 0.2; done
      ;;
  esac
  wq up >/dev/null || return 1
  herdr
}

# ============================================================
# Aliases
# ============================================================
alias ls='lsd'
alias ll='ls -alh'

# ============================================================
# Terminal Integration (foot/ghostty compatible)
# ============================================================
function osc7-pwd() {
    emulate -L zsh
    setopt extendedglob
    local LC_ALL=C
    printf '\e]7;file://%s%s\e\' $HOST ${PWD//(#m)([^@-Za-z&-;_~])/%${(l:2::0:)$(([##16]#MATCH))}}
}

function chpwd-osc7-pwd() {
    (( ZSH_SUBSHELL )) || osc7-pwd
}
add-zsh-hook -Uz chpwd chpwd-osc7-pwd

# Shell integration for prompt marking
function precmd {
    if ! builtin zle; then
        print -n "\e]133;D\e\\"
    else
        print -Pn "\e]133;A\e\\"
    fi
}

function preexec {
    print -n "\e]133;C\e\\"
}

# ============================================================
# Syntax Highlighting & History Search (load last)
# ============================================================
source "$HOME/.config/zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$HOME/.config/zsh/zsh-history-substring-search/zsh-history-substring-search.zsh"
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
