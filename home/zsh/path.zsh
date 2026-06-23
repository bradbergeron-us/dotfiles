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

# dotfiles man page — make `man dotfiles` work (man/man1/dotfiles.1). The
# trailing colon (when MANPATH is empty) keeps the system man paths searched.
[[ -n "${DOTFILES_DIR:-}" && -d "$DOTFILES_DIR/man" ]] && export MANPATH="$DOTFILES_DIR/man:${MANPATH:-}"

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

# Rust — the official rustup installer writes ~/.cargo/env; Homebrew's keg-only
# rustup instead keeps its proxies (cargo, rustc, ...) under
# <brew prefix>/opt/rustup/bin and does NOT put them on PATH. Handle both,
# without shelling out to `brew` (HOMEBREW_PREFIX is exported by zprofile).
if [[ -f "$HOME/.cargo/env" ]]; then
  . "$HOME/.cargo/env"
else
  for _rustup_bin in "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/rustup/bin" /usr/local/opt/rustup/bin; do
    [[ -d "$_rustup_bin" ]] && { export PATH="$_rustup_bin:$PATH"; break; }
  done
  unset _rustup_bin
fi

# Go — tools installed via `go install` land in ~/go/bin
export GOPATH="${GOPATH:-$HOME/go}"
[[ -d "$GOPATH/bin" ]] && export PATH="$PATH:$GOPATH/bin"

# Go module proxy — use JFrog Artifactory (corporate network requirement)
# Falls back to direct if proxy is unavailable
export GOPROXY="https://jfrog.accenturefederaldev.com/artifactory/afs-vgo-proxy/,direct"

# Local binaries (Claude Code, pipx, etc.)
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# fzf (fuzzy finder — Ctrl+R history, Ctrl+T file picker)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
