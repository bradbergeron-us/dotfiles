#!/usr/bin/env bash
# verify_helpers.sh — pure/testable helpers sourced by verify.sh
# No side effects, no interactive prompts, no exits.
# shellcheck disable=SC2034  # variables are used by callers that source this file

# ── Symlink map ───────────────────────────────────────────────────────────
# The canonical dotfile→destination mapping lives in config/symlinks.map (the
# single source of truth shared with install.sh, bootstrap --dry-run, and CI).
# load_symlink_map reads it into DOTFILES_SYMLINKS as
# "src_relative_to_DOTFILES_DIR:dest_relative_to_HOME" entries — the form
# check_symlinks consumes. Defaults to empty so the array is always set.
DOTFILES_SYMLINKS=()

# load_symlink_map MANIFEST
# Populates DOTFILES_SYMLINKS from a symlinks.map manifest of "src dest" records
# (whitespace-separated; blank lines and # comments ignored). A missing manifest
# leaves the array empty.
load_symlink_map() {
  local manifest="$1" src dest
  DOTFILES_SYMLINKS=()
  [[ -f "$manifest" ]] || return 0
  while read -r src dest; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    DOTFILES_SYMLINKS+=("$src:$dest")
  done < "$manifest"
}

# check_symlinks DOTFILES_DIR HOME_DIR
# Validates every entry in DOTFILES_SYMLINKS: source must exist in DOTFILES_DIR
# and the destination symlink must point to it exactly.
# Sets:
#   SYMLINK_OK_COUNT     — correctly linked symlinks
#   SYMLINK_BROKEN_COUNT — broken/missing/wrong-target symlinks
#   SYMLINK_BROKEN_LIST  — array of human-readable problem descriptions
check_symlinks() {
  local dotfiles_dir="$1"
  local home_dir="$2"
  SYMLINK_OK_COUNT=0
  SYMLINK_BROKEN_COUNT=0
  SYMLINK_BROKEN_LIST=()

  [[ "${#DOTFILES_SYMLINKS[@]}" -eq 0 ]] && return 0

  for pair in "${DOTFILES_SYMLINKS[@]}"; do
    local src_rel="${pair%%:*}"
    local dest_rel="${pair##*:}"
    local src="$dotfiles_dir/$src_rel"
    local dest="$home_dir/$dest_rel"

    # Source file must exist in the dotfiles checkout
    if [[ ! -e "$src" ]]; then
      SYMLINK_BROKEN_COUNT=$(( SYMLINK_BROKEN_COUNT + 1 ))
      SYMLINK_BROKEN_LIST+=("$dest_rel  ← source missing in dotfiles: $src_rel")
      continue
    fi

    if [[ -L "$dest" ]]; then
      local actual_target
      actual_target=$(readlink "$dest")
      if [[ "$actual_target" == "$src" ]]; then
        SYMLINK_OK_COUNT=$(( SYMLINK_OK_COUNT + 1 ))
      else
        SYMLINK_BROKEN_COUNT=$(( SYMLINK_BROKEN_COUNT + 1 ))
        SYMLINK_BROKEN_LIST+=("$dest_rel  ← wrong target (run install.sh)")
      fi
    elif [[ -e "$dest" ]]; then
      SYMLINK_BROKEN_COUNT=$(( SYMLINK_BROKEN_COUNT + 1 ))
      SYMLINK_BROKEN_LIST+=("$dest_rel  ← plain file, not a symlink (run install.sh)")
    else
      SYMLINK_BROKEN_COUNT=$(( SYMLINK_BROKEN_COUNT + 1 ))
      SYMLINK_BROKEN_LIST+=("$dest_rel  ← missing (run install.sh)")
    fi
  done
}

# check_required_tools TOOL [TOOL ...]
# Checks each named tool is available on PATH via command -v.
# Sets:
#   TOOLS_PRESENT_COUNT — number of tools found
#   TOOLS_MISSING_COUNT — number of tools not found
#   TOOLS_MISSING_LIST  — array of missing tool names
check_required_tools() {
  TOOLS_PRESENT_COUNT=0
  TOOLS_MISSING_COUNT=0
  TOOLS_MISSING_LIST=()

  for tool in "$@"; do
    if command -v "$tool" &>/dev/null; then
      TOOLS_PRESENT_COUNT=$(( TOOLS_PRESENT_COUNT + 1 ))
    else
      TOOLS_MISSING_COUNT=$(( TOOLS_MISSING_COUNT + 1 ))
      TOOLS_MISSING_LIST+=("$tool")
    fi
  done
}

# check_ssh_key [KEY_FILE]
# Checks that the SSH key file exists and is loaded in the SSH agent.
# Defaults to ~/.ssh/id_ed25519 when KEY_FILE is omitted.
# Sets:
#   SSH_KEY_OK    — true if key file exists and agent has it loaded
#   SSH_KEY_ISSUE — human-readable problem description (empty when OK)
check_ssh_key() {
  local key_file="${1:-$HOME/.ssh/id_ed25519}"
  SSH_KEY_OK=false
  SSH_KEY_ISSUE=""

  if [[ ! -f "$key_file" ]]; then
    SSH_KEY_ISSUE="$key_file not found — run bootstrap.sh to generate"
    return
  fi

  local fingerprint
  fingerprint=$(ssh-keygen -lf "$key_file" 2>/dev/null | awk '{print $2}') || true

  if [[ -z "$fingerprint" ]]; then
    SSH_KEY_ISSUE="could not read fingerprint from $key_file"
    return
  fi

  if ssh-add -l 2>/dev/null | grep -qF "$fingerprint"; then
    SSH_KEY_OK=true
  else
    SSH_KEY_ISSUE="key not loaded in SSH agent — run: ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
  fi
}

# check_git_lfs_global
# Checks that git-lfs is installed and initialized in the global git config.
# Sets:
#   GIT_LFS_OK    — true if git-lfs is installed and globally initialized
#   GIT_LFS_ISSUE — human-readable problem description (empty when OK)
check_git_lfs_global() {
  GIT_LFS_OK=false
  GIT_LFS_ISSUE=""

  if ! command -v git-lfs &>/dev/null; then
    GIT_LFS_ISSUE="git-lfs not installed — run: brew install git-lfs"
    return
  fi

  local clean_filter
  clean_filter=$(git config --global filter.lfs.clean 2>/dev/null) || true

  if [[ -n "$clean_filter" ]]; then
    GIT_LFS_OK=true
  else
    GIT_LFS_ISSUE="git-lfs not initialized globally — run: git lfs install --skip-repo"
  fi
}

# check_mise_installed TOML_FILE
# Checks that the tools declared in TOML_FILE are actually installed via mise.
# Silently skips if mise is not on PATH (check_required_tools covers that).
# Sets:
#   MISE_UNINSTALLED_COUNT — number of tools not installed
#   MISE_UNINSTALLED_LIST  — array of problem descriptions
check_mise_installed() {
  local toml_file="$1"
  MISE_UNINSTALLED_COUNT=0
  MISE_UNINSTALLED_LIST=()

  command -v mise &>/dev/null || return 0

  # Derive the runtime list from mise.toml (the single source of truth) via
  # parse_mise_runtimes (from bootstrap_helpers.sh, which verify.sh sources
  # before this file), so a tool added to or removed from mise.toml is
  # reflected here automatically.
  local entry tool toml_ver
  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    tool="${entry%@*}"
    toml_ver="${entry#*@}"
    if ! mise where "$tool" &>/dev/null 2>&1; then
      MISE_UNINSTALLED_COUNT=$(( MISE_UNINSTALLED_COUNT + 1 ))
      MISE_UNINSTALLED_LIST+=("$tool@$toml_ver not installed — run: mise install")
    fi
  done < <(parse_mise_runtimes "$toml_file")
}

# check_dotfiles_git_health DOTFILES_DIR
# Repository/config integrity guard:
#   1. No tracked dotfile contains git merge-conflict markers.
#   2. `git config --list` parses cleanly (catches a broken ~/.gitconfig before
#      install.sh symlinks gitconfig over it).
# Sets:
#   DOTFILES_GIT_HEALTH_OK     — true when both checks pass
#   DOTFILES_GIT_HEALTH_ISSUES — array of human-readable problems (empty when OK)
#   DOTFILES_CONFLICT_FILES    — array of tracked files containing markers
check_dotfiles_git_health() {
  local dotfiles_dir="$1"
  DOTFILES_GIT_HEALTH_OK=true
  DOTFILES_GIT_HEALTH_ISSUES=()
  DOTFILES_CONFLICT_FILES=()

  # Build conflict-marker patterns at runtime so this source file never
  # contains a literal 7-character marker that would match itself.
  local _b _s _e marker_re
  _b=$(printf '<%.0s' {1..7})
  _s=$(printf '=%.0s' {1..7})
  _e=$(printf '>%.0s' {1..7})
  marker_re="^${_b}|^${_e}|^${_s}\$"

  if git -C "$dotfiles_dir" rev-parse --is-inside-work-tree &>/dev/null; then
    local matches
    matches=$(git -C "$dotfiles_dir" grep -lE "$marker_re" -- . 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        DOTFILES_CONFLICT_FILES+=("$f")
        DOTFILES_GIT_HEALTH_ISSUES+=("conflict markers in tracked file: $f")
      done <<< "$matches"
      DOTFILES_GIT_HEALTH_OK=false
    fi
  else
    DOTFILES_GIT_HEALTH_ISSUES+=("$dotfiles_dir is not a git work tree — cannot scan tracked files")
    DOTFILES_GIT_HEALTH_OK=false
  fi

  if ! git config --list &>/dev/null; then
    DOTFILES_GIT_HEALTH_ISSUES+=("git config --list failed — ~/.gitconfig may be broken")
    DOTFILES_GIT_HEALTH_OK=false
  fi
}

# check_brewfile_drift BREWFILE
# Detects divergence between installed Homebrew packages and the Brewfile via
# `brew bundle check`. Silently skips when brew is not on PATH (check_required_tools
# already reports a missing brew).
# Sets:
#   BREWFILE_DRIFT_OK      — true when packages match the Brewfile (or skipped)
#   BREWFILE_DRIFT_SKIPPED — true when brew is unavailable
#   BREWFILE_DRIFT_ISSUE   — human-readable problem description (empty when OK)
check_brewfile_drift() {
  local brewfile="$1"
  BREWFILE_DRIFT_OK=true
  BREWFILE_DRIFT_SKIPPED=false
  BREWFILE_DRIFT_ISSUE=""

  if ! command -v brew &>/dev/null; then
    BREWFILE_DRIFT_SKIPPED=true
    return 0
  fi

  if [[ ! -f "$brewfile" ]]; then
    BREWFILE_DRIFT_OK=false
    BREWFILE_DRIFT_ISSUE="Brewfile not found at $brewfile"
    return 0
  fi

  if brew bundle check --file="$brewfile" &>/dev/null; then
    BREWFILE_DRIFT_OK=true
  else
    BREWFILE_DRIFT_OK=false
    BREWFILE_DRIFT_ISSUE="installed packages diverge from Brewfile — run: brew bundle install --file=$brewfile"
  fi
}

# check_stale_backups BACKUP_DIR [DAYS]
# Finds backup directories inside BACKUP_DIR that are older than DAYS (default: 30).
# Sets:
#   STALE_BACKUP_COUNT — number of stale backup dirs found
#   STALE_BACKUP_LIST  — array of stale backup directory paths
check_stale_backups() {
  local backup_dir="$1"
  local days="${2:-30}"
  STALE_BACKUP_COUNT=0
  STALE_BACKUP_LIST=()

  [[ -d "$backup_dir" ]] || return 0

  while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    STALE_BACKUP_COUNT=$(( STALE_BACKUP_COUNT + 1 ))
    STALE_BACKUP_LIST+=("$entry")
  done < <(find "$backup_dir" -mindepth 1 -maxdepth 1 -type d -mtime +"$days" 2>/dev/null)
}
