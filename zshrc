# ------------------
# Shell Variables
# ------------------

export EDITOR=code
export NVM_DIR="$HOME/.nvm"

# ------------------
# PATH Manipulations
# ------------------

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

# chruby (guarded — install via: brew install chruby ruby-install)
if command -v brew &>/dev/null; then
  _chruby_sh="$(brew --prefix chruby 2>/dev/null)/share/chruby/chruby.sh"
  if [[ -f "$_chruby_sh" ]]; then
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3 2>/dev/null)"
    source "$_chruby_sh"
    source "${_chruby_sh:h}/auto.sh"
    chruby ruby-3.3.6 2>/dev/null || true
  fi
  unset _chruby_sh
fi

# Lazy-load NVM — defers sourcing until first use of nvm/node/npm/npx
_nvm_load() {
  unset -f nvm node npm npx
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"
}
nvm()  { _nvm_load; nvm  "$@"; }
node() { _nvm_load; node "$@"; }
npm()  { _nvm_load; npm  "$@"; }
npx()  { _nvm_load; npx  "$@"; }

export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# fzf (fuzzy finder — Ctrl+R history, Ctrl+T file picker)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ------------------
# Zsh hooks
# ------------------

autoload -U add-zsh-hook

load-nvmrc() {
  # Walk up dirs to find .nvmrc without eagerly loading NVM
  local dir="$PWD" nvmrc_path=""
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/.nvmrc" ]] && { nvmrc_path="$dir/.nvmrc"; break; }
    dir="${dir:h}"
  done

  if [[ -n "$nvmrc_path" ]]; then
    _nvm_load
    local nvmrc_node_version node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")") 
    node_version=$(nvm version)
    if [[ "$nvmrc_node_version" == "N/A" ]]; then
      echo "Installing Node version from .nvmrc..."
      nvm install
    elif [[ "$nvmrc_node_version" != "$node_version" ]]; then
      echo "Switching to Node version $nvmrc_node_version..."
      nvm use
    fi
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

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
alias gst='git status'
alias glog='git log --oneline --decorate --color --graph'

alias src='source ~/.zshrc'
alias c='clear'
alias edithost='sudo nano /etc/hosts'

alias ..='../..'
alias ...='../../..'
alias ....='../../../..'
alias .....='../../../../..'
alias la='ls -Ah'
alias l='colorls --group-directories-first --almost-all'
alias ll='colorls --group-directories-first --almost-all --long'
alias lc='colorls -lA --sd'
alias ls='colorls -h --group-directories-first -1'
alias change="code ~/.zshrc"
alias update="source ~/.zshrc"
alias history='history 0'

# bat (syntax-highlighted cat)
command -v bat &>/dev/null && alias cat='bat --paging=never'

eval "$(starship init zsh)"
test -f ~/afs_localprops.sh && source ~/afs_localprops.sh

# colorls completion (guarded)
if command -v colorls >/dev/null 2>&1; then
  colorls_gem_path=$(dirname $(gem which colorls 2>/dev/null) 2>/dev/null)
  if [[ -n "$colorls_gem_path" ]]; then
    if [[ -d "$colorls_gem_path/zsh" ]]; then
      fpath=("$colorls_gem_path/zsh" $fpath)
    fi
  fi
fi

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
compinit

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Angular CLI autocompletion
if command -v node &>/dev/null && command -v ng &>/dev/null; then
  CURRENT_NODE_VERSION=$(node -v 2>/dev/null)
  if [[ -n "$CURRENT_NODE_VERSION" && "$CURRENT_NODE_VERSION" != "v0."* ]]; then
    source <(ng completion script)
  fi
fi

# rbenv and pyenv if installed
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# Machine-specific overrides (not committed to dotfiles)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
. "$HOME/.local/bin/env"
