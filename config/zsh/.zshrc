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
bindkey '^a' beginning-of-line

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
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# ============================================================
# Aliases
# ============================================================
alias ls='lsd'
alias ll='ls -alh'

# ============================================================
# Agents
# ============================================================
# Run the coordinating Claude Code inside hc, so the workers it starts are its
# children and can report back to it. Reattaches if it is already running.
# hc-pane reads the tmux pane labels to open workers beside it.
lead() {
    local name=${1:-lead}
    if [ -z "$TMUX" ]; then
        echo "lead: run it inside tmux" >&2
        return 1
    fi
    # --rm because hc get also matches finished terminals, which would block a restart
    hc get "$name" >/dev/null 2>&1 || hc run --bg --rm --no-parent --name "$name" --cwd "$PWD" claude >/dev/null || return
    hc label "$name" tmux_pane="$TMUX_PANE" tmux_socket="${TMUX%%,*}" >/dev/null
    hc attach "$name"
}

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
