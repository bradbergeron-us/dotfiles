#!/usr/bin/env bash
# test_verify_helpers.sh — unit tests for verify_helpers.sh
# Usage: bash scripts/test_verify_helpers.sh
# shellcheck disable=SC1091,SC2030,SC2031,SC2034  # dynamic source; intentional subshell scoping; vars used by sourced fns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
  TESTS_PASSED=$(( TESTS_PASSED + 1 ))
  TESTS_RUN=$(( TESTS_RUN + 1 ))
  printf "  PASS  %s\n" "$1"
}

fail() {
  TESTS_FAILED=$(( TESTS_FAILED + 1 ))
  TESTS_RUN=$(( TESTS_RUN + 1 ))
  printf "  FAIL  %s — %s\n" "$1" "$2"
}

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ── Shared fake dotfiles dir ───────────────────────────────────────────────────
FAKE_DOTFILES="$TMPDIR_BASE/dotfiles"
mkdir -p "$FAKE_DOTFILES/config"
touch "$FAKE_DOTFILES/zshrc"
touch "$FAKE_DOTFILES/gitconfig"
touch "$FAKE_DOTFILES/config/mise.toml"

# ── check_symlinks ────────────────────────────────────────────────────────────
echo ""
echo "=== check_symlinks ==="

# Case 1: all correct symlinks
FAKE_HOME="$TMPDIR_BASE/home1"
mkdir -p "$FAKE_HOME/.config/mise"
ln -sf "$FAKE_DOTFILES/zshrc"            "$FAKE_HOME/.zshrc"
ln -sf "$FAKE_DOTFILES/gitconfig"        "$FAKE_HOME/.gitconfig"
ln -sf "$FAKE_DOTFILES/config/mise.toml" "$FAKE_HOME/.config/mise/config.toml"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=(
    "zshrc:.zshrc"
    "gitconfig:.gitconfig"
    "config/mise.toml:.config/mise/config.toml"
  )
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME"
  [[ "$SYMLINK_OK_COUNT"     -eq 3 ]] || { printf "  FAIL  ok count: expected 3, got %s\n"     "$SYMLINK_OK_COUNT";     exit 1; }
  [[ "$SYMLINK_BROKEN_COUNT" -eq 0 ]] || { printf "  FAIL  broken count: expected 0, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: all correct → OK=3, BROKEN=0"
else
  fail "check_symlinks: all correct" "subshell exited non-zero"
fi

# Case 2: one missing destination
FAKE_HOME2="$TMPDIR_BASE/home2"
mkdir -p "$FAKE_HOME2"
ln -sf "$FAKE_DOTFILES/zshrc" "$FAKE_HOME2/.zshrc"
# gitconfig symlink intentionally absent

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("zshrc:.zshrc" "gitconfig:.gitconfig")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME2"
  [[ "$SYMLINK_OK_COUNT"     -eq 1 ]] || { printf "  FAIL  ok count: expected 1, got %s\n"     "$SYMLINK_OK_COUNT";     exit 1; }
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: one missing destination → BROKEN=1"
else
  fail "check_symlinks: one missing destination" "subshell exited non-zero"
fi

# Case 3: symlink points to wrong target
FAKE_HOME3="$TMPDIR_BASE/home3"
mkdir -p "$FAKE_HOME3"
ln -sf "/some/completely/different/path" "$FAKE_HOME3/.zshrc"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("zshrc:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME3"
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: wrong symlink target → BROKEN=1"
else
  fail "check_symlinks: wrong symlink target" "subshell exited non-zero"
fi

# Case 4: destination is a plain file (not a symlink)
FAKE_HOME4="$TMPDIR_BASE/home4"
mkdir -p "$FAKE_HOME4"
echo "not a symlink" > "$FAKE_HOME4/.zshrc"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("zshrc:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME4"
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: plain file (not symlink) → BROKEN=1"
else
  fail "check_symlinks: plain file" "subshell exited non-zero"
fi

# Case 5: source file missing from dotfiles checkout
FAKE_HOME5="$TMPDIR_BASE/home5"
mkdir -p "$FAKE_HOME5"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=("nonexistent_src:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME5"
  [[ "$SYMLINK_BROKEN_COUNT" -eq 1 ]] || { printf "  FAIL  broken count: expected 1, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: source file missing in dotfiles → BROKEN=1"
else
  fail "check_symlinks: source file missing" "subshell exited non-zero"
fi

# Case 6: empty symlink list → all counts zero
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  DOTFILES_SYMLINKS=()
  check_symlinks "$FAKE_DOTFILES" "$FAKE_HOME"
  [[ "$SYMLINK_OK_COUNT"     -eq 0 ]] || { printf "  FAIL  ok: expected 0, got %s\n"     "$SYMLINK_OK_COUNT";     exit 1; }
  [[ "$SYMLINK_BROKEN_COUNT" -eq 0 ]] || { printf "  FAIL  broken: expected 0, got %s\n" "$SYMLINK_BROKEN_COUNT"; exit 1; }
); then
  pass "check_symlinks: empty DOTFILES_SYMLINKS → all counts zero"
else
  fail "check_symlinks: empty list" "subshell exited non-zero"
fi

# ── check_mise_version_drift ──────────────────────────────────────────────────
echo ""
echo "=== check_mise_version_drift ==="

TOML_MATCH="$TMPDIR_BASE/mise_match.toml"
TOML_DRIFT="$TMPDIR_BASE/mise_drift.toml"
TOML_MISSING_RUBY="$TMPDIR_BASE/mise_missing_ruby.toml"
BOOTSTRAP_REF="$TMPDIR_BASE/bootstrap_ref.sh"

cat > "$TOML_MATCH" << 'EOF'
[tools]
ruby = "3.3.6"
node = "22"
java = "temurin-21"
python = "3.12"
go = "1.24"
EOF

cat > "$TOML_DRIFT" << 'EOF'
[tools]
ruby = "3.3.0"
node = "20"
java = "temurin-21"
python = "3.12"
go = "1.24"
EOF

cat > "$TOML_MISSING_RUBY" << 'EOF'
[tools]
node = "22"
java = "temurin-21"
python = "3.12"
go = "1.24"
EOF

cat > "$BOOTSTRAP_REF" << 'EOF'
mise install ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
mise use --global ruby@3.3.6 node@22 java@temurin-21 python@3.12 go@1.24
EOF

# Case 1: no drift
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_MATCH" "$BOOTSTRAP_REF"
  [[ "$DRIFT_COUNT" -eq 0 ]] || { printf "  FAIL  drift: expected 0, got %s\n" "$DRIFT_COUNT"; exit 1; }
); then
  pass "check_mise_version_drift: matching versions → DRIFT=0"
else
  fail "check_mise_version_drift: matching versions" "subshell exited non-zero"
fi

# Case 2: 2 drifted tools (ruby 3.3.0 vs 3.3.6, node 20 vs 22)
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_DRIFT" "$BOOTSTRAP_REF"
  [[ "$DRIFT_COUNT" -eq 2 ]] || { printf "  FAIL  drift: expected 2, got %s\n" "$DRIFT_COUNT"; exit 1; }
); then
  pass "check_mise_version_drift: ruby+node drifted → DRIFT=2"
else
  fail "check_mise_version_drift: 2 drifted tools" "subshell exited non-zero"
fi

# Case 3: drift list names the correct tools
drift_items=$(
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_DRIFT" "$BOOTSTRAP_REF"
  printf '%s\n' "${DRIFT_LIST[@]}"
)
if echo "$drift_items" | grep -q "^ruby:"; then
  pass "check_mise_version_drift: DRIFT_LIST contains ruby entry"
else
  fail "check_mise_version_drift: DRIFT_LIST contains ruby entry" "got: $drift_items"
fi
if echo "$drift_items" | grep -q "^node:"; then
  pass "check_mise_version_drift: DRIFT_LIST contains node entry"
else
  fail "check_mise_version_drift: DRIFT_LIST contains node entry" "got: $drift_items"
fi

# Case 4: ruby absent from toml → detected as drift
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_mise_version_drift "$TOML_MISSING_RUBY" "$BOOTSTRAP_REF"
  [[ "$DRIFT_COUNT" -ge 1 ]] || { printf "  FAIL  drift: expected >= 1, got %s\n" "$DRIFT_COUNT"; exit 1; }
); then
  pass "check_mise_version_drift: ruby missing from toml → DRIFT>=1"
else
  fail "check_mise_version_drift: ruby missing from toml" "subshell exited non-zero"
fi

# ── check_required_tools ──────────────────────────────────────────────────────
echo ""
echo "=== check_required_tools ==="

# Case 1: all present (universally available commands)
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools bash cat ls
  [[ "$TOOLS_PRESENT_COUNT" -eq 3 ]] || { printf "  FAIL  present: expected 3, got %s\n" "$TOOLS_PRESENT_COUNT"; exit 1; }
  [[ "$TOOLS_MISSING_COUNT" -eq 0 ]] || { printf "  FAIL  missing: expected 0, got %s\n" "$TOOLS_MISSING_COUNT"; exit 1; }
); then
  pass "check_required_tools: all present (bash, cat, ls) → MISSING=0"
else
  fail "check_required_tools: all present" "subshell exited non-zero"
fi

# Case 2: one clearly non-existent tool
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools bash __nonexistent_tool_xyz__
  [[ "$TOOLS_PRESENT_COUNT" -eq 1 ]] || { printf "  FAIL  present: expected 1, got %s\n" "$TOOLS_PRESENT_COUNT"; exit 1; }
  [[ "$TOOLS_MISSING_COUNT" -eq 1 ]] || { printf "  FAIL  missing: expected 1, got %s\n" "$TOOLS_MISSING_COUNT"; exit 1; }
); then
  pass "check_required_tools: one missing → MISSING=1"
else
  fail "check_required_tools: one missing" "subshell exited non-zero"
fi

# Case 3: missing tool name appears in TOOLS_MISSING_LIST
missing_names=$(
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools bash __nonexistent_tool_xyz__
  printf '%s\n' "${TOOLS_MISSING_LIST[@]}"
)
if echo "$missing_names" | grep -q "^__nonexistent_tool_xyz__$"; then
  pass "check_required_tools: missing tool name in TOOLS_MISSING_LIST"
else
  fail "check_required_tools: missing tool name in TOOLS_MISSING_LIST" "got: $missing_names"
fi

# Case 4: no tools passed → all counts zero
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_required_tools
  [[ "$TOOLS_PRESENT_COUNT" -eq 0 ]] || { printf "  FAIL  present: expected 0, got %s\n" "$TOOLS_PRESENT_COUNT"; exit 1; }
  [[ "$TOOLS_MISSING_COUNT" -eq 0 ]] || { printf "  FAIL  missing: expected 0, got %s\n" "$TOOLS_MISSING_COUNT"; exit 1; }
); then
  pass "check_required_tools: empty list → all counts zero"
else
  fail "check_required_tools: empty list" "subshell exited non-zero"
fi

# ── check_stale_backups ───────────────────────────────────────────────────────
echo ""
echo "=== check_stale_backups ==="

# Case 1: backup dir does not exist
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$TMPDIR_BASE/nonexistent_backup_dir"
  [[ "$STALE_BACKUP_COUNT" -eq 0 ]] || { printf "  FAIL  count: expected 0, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: no backup dir → STALE=0"
else
  fail "check_stale_backups: no backup dir" "subshell exited non-zero"
fi

# Case 2: backup dir exists but is empty
BACKUP_EMPTY="$TMPDIR_BASE/backup_empty"
mkdir -p "$BACKUP_EMPTY"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_EMPTY"
  [[ "$STALE_BACKUP_COUNT" -eq 0 ]] || { printf "  FAIL  count: expected 0, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: empty backup dir → STALE=0"
else
  fail "check_stale_backups: empty backup dir" "subshell exited non-zero"
fi

# Case 3: recent backup should not be stale (threshold=30)
BACKUP_RECENT="$TMPDIR_BASE/backup_recent"
mkdir -p "$BACKUP_RECENT/20260601_120000"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_RECENT" 30
  [[ "$STALE_BACKUP_COUNT" -eq 0 ]] || { printf "  FAIL  count: expected 0, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: recent backup → not stale"
else
  fail "check_stale_backups: recent backup" "subshell exited non-zero"
fi

# Case 4: old backup detected as stale (backdate via touch -t to Jan 2023)
BACKUP_OLD="$TMPDIR_BASE/backup_old"
mkdir -p "$BACKUP_OLD/20230101_120000"
touch -t 202301010000 "$BACKUP_OLD/20230101_120000"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_OLD" 30
  [[ "$STALE_BACKUP_COUNT" -eq 1 ]] || { printf "  FAIL  count: expected 1, got %s\n" "$STALE_BACKUP_COUNT"; exit 1; }
); then
  pass "check_stale_backups: backdated backup (Jan 2023) → STALE=1"
else
  fail "check_stale_backups: backdated backup" "subshell exited non-zero"
fi

# Case 5: stale path appears in STALE_BACKUP_LIST
stale_paths=$(
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_stale_backups "$BACKUP_OLD" 30
  printf '%s\n' "${STALE_BACKUP_LIST[@]}"
)
if echo "$stale_paths" | grep -q "20230101_120000"; then
  pass "check_stale_backups: stale dir path in STALE_BACKUP_LIST"
else
  fail "check_stale_backups: stale dir path in STALE_BACKUP_LIST" "got: $stale_paths"
fi

# ── check_ssh_key ───────────────────────────────────────────────────────────────
echo ""
echo "=== check_ssh_key ==="

# Case 1: key file does not exist → SSH_KEY_OK=false, SSH_KEY_ISSUE non-empty
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_ssh_key "$TMPDIR_BASE/nonexistent_key"
  [[ "$SSH_KEY_OK" == "false" ]] || { printf "  FAIL  SSH_KEY_OK should be false\n"; exit 1; }
  [[ -n "$SSH_KEY_ISSUE" ]] || { printf "  FAIL  SSH_KEY_ISSUE should be non-empty\n"; exit 1; }
); then
  pass "check_ssh_key: missing key file → SSH_KEY_OK=false, issue set"
else
  fail "check_ssh_key: missing key file" "subshell exited non-zero"
fi

# Case 2: key file exists but agent doesn't have it → SSH_KEY_OK=false
# Generate a throwaway key in a temp dir; it won't be in the agent.
TMP_KEY="$TMPDIR_BASE/test_id_ed25519"
ssh-keygen -t ed25519 -f "$TMP_KEY" -N "" -C "test" &>/dev/null

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  check_ssh_key "$TMP_KEY"
  # Key exists but almost certainly not in this subshell's agent
  [[ "$SSH_KEY_OK" == "false" ]] || [[ "$SSH_KEY_OK" == "true" ]] || { printf "  FAIL  SSH_KEY_OK must be boolean\n"; exit 1; }
  # SSH_KEY_ISSUE should be empty only if somehow loaded
  [[ -n "$SSH_KEY_ISSUE" || "$SSH_KEY_OK" == "true" ]] || { printf "  FAIL  expected issue or ok=true\n"; exit 1; }
); then
  pass "check_ssh_key: key exists but not in agent → SSH_KEY_OK=false (or OK if agent has it)"
else
  fail "check_ssh_key: key exists, agent check" "subshell exited non-zero"
fi

# ── check_git_lfs_global ───────────────────────────────────────────────────
echo ""
echo "=== check_git_lfs_global ==="

# Case 1: git-lfs not initialized (empty global config)
TMP_GIT_CONFIG="$TMPDIR_BASE/gitconfig_empty"
touch "$TMP_GIT_CONFIG"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export GIT_CONFIG_GLOBAL="$TMP_GIT_CONFIG"
  check_git_lfs_global
  # If git-lfs is installed on this machine, it should report not-initialized
  # If git-lfs is not installed, GIT_LFS_ISSUE should mention "not installed"
  [[ "$GIT_LFS_OK" == "false" ]] || { printf "  FAIL  GIT_LFS_OK should be false with empty config\n"; exit 1; }
  [[ -n "$GIT_LFS_ISSUE" ]] || { printf "  FAIL  GIT_LFS_ISSUE should be non-empty\n"; exit 1; }
); then
  pass "check_git_lfs_global: empty config → GIT_LFS_OK=false, issue set"
else
  fail "check_git_lfs_global: empty config" "subshell exited non-zero"
fi

# Case 2: config has filter.lfs.clean set → GIT_LFS_OK=true (only if git-lfs is installed)
TMP_GIT_CONFIG_WITH_LFS="$TMPDIR_BASE/gitconfig_lfs"
cat > "$TMP_GIT_CONFIG_WITH_LFS" << 'EOF'
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
EOF

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export GIT_CONFIG_GLOBAL="$TMP_GIT_CONFIG_WITH_LFS"
  check_git_lfs_global
  if command -v git-lfs &>/dev/null; then
    [[ "$GIT_LFS_OK" == "true" ]] || { printf "  FAIL  GIT_LFS_OK should be true when lfs config present\n"; exit 1; }
  else
    # git-lfs not installed — GIT_LFS_OK=false regardless of config
    [[ "$GIT_LFS_OK" == "false" ]] || { printf "  FAIL  GIT_LFS_OK should be false without git-lfs binary\n"; exit 1; }
  fi
); then
  pass "check_git_lfs_global: lfs config present → GIT_LFS_OK matches binary availability"
else
  fail "check_git_lfs_global: lfs config present" "subshell exited non-zero"
fi

# ── check_mise_installed ──────────────────────────────────────────────────
echo ""
echo "=== check_mise_installed ==="

# Case 1: mise not on PATH → silently returns count=0 (no-op)
mkdir -p "$TMPDIR_BASE/empty_bin"
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export PATH="$TMPDIR_BASE/empty_bin"
  check_mise_installed "$TMPDIR_BASE/mise_match.toml"
  [[ "$MISE_UNINSTALLED_COUNT" -eq 0 ]] || { printf "  FAIL  count should be 0 when mise absent, got %s\n" "$MISE_UNINSTALLED_COUNT"; exit 1; }
); then
  pass "check_mise_installed: mise not on PATH → silently skipped (count=0)"
else
  fail "check_mise_installed: mise not on PATH" "subshell exited non-zero"
fi

# Case 2: all tools installed (reuse TOML_MATCH from earlier; only runs if mise is present)
if command -v mise &>/dev/null; then
  if (
    source "$SCRIPT_DIR/verify_helpers.sh"
    check_mise_installed "$TOML_MATCH"
    # We can't assert count=0 since tools may not be installed in CI,
    # but we can verify the function runs without error and sets the globals.
    [[ -n "${MISE_UNINSTALLED_COUNT+set}" ]] || { printf "  FAIL  MISE_UNINSTALLED_COUNT not set\n"; exit 1; }
  ); then
    pass "check_mise_installed: mise present → runs without error, count is set"
  else
    fail "check_mise_installed: mise present" "subshell exited non-zero"
  fi
else
  pass "check_mise_installed: mise not installed — skipped"
fi

# ── check_dotfiles_git_health ─────────────────────────────────────────────
echo ""
echo "=== check_dotfiles_git_health ==="

# Build conflict markers at runtime so this test file never contains a literal
# 7-character marker (which would trip the very check it exercises).
CM_BEGIN=$(printf '<%.0s' {1..7})
CM_SEP=$(printf '=%.0s' {1..7})
CM_END=$(printf '>%.0s' {1..7})

# Clean global config so git operations succeed in the scan cases.
CLEAN_GITCONFIG="$TMPDIR_BASE/gitconfig_clean"
touch "$CLEAN_GITCONFIG"

# Case 1: clean tracked files + clean config → OK=true
GITREPO_CLEAN="$TMPDIR_BASE/gitrepo_clean"
mkdir -p "$GITREPO_CLEAN"
git -C "$GITREPO_CLEAN" init -q
echo "hello world" > "$GITREPO_CLEAN/file.txt"
git -C "$GITREPO_CLEAN" add file.txt

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export GIT_CONFIG_GLOBAL="$CLEAN_GITCONFIG"
  check_dotfiles_git_health "$GITREPO_CLEAN"
  [[ "$DOTFILES_GIT_HEALTH_OK" == "true" ]] || { printf "  FAIL  expected OK=true, got %s\n" "$DOTFILES_GIT_HEALTH_OK"; exit 1; }
  [[ "${#DOTFILES_CONFLICT_FILES[@]}" -eq 0 ]] || { printf "  FAIL  expected 0 conflict files\n"; exit 1; }
); then
  pass "check_dotfiles_git_health: clean repo + clean config → OK=true"
else
  fail "check_dotfiles_git_health: clean repo" "subshell exited non-zero"
fi

# Case 2: a tracked file containing conflict markers → OK=false, file listed
GITREPO_CONFLICT="$TMPDIR_BASE/gitrepo_conflict"
mkdir -p "$GITREPO_CONFLICT"
git -C "$GITREPO_CONFLICT" init -q
{
  echo "$CM_BEGIN HEAD"
  echo "ours"
  echo "$CM_SEP"
  echo "theirs"
  echo "$CM_END branch"
} > "$GITREPO_CONFLICT/conflicted.txt"
git -C "$GITREPO_CONFLICT" add conflicted.txt

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export GIT_CONFIG_GLOBAL="$CLEAN_GITCONFIG"
  check_dotfiles_git_health "$GITREPO_CONFLICT"
  [[ "$DOTFILES_GIT_HEALTH_OK" == "false" ]] || { printf "  FAIL  expected OK=false\n"; exit 1; }
  printf '%s\n' "${DOTFILES_CONFLICT_FILES[@]}" | grep -q "conflicted.txt" || { printf "  FAIL  conflicted.txt not in DOTFILES_CONFLICT_FILES\n"; exit 1; }
); then
  pass "check_dotfiles_git_health: tracked file with markers → OK=false, file listed"
else
  fail "check_dotfiles_git_health: conflict markers" "subshell exited non-zero"
fi

# Case 3: broken global config (contains a conflict marker) → git config fails → OK=false
BROKEN_GITCONFIG="$TMPDIR_BASE/gitconfig_broken"
{
  echo "[user]"
  echo "  name = test"
  echo "$CM_BEGIN HEAD"
} > "$BROKEN_GITCONFIG"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export GIT_CONFIG_GLOBAL="$BROKEN_GITCONFIG"
  check_dotfiles_git_health "$GITREPO_CLEAN"
  [[ "$DOTFILES_GIT_HEALTH_OK" == "false" ]] || { printf "  FAIL  expected OK=false with broken config\n"; exit 1; }
  [[ "${#DOTFILES_GIT_HEALTH_ISSUES[@]}" -ge 1 ]] || { printf "  FAIL  expected at least one issue\n"; exit 1; }
); then
  pass "check_dotfiles_git_health: broken global config → OK=false"
else
  fail "check_dotfiles_git_health: broken global config" "subshell exited non-zero"
fi

# Case 4: path that is not a git work tree → OK=false with an issue
NOT_A_REPO="$TMPDIR_BASE/not_a_repo"
mkdir -p "$NOT_A_REPO"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export GIT_CONFIG_GLOBAL="$CLEAN_GITCONFIG"
  check_dotfiles_git_health "$NOT_A_REPO"
  [[ "$DOTFILES_GIT_HEALTH_OK" == "false" ]] || { printf "  FAIL  expected OK=false for non-repo\n"; exit 1; }
); then
  pass "check_dotfiles_git_health: non-git directory → OK=false"
else
  fail "check_dotfiles_git_health: non-git directory" "subshell exited non-zero"
fi

# ── check_brewfile_drift ──────────────────────────────────────────────────
echo ""
echo "=== check_brewfile_drift ==="

# Fake brew stub: `brew bundle check --file=F` exits 0 iff F contains IN_SYNC.
FAKE_BIN="$TMPDIR_BASE/fakebin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/brew" << 'EOF'
#!/usr/bin/env bash
f=""
for a in "$@"; do
  case "$a" in
    --file=*) f="${a#--file=}" ;;
  esac
done
if [[ "${1:-}" == "bundle" ]]; then
  if [[ -f "$f" ]] && grep -q IN_SYNC "$f"; then exit 0; else exit 1; fi
fi
exit 0
EOF
chmod +x "$FAKE_BIN/brew"

# Case 1: brew not on PATH → skipped, OK=true
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export PATH="$TMPDIR_BASE/empty_bin"
  check_brewfile_drift "$TMPDIR_BASE/whatever_Brewfile"
  [[ "$BREWFILE_DRIFT_SKIPPED" == "true" ]] || { printf "  FAIL  expected SKIPPED=true\n"; exit 1; }
  [[ "$BREWFILE_DRIFT_OK" == "true" ]] || { printf "  FAIL  expected OK=true when skipped\n"; exit 1; }
); then
  pass "check_brewfile_drift: brew absent → skipped, OK=true"
else
  fail "check_brewfile_drift: brew absent" "subshell exited non-zero"
fi

# Case 2: brew present, Brewfile in sync → OK=true, not skipped
BREWFILE_SYNC="$TMPDIR_BASE/Brewfile_sync"
echo "# IN_SYNC marker" > "$BREWFILE_SYNC"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export PATH="$FAKE_BIN:$PATH"
  check_brewfile_drift "$BREWFILE_SYNC"
  [[ "$BREWFILE_DRIFT_SKIPPED" == "false" ]] || { printf "  FAIL  expected SKIPPED=false\n"; exit 1; }
  [[ "$BREWFILE_DRIFT_OK" == "true" ]] || { printf "  FAIL  expected OK=true in sync\n"; exit 1; }
); then
  pass "check_brewfile_drift: in sync → OK=true"
else
  fail "check_brewfile_drift: in sync" "subshell exited non-zero"
fi

# Case 3: brew present, Brewfile drifted → OK=false, issue set
BREWFILE_DRIFTED="$TMPDIR_BASE/Brewfile_drift"
echo "brew \"git\"" > "$BREWFILE_DRIFTED"

if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export PATH="$FAKE_BIN:$PATH"
  check_brewfile_drift "$BREWFILE_DRIFTED"
  [[ "$BREWFILE_DRIFT_OK" == "false" ]] || { printf "  FAIL  expected OK=false on drift\n"; exit 1; }
  [[ -n "$BREWFILE_DRIFT_ISSUE" ]] || { printf "  FAIL  expected non-empty issue\n"; exit 1; }
); then
  pass "check_brewfile_drift: drift detected → OK=false, issue set"
else
  fail "check_brewfile_drift: drift detected" "subshell exited non-zero"
fi

# Case 4: brew present but Brewfile missing → OK=false, issue mentions not found
if (
  source "$SCRIPT_DIR/verify_helpers.sh"
  export PATH="$FAKE_BIN:$PATH"
  check_brewfile_drift "$TMPDIR_BASE/does_not_exist_Brewfile"
  [[ "$BREWFILE_DRIFT_OK" == "false" ]] || { printf "  FAIL  expected OK=false for missing Brewfile\n"; exit 1; }
  echo "$BREWFILE_DRIFT_ISSUE" | grep -q "not found" || { printf "  FAIL  issue should mention 'not found'\n"; exit 1; }
); then
  pass "check_brewfile_drift: missing Brewfile → OK=false, 'not found' issue"
else
  fail "check_brewfile_drift: missing Brewfile" "subshell exited non-zero"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────"
printf "  %d tests: %d passed, %d failed\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
echo "─────────────────────────────────────"

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  exit 1
fi
