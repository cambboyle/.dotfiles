# =============================================================================
# PATH
# =============================================================================

export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# HOMEBREW
# =============================================================================

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# =============================================================================
# TMUX AUTO-START
# =============================================================================

if [ -z "$TMUX" ]; then
    ~/.config/tmux/start.sh
    tmux attach -t dev
fi

# =============================================================================
# ZINIT — PLUGIN MANAGER
# =============================================================================

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# =============================================================================
# HISTORY
# =============================================================================

HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# =============================================================================
# KEYBINDINGS
# =============================================================================

bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# =============================================================================
# COMPLETION STYLING
# =============================================================================

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# =============================================================================
# ALIASES — GENERAL
# =============================================================================

alias ls='ls --color'
alias c='clear'

# =============================================================================
# ALIASES — MISC
# =============================================================================

alias rain='z terminal-rain/build && ./terminal-rain'
alias zdocker='zellij --layout ~/.config/zellij/layouts/docker.kdl'

# =============================================================================
# SHELL INTEGRATIONS
# =============================================================================

eval "$(fzf --zsh)" 
eval "$(zoxide init zsh)" 
eval "$(oh-my-posh init zsh --config ~/config.omp.json)" 

# Load private/local config
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
