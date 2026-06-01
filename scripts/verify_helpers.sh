#!/usr/bin/env bash
# verify_helpers.sh — pure/testable helpers sourced by verify.sh
# No side effects, no interactive prompts, no exits.
# shellcheck disable=SC2034  # variables are used by callers that source this file

# ── Symlink map ───────────────────────────────────────────────────────────────
# Each entry is "src_relative_to_DOTFILES_DIR:dest_relative_to_HOME"
DOTFILES_SYMLINKS=(
  "zshrc:.zshrc"
  "zprofile:.zprofile"
  "gitconfig:.gitconfig"
  "tmux.conf:.tmux.conf"
  "hyper.js:.hyper.js"
  "gitignore_global:.gitignore_global"
  "gemrc:.gemrc"
  "irbrc:.irbrc"
  "pryrc:.pryrc"
  "psqlrc:.psqlrc"
  "npmrc:.npmrc"
  "editorconfig:.editorconfig"
  "config/starship.toml:.config/starship.toml"
  "config/direnvrc:.config/direnv/direnvrc"
  "config/mise.toml:.config/mise/config.toml"
  "ssh_config:.ssh/config"
)

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

# check_mise_version_drift TOML_FILE BOOTSTRAP_FILE
# Compares runtime versions in config/mise.toml against the pinned versions in bootstrap.sh.
# Detects drift introduced by editing one file without updating the other.
# Sets:
#   DRIFT_COUNT — number of mismatches
#   DRIFT_LIST  — array of "tool: mise.toml=X  bootstrap.sh=Y" descriptions
check_mise_version_drift() {
  local toml_file="$1"
  local bootstrap_file="$2"
  DRIFT_COUNT=0
  DRIFT_LIST=()

  local tools=(ruby node java python go)

  for tool in "${tools[@]}"; do
    # Extract from mise.toml: tool = "version"
    local toml_ver
    toml_ver=$(grep -E "^${tool}[[:space:]]*=" "$toml_file" 2>/dev/null \
      | sed 's/.*=[[:space:]]*"\(.*\)".*/\1/' | tr -d '[:space:]')

    # Extract from bootstrap.sh: mise install ...tool@version...
    local bootstrap_ver
    bootstrap_ver=$(grep -oE "${tool}@[^[:space:]]+" "$bootstrap_file" 2>/dev/null \
      | head -1 | sed "s/${tool}@//")

    # Skip tools not tracked in either file
    [[ -z "$toml_ver" && -z "$bootstrap_ver" ]] && continue

    if [[ -z "$toml_ver" ]]; then
      DRIFT_COUNT=$(( DRIFT_COUNT + 1 ))
      DRIFT_LIST+=("$tool: present in bootstrap.sh ($bootstrap_ver) but missing from mise.toml")
      continue
    fi

    if [[ -z "$bootstrap_ver" ]]; then
      DRIFT_COUNT=$(( DRIFT_COUNT + 1 ))
      DRIFT_LIST+=("$tool: present in mise.toml ($toml_ver) but not found in bootstrap.sh")
      continue
    fi

    if [[ "$toml_ver" != "$bootstrap_ver" ]]; then
      DRIFT_COUNT=$(( DRIFT_COUNT + 1 ))
      DRIFT_LIST+=("$tool: mise.toml=$toml_ver  bootstrap.sh=$bootstrap_ver")
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
