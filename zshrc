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

# Local binaries (Claude Code, pipx, etc.)
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# fzf (fuzzy finder — Ctrl+R history, Ctrl+T file picker)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ------------------
# Zsh hooks
# ------------------

autoload -U add-zsh-hook

# Fast Claude Code detection with caching
# Checks if this specific shell is running under Claude Code
_CLAUDE_SESSION_CACHE=""
_CLAUDE_SESSION_CACHE_TIME=0

function _is_claude_session() {
  local now=$(date +%s)
  local cache_ttl=5  # Cache result for 5 seconds

  # Return cached result if still valid
  if (( now - _CLAUDE_SESSION_CACHE_TIME < cache_ttl )); then
    [[ "$_CLAUDE_SESSION_CACHE" == "yes" ]] && return 0 || return 1
  fi

  # Fast check: is 'claude' a direct child process?
  if pgrep -P $$ -q claude 2>/dev/null; then
    _CLAUDE_SESSION_CACHE="yes"
    _CLAUDE_SESSION_CACHE_TIME=$now
    return 0
  fi

  # Quick process tree check (max 5 levels, more efficient)
  local pid=$PPID
  local depth=0
  while [[ $pid -gt 1 ]] && (( depth < 5 )); do
    local cmd=$(ps -o comm= -p "$pid" 2>/dev/null)
    if [[ "$cmd" == *"claude"* ]]; then
      _CLAUDE_SESSION_CACHE="yes"
      _CLAUDE_SESSION_CACHE_TIME=$now
      return 0
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [[ -z "$pid" ]] && break
    ((depth++))
  done

  _CLAUDE_SESSION_CACHE="no"
  _CLAUDE_SESSION_CACHE_TIME=$now
  return 1
}

# Format current directory for tab title display
# Shows last 3 directory components (or full path if shorter)
# Appends indicator if Claude Code is running
function _format_tab_title() {
  local short_path="${1:-$PWD}"
  local show_claude="${2:-no}"

  # Replace home directory with tilde
  short_path="${short_path/#$HOME/~}"

  # Handle root directory edge case
  if [[ "$short_path" == "/" ]]; then
    short_path="/"
  else
    local path_parts=(${(s:/:)short_path})
    if (( ${#path_parts} > 3 )); then
      short_path=".../${path_parts[-3]}/${path_parts[-2]}/${path_parts[-1]}"
    fi
  fi

  # Append Claude Code indicator if requested
  if [[ "$show_claude" == "yes" ]]; then
    echo "${short_path} ⚡"
  else
    echo "$short_path"
  fi
}

# Update terminal tab title with current directory
# Uses both OSC 0 (icon + title) and OSC 2 (title only) for compatibility
function _set_terminal_title() {
  local show_claude="no"
  _is_claude_session && show_claude="yes"

  local title="$(_format_tab_title "$PWD" "$show_claude")"
  print -Pn "\e]0;${title}\a"
  print -Pn "\e]2;${title}\a"
}

# Register hooks to update title aggressively
add-zsh-hook precmd _set_terminal_title   # Before each prompt
add-zsh-hook chpwd _set_terminal_title    # When directory changes
add-zsh-hook preexec _set_terminal_title  # Before command execution

# Set initial title on shell startup
_set_terminal_title

# Aggressive override for Claude Code: update on every line editor action
# This makes the title update extremely responsive
function _zle_title_update() {
  _set_terminal_title
}

# Create a self-insert widget wrapper to update title on every keystroke
# Only do this if Claude Code is potentially running (has performance cost)
if [[ -n "$PPID" ]]; then
  local parent_cmd=$(ps -o comm= -p "$PPID" 2>/dev/null)
  if [[ "$parent_cmd" == *"claude"* ]]; then
    # We're in Claude Code - set up aggressive title updates
    zle -N _zle_title_update

    # Update title when line editor initializes
    function zle-line-init() {
      _set_terminal_title
    }
    zle -N zle-line-init

    # Update title on every keypress (aggressive but necessary for Claude)
    function zle-line-pre-redraw() {
      _set_terminal_title
    }
    zle -N zle-line-pre-redraw
  fi
fi

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
