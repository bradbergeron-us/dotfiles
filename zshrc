# ------------------
# Shell Variables
# ------------------

export EDITOR=code

# ------------------
# PATH Manipulations
# ------------------

# NVM conflict guard: if NVM is still installed on this machine but empty
# (no versions), suppress it so mise owns Node cleanly.
# NVM has been removed from this machine; this guard is a safety net for
# any env that still has a ghost NVM_DIR set (e.g. .zshrc.local, /etc/zshenv).
if [[ -n "${NVM_DIR:-}" ]]; then
  _nvm_node_dir="${NVM_DIR}/versions/node"
  if [[ ! -d "$_nvm_node_dir" ]] || [[ -z "$(ls -A "$_nvm_node_dir" 2>/dev/null)" ]]; then
    unset NVM_DIR  # ghost install — mise owns Node, nothing is lost
  fi
  unset _nvm_node_dir
fi

# mise — polyglot version manager (replaces chruby + nvm + pyenv)
# Reads .ruby-version, .nvmrc, .python-version automatically per project
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# Rust (cargo) — add to PATH if rustup is installed
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Go — tools installed via `go install` land in ~/go/bin
export GOPATH="${GOPATH:-$HOME/go}"
[[ -d "$GOPATH/bin" ]] && export PATH="$PATH:$GOPATH/bin"

export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# fzf (fuzzy finder — Ctrl+R history, Ctrl+T file picker)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ------------------
# Zsh hooks
# ------------------

autoload -U add-zsh-hook

function tabTitle() {
  echo -ne "\033]0;${PWD##*/}\007"
}
add-zsh-hook precmd tabTitle

# ------------------
# Aliases
# ------------------

alias gcm="git commit -m"
alias gcam='git commit -a -m'
alias gca="git commit --amend --no-edit"
alias gcae="git commit --amend"
alias gcaa="git add --all && git commit --amend --no-edit"
alias gcaae="git add --all && git commit --amend"
alias gap="git add -p"
alias gnope="git checkout ."
alias gwait="git reset HEAD"
alias gundo="git reset --soft HEAD^"
alias greset="git clean -f && git reset --hard HEAD"
alias gl="git log --graph --pretty='%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias glb='git log --oneline --decorate --graph --all'
alias gst='git status -s'
alias gpl="git pull --rebase"
alias gps="git push"
alias gpsf="git push --force-with-lease"
alias grb="git rebase"
alias grbi='git rebase -i'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias gcmb="git branch --merged | grep -Ev '(^\\*|master)' | xargs git branch -d"
alias gset='git branch --set-upstream-to=origin/`git symbolic-ref --short HEAD`'
grn() { git rebase -i HEAD~"$1"; }
grbic() { git rebase -i "$1"; }

alias gp='git pull'
alias gco='git checkout'
alias glog='git log --oneline --decorate --color --graph'

alias src='source ~/.zshrc'
alias c='clear'
alias edithost='sudo nano /etc/hosts'

alias ..='../..'
alias ...='../../..'
alias ....='../../../..'
alias .....='../../../../..'
alias ls='lsd --group-dirs first'
alias la='lsd -A'
alias l='lsd -A --group-dirs first'
alias ll='lsd -lA --group-dirs first'
alias lc='lsd -lA --group-dirs first --sort date'
alias change="code ~/.zshrc"
alias update="source ~/.zshrc"
alias history='history 0'

# bat (syntax-highlighted cat)
command -v bat &>/dev/null && alias cat='bat --paging=never'

eval "$(starship init zsh)"
test -f ~/afs_localprops.sh && source ~/afs_localprops.sh

# Optional plugins if installed
if [ -f "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]; then
  source "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi

if [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Enable enhanced menu selection in completions
zmodload -i zsh/complist 2>/dev/null || true

autoload -Uz compinit
# Only rebuild completion dump once per day — saves ~30-50ms per shell start
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# direnv — per-directory environment variables (.envrc files)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Angular CLI autocompletion
if command -v node &>/dev/null && command -v ng &>/dev/null; then
  CURRENT_NODE_VERSION=$(node -v 2>/dev/null)
  if [[ -n "$CURRENT_NODE_VERSION" && "$CURRENT_NODE_VERSION" != "v0."* ]]; then
    source <(ng completion script)
  fi
fi

# Machine-specific overrides (not committed to dotfiles)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
# uv (Python package manager) shell integration — only if installed
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
