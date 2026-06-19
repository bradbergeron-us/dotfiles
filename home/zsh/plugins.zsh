# plugins.zsh — shell plugins and completion initialization.

# Zsh plugins — managed declaratively by sheldon (config: ~/.config/sheldon/plugins.toml).
# Falls back to manually-cloned plugins under ~/.zsh so a machine without sheldon
# (e.g. before bootstrap installs it) still gets highlighting + autosuggestions.
if command -v sheldon &>/dev/null; then
  eval "$(sheldon source)"
else
  [ -f "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ] && \
    source "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  [ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
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
