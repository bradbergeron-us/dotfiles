# integrations.zsh — third-party tool integrations.

# zoxide — smarter cd (`z <dir>` jumps to frecent directories)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# direnv — per-directory environment variables (.envrc files)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Angular CLI autocompletion (disabled for performance - enable if needed)
# if command -v node &>/dev/null && command -v ng &>/dev/null; then
#   source <(ng completion script)
# fi
