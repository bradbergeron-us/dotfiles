# functions.zsh — shell functions and zsh hooks.
# Sourced before aliases (matching the original zshrc order).

# ------------------
# Zsh hooks
# ------------------

autoload -U add-zsh-hook

# Check if Claude Code is active (cached for performance)
# Only checks once per shell session to avoid slowdown
__DOTFILES_CLAUDE_SESSION_CACHED=""
function _is_claude_session() {
  # Return cached result if already checked
  [[ -n "$__DOTFILES_CLAUDE_SESSION_CACHED" ]] && return $__DOTFILES_CLAUDE_SESSION_CACHED

  # Fast checks first (environment variables - nearly free)
  if [[ -n "$CLAUDE_CODE_ENTRYPOINT" ]] || [[ -n "$CLAUDE_CODE_SESSION_ID" ]] || \
     [[ -n "$CLAUDE_CODE_USE_BEDROCK" ]] || [[ -n "$ANTHROPIC_MODEL" ]] || \
     [[ "$TERM_PROGRAM" == *"claude"* ]]; then
    __DOTFILES_CLAUDE_SESSION_CACHED=0
    return 0
  fi

  # Quick parent process check (avoid expensive tree walk)
  if pgrep -P $$ claude &>/dev/null; then
    __DOTFILES_CLAUDE_SESSION_CACHED=0
    return 0
  fi

  # Not in Claude Code session
  __DOTFILES_CLAUDE_SESSION_CACHED=1
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
# Simplified version without background updater for performance
function _set_terminal_title() {
  local show_claude="no"
  _is_claude_session && show_claude="yes"

  local title="$(_format_tab_title "$PWD" "$show_claude")"
  print -Pn "\e]0;${title}\a"
}

# Register hooks to update title on:
# - precmd: before each prompt
# - chpwd: when directory changes
add-zsh-hook precmd _set_terminal_title
add-zsh-hook chpwd _set_terminal_title

# Set initial title on shell startup
_set_terminal_title

# ------------------
# Git helper functions
# ------------------

grn() { git rebase -i HEAD~"$1"; }
grbic() { git rebase -i "$1"; }

# ------------------
# Terminal helpers
# ------------------

# Source terminal helper functions from scripts directory
# Provides: reset_terminal_preference, get_terminal_emulator, open_terminal_tab
if [[ -f "$DOTFILES_DIR/scripts/lib/terminal_helpers.sh" ]]; then
  source "$DOTFILES_DIR/scripts/lib/terminal_helpers.sh"
fi
