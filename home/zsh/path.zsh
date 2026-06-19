# path.zsh — PATH and environment setup.
# Sourced first by home/zshrc so later modules (and the prompt) see the full
# PATH and core environment.

# ------------------
# Shell Variables
# ------------------

export EDITOR=code

# ------------------
# PATH Manipulations
# ------------------

# dotfiles CLI — put the repo's bin/ on PATH so `dotfiles <command>` works.
# DOTFILES_DIR is resolved in home/zshrc from this file's real location.
[[ -n "${DOTFILES_DIR:-}" && -d "$DOTFILES_DIR/bin" ]] && export PATH="$DOTFILES_DIR/bin:$PATH"

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
