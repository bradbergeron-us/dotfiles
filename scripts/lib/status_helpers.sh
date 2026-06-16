#!/usr/bin/env bash
# status_helpers.sh — pure, side-effect-free helpers sourced by status.sh.
#
# Each function either echoes a value or sets result globals (never prints UI or
# calls exit), so they are unit-testable against fixtures and temp git repos.
# shellcheck disable=SC2034  # GIT_STATE_* globals are consumed by the sourcing script

# read_kv_value FILE KEY — echo the raw value of a `KEY=value` line in FILE.
# Whitespace around the `=` is ignored, trailing whitespace is trimmed, full-line
# `#` comments are skipped (so `#` is preserved inside values), and the last
# assignment wins. Echoes nothing when the key is absent or the file is missing.
# Used to read logs/update.status, whose values (e.g. "Homebrew, Rust") may
# contain spaces and commas.
read_kv_value() {
  local file="$1" key="$2" line val=""
  [[ -f "$file" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^[[:space:]]*# ]]; then continue; fi  # skip full-line comments
    if [[ "$line" =~ ^[[:space:]]*"$key"[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      val="${BASH_REMATCH[1]}"
      val="${val%"${val##*[![:space:]]}"}"  # trim trailing whitespace
    fi
  done < "$file"
  printf '%s' "$val"
}

# git_state DIR — inspect the git work tree at DIR (read-only) and set globals:
#   GIT_STATE_BRANCH    branch name; "detached@<sha>" when detached; "" if not a repo
#   GIT_STATE_DIRTY     true if there are staged/unstaged changes to tracked files
#   GIT_STATE_UNTRACKED count of untracked, non-ignored files
#   GIT_STATE_UPSTREAM  true if the branch has a configured upstream
#   GIT_STATE_AHEAD     commits on HEAD not on the upstream
#   GIT_STATE_BEHIND    commits on the upstream not on HEAD
# Safe on a non-git directory: leaves the defaults below.
git_state() {
  local dir="$1"
  GIT_STATE_BRANCH=""
  GIT_STATE_DIRTY=false
  GIT_STATE_UNTRACKED=0
  GIT_STATE_UPSTREAM=false
  GIT_STATE_AHEAD=0
  GIT_STATE_BEHIND=0

  git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null || return 0

  GIT_STATE_BRANCH=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [[ "$GIT_STATE_BRANCH" == "HEAD" ]]; then
    # Detached HEAD: show a short SHA instead of the bare "HEAD".
    local _short
    _short=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || true)
    GIT_STATE_BRANCH="detached@${_short}"
  fi

  if ! git -C "$dir" diff --quiet 2>/dev/null || ! git -C "$dir" diff --cached --quiet 2>/dev/null; then
    GIT_STATE_DIRTY=true
  fi

  local _untracked
  _untracked=$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d '[:space:]')
  GIT_STATE_UNTRACKED=${_untracked:-0}

  # rev-list --left-right --count UPSTREAM...HEAD → "<behind>\t<ahead>"
  local counts
  if counts=$(git -C "$dir" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null); then
    GIT_STATE_UPSTREAM=true
    GIT_STATE_BEHIND=$(printf '%s' "$counts" | awk '{print $1}')
    GIT_STATE_AHEAD=$(printf '%s' "$counts" | awk '{print $2}')
  fi
}
