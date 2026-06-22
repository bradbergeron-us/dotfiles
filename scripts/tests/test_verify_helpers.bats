#!/usr/bin/env bats
# test_verify_helpers.bats — unit tests for scripts/lib/verify_helpers.sh
# Run: bats scripts/tests/test_verify_helpers.bats

load 'test_helper'

setup() {
  # verify.sh sources bootstrap + verify at runtime; the tag-filtering tests
  # additionally rely on profile_helpers, so source all three here.
  # shellcheck source=/dev/null
  source "$LIB_DIR/bootstrap_helpers.sh"
  # shellcheck source=/dev/null
  source "$LIB_DIR/profile_helpers.sh"
  # shellcheck source=/dev/null
  source "$LIB_DIR/verify_helpers.sh"

  # Shared fake dotfiles checkout used by the check_symlinks cases.
  FAKE_DOTFILES="$BATS_TEST_TMPDIR/dotfiles"
  mkdir -p "$FAKE_DOTFILES/config"
  touch "$FAKE_DOTFILES/zshrc"
  touch "$FAKE_DOTFILES/gitconfig"
  touch "$FAKE_DOTFILES/config/mise.toml"
}

# ── check_symlinks ────────────────────────────────────────────────────────────
@test "check_symlinks: all correct → OK=3, BROKEN=0" {
  local h="$BATS_TEST_TMPDIR/home1"
  mkdir -p "$h/.config/mise"
  ln -sf "$FAKE_DOTFILES/zshrc"            "$h/.zshrc"
  ln -sf "$FAKE_DOTFILES/gitconfig"        "$h/.gitconfig"
  ln -sf "$FAKE_DOTFILES/config/mise.toml" "$h/.config/mise/config.toml"
  DOTFILES_SYMLINKS=(
    "zshrc:.zshrc"
    "gitconfig:.gitconfig"
    "config/mise.toml:.config/mise/config.toml"
  )
  check_symlinks "$FAKE_DOTFILES" "$h"
  [ "$SYMLINK_OK_COUNT" -eq 3 ]
  [ "$SYMLINK_BROKEN_COUNT" -eq 0 ]
}

@test "check_symlinks: one missing destination → BROKEN=1" {
  local h="$BATS_TEST_TMPDIR/home2"
  mkdir -p "$h"
  ln -sf "$FAKE_DOTFILES/zshrc" "$h/.zshrc"
  # gitconfig symlink intentionally absent
  DOTFILES_SYMLINKS=("zshrc:.zshrc" "gitconfig:.gitconfig")
  check_symlinks "$FAKE_DOTFILES" "$h"
  [ "$SYMLINK_OK_COUNT" -eq 1 ]
  [ "$SYMLINK_BROKEN_COUNT" -eq 1 ]
}

@test "check_symlinks: wrong symlink target → BROKEN=1" {
  local h="$BATS_TEST_TMPDIR/home3"
  mkdir -p "$h"
  ln -sf "/some/completely/different/path" "$h/.zshrc"
  DOTFILES_SYMLINKS=("zshrc:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$h"
  [ "$SYMLINK_BROKEN_COUNT" -eq 1 ]
}

@test "check_symlinks: plain file (not symlink) → BROKEN=1" {
  local h="$BATS_TEST_TMPDIR/home4"
  mkdir -p "$h"
  echo "not a symlink" > "$h/.zshrc"
  DOTFILES_SYMLINKS=("zshrc:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$h"
  [ "$SYMLINK_BROKEN_COUNT" -eq 1 ]
}

@test "check_symlinks: source file missing in dotfiles → BROKEN=1" {
  local h="$BATS_TEST_TMPDIR/home5"
  mkdir -p "$h"
  DOTFILES_SYMLINKS=("nonexistent_src:.zshrc")
  check_symlinks "$FAKE_DOTFILES" "$h"
  [ "$SYMLINK_BROKEN_COUNT" -eq 1 ]
}

@test "check_symlinks: empty DOTFILES_SYMLINKS → all counts zero" {
  local h="$BATS_TEST_TMPDIR/home_empty"
  mkdir -p "$h"
  DOTFILES_SYMLINKS=()
  check_symlinks "$FAKE_DOTFILES" "$h"
  [ "$SYMLINK_OK_COUNT" -eq 0 ]
  [ "$SYMLINK_BROKEN_COUNT" -eq 0 ]
}

# ── load_symlink_map ──────────────────────────────────────────────────────────
@test "load_symlink_map: parses manifest into src:dest, ignores comments/blanks" {
  local map="$BATS_TEST_TMPDIR/symlinks.map"
  cat > "$map" << 'EOF'
# comment line ignored
home/zshrc        .zshrc

config/mise.toml  .config/mise/config.toml
EOF
  load_symlink_map "$map"
  [ "${#DOTFILES_SYMLINKS[@]}" -eq 2 ]
  [ "${DOTFILES_SYMLINKS[0]}" = "home/zshrc:.zshrc" ]
  [ "${DOTFILES_SYMLINKS[1]}" = "config/mise.toml:.config/mise/config.toml" ]
}

@test "load_symlink_map: missing manifest → empty array" {
  load_symlink_map "$BATS_TEST_TMPDIR/does_not_exist.map"
  [ "${#DOTFILES_SYMLINKS[@]}" -eq 0 ]
}

@test "load_symlink_map + check_symlinks: manifest-driven check passes end-to-end" {
  local mdot="$BATS_TEST_TMPDIR/map_dotfiles"
  local mhome="$BATS_TEST_TMPDIR/map_home"
  mkdir -p "$mdot/home" "$mhome"
  touch "$mdot/home/zshrc"
  printf 'home/zshrc  .zshrc\n' > "$mdot/symlinks.map"
  ln -sf "$mdot/home/zshrc" "$mhome/.zshrc"
  load_symlink_map "$mdot/symlinks.map"
  check_symlinks "$mdot" "$mhome"
  [ "$SYMLINK_OK_COUNT" -eq 1 ]
  [ "$SYMLINK_BROKEN_COUNT" -eq 0 ]
}

@test "load_symlink_map: profile=minimal skips gui-tagged record" {
  local map="$BATS_TEST_TMPDIR/symlinks_tagged.map"
  cat > "$map" << 'EOF'
home/zshrc     .zshrc
home/hyper.js  .hyper.js   gui
EOF
  load_symlink_map "$map" minimal
  [ "${#DOTFILES_SYMLINKS[@]}" -eq 1 ]
  [ "${DOTFILES_SYMLINKS[0]}" = "home/zshrc:.zshrc" ]
}

@test "load_symlink_map: profile=personal keeps gui-tagged record" {
  local map="$BATS_TEST_TMPDIR/symlinks_tagged.map"
  cat > "$map" << 'EOF'
home/zshrc     .zshrc
home/hyper.js  .hyper.js   gui
EOF
  load_symlink_map "$map" personal
  [ "${#DOTFILES_SYMLINKS[@]}" -eq 2 ]
}

@test "load_symlink_map: no profile arg keeps all records (back-compat)" {
  local map="$BATS_TEST_TMPDIR/symlinks_tagged.map"
  cat > "$map" << 'EOF'
home/zshrc     .zshrc
home/hyper.js  .hyper.js   gui
EOF
  load_symlink_map "$map"
  [ "${#DOTFILES_SYMLINKS[@]}" -eq 2 ]
}

# ── check_required_tools ──────────────────────────────────────────────────────
@test "check_required_tools: all present (bash, cat, ls) → MISSING=0" {
  check_required_tools bash cat ls
  [ "$TOOLS_PRESENT_COUNT" -eq 3 ]
  [ "$TOOLS_MISSING_COUNT" -eq 0 ]
}

@test "check_required_tools: one missing → MISSING=1" {
  check_required_tools bash __nonexistent_tool_xyz__
  [ "$TOOLS_PRESENT_COUNT" -eq 1 ]
  [ "$TOOLS_MISSING_COUNT" -eq 1 ]
}

@test "check_required_tools: missing tool name in TOOLS_MISSING_LIST" {
  check_required_tools bash __nonexistent_tool_xyz__
  printf '%s\n' "${TOOLS_MISSING_LIST[@]}" | grep -q "^__nonexistent_tool_xyz__$"
}

@test "check_required_tools: empty list → all counts zero" {
  check_required_tools
  [ "$TOOLS_PRESENT_COUNT" -eq 0 ]
  [ "$TOOLS_MISSING_COUNT" -eq 0 ]
}

# ── check_stale_backups ───────────────────────────────────────────────────────
@test "check_stale_backups: no backup dir → STALE=0" {
  check_stale_backups "$BATS_TEST_TMPDIR/nonexistent_backup_dir"
  [ "$STALE_BACKUP_COUNT" -eq 0 ]
}

@test "check_stale_backups: empty backup dir → STALE=0" {
  local d="$BATS_TEST_TMPDIR/backup_empty"; mkdir -p "$d"
  check_stale_backups "$d"
  [ "$STALE_BACKUP_COUNT" -eq 0 ]
}

@test "check_stale_backups: recent backup → not stale" {
  local d="$BATS_TEST_TMPDIR/backup_recent"; mkdir -p "$d/20260601_120000"
  check_stale_backups "$d" 30
  [ "$STALE_BACKUP_COUNT" -eq 0 ]
}

@test "check_stale_backups: backdated backup (Jan 2023) → STALE=1" {
  local d="$BATS_TEST_TMPDIR/backup_old"; mkdir -p "$d/20230101_120000"
  touch -t 202301010000 "$d/20230101_120000"
  check_stale_backups "$d" 30
  [ "$STALE_BACKUP_COUNT" -eq 1 ]
}

@test "check_stale_backups: stale dir path in STALE_BACKUP_LIST" {
  local d="$BATS_TEST_TMPDIR/backup_old"; mkdir -p "$d/20230101_120000"
  touch -t 202301010000 "$d/20230101_120000"
  check_stale_backups "$d" 30
  printf '%s\n' "${STALE_BACKUP_LIST[@]}" | grep -q "20230101_120000"
}

# ── check_ssh_key ─────────────────────────────────────────────────────────────
@test "check_ssh_key: missing key file → SSH_KEY_OK=false, issue set" {
  check_ssh_key "$BATS_TEST_TMPDIR/nonexistent_key"
  [ "$SSH_KEY_OK" = "false" ]
  [ -n "$SSH_KEY_ISSUE" ]
}

@test "check_ssh_key: key exists but not in agent → SSH_KEY_OK=false (or OK)" {
  if ! command -v ssh-keygen >/dev/null 2>&1; then skip "ssh-keygen not available"; fi
  local key="$BATS_TEST_TMPDIR/test_id_ed25519"
  ssh-keygen -t ed25519 -f "$key" -N "" -C "test" &>/dev/null
  check_ssh_key "$key"
  # Key exists but almost certainly not in this process's agent.
  [ "$SSH_KEY_OK" = "false" ] || [ "$SSH_KEY_OK" = "true" ]
  [ -n "$SSH_KEY_ISSUE" ] || [ "$SSH_KEY_OK" = "true" ]
}

# ── check_git_lfs_global ──────────────────────────────────────────────────────
@test "check_git_lfs_global: empty config → GIT_LFS_OK=false, issue set" {
  local cfg="$BATS_TEST_TMPDIR/gitconfig_empty"
  touch "$cfg"
  export GIT_CONFIG_GLOBAL="$cfg"
  check_git_lfs_global
  [ "$GIT_LFS_OK" = "false" ]
  [ -n "$GIT_LFS_ISSUE" ]
}

@test "check_git_lfs_global: lfs config present → GIT_LFS_OK matches binary availability" {
  local cfg="$BATS_TEST_TMPDIR/gitconfig_lfs"
  cat > "$cfg" << 'EOF'
[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true
EOF
  export GIT_CONFIG_GLOBAL="$cfg"
  check_git_lfs_global
  if command -v git-lfs &>/dev/null; then
    [ "$GIT_LFS_OK" = "true" ]
  else
    [ "$GIT_LFS_OK" = "false" ]
  fi
}

@test "check_git_lfs_global: filters via [include] are detected (follows includes)" {
  # Regression: the global file itself has NO lfs filters; they live in an
  # [include]d file (mirrors the dotfiles' ~/.gitconfig -> home/gitconfig setup).
  # A plain `git config --global` misses this; --includes detects it.
  if ! command -v git-lfs &>/dev/null; then skip "git-lfs not installed"; fi
  local inc="$BATS_TEST_TMPDIR/included_lfs.gitconfig"
  cat > "$inc" << 'EOF'
[filter "lfs"]
clean = git-lfs clean -- %f
smudge = git-lfs smudge -- %f
process = git-lfs filter-process
required = true
EOF
  local cfg="$BATS_TEST_TMPDIR/gitconfig_include"
  printf '[include]\n\tpath = %s\n' "$inc" > "$cfg"
  export GIT_CONFIG_GLOBAL="$cfg"
  check_git_lfs_global
  [ "$GIT_LFS_OK" = "true" ]
  [ -z "$GIT_LFS_ISSUE" ]
}

# ── check_mise_installed ──────────────────────────────────────────────────────
write_mise_match() {
  cat > "$BATS_TEST_TMPDIR/mise_match.toml" << 'EOF'
[tools]
ruby = "3.3.6"
node = "22"
java = "temurin-21"
python = "3.12"
go = "1.24"
EOF
}

@test "check_mise_installed: mise not on PATH → silently skipped (count=0)" {
  write_mise_match
  mkdir -p "$BATS_TEST_TMPDIR/empty_bin"
  # Restrict PATH and assert the global inside the same subshell so the
  # restricted PATH never leaks to the rest of the test.
  ( set -e
    export PATH="$BATS_TEST_TMPDIR/empty_bin"
    check_mise_installed "$BATS_TEST_TMPDIR/mise_match.toml"
    [ "$MISE_UNINSTALLED_COUNT" -eq 0 ]
  )
}

@test "check_mise_installed: mise present → runs without error, count is set" {
  if ! command -v mise &>/dev/null; then skip "mise not installed"; fi
  write_mise_match
  check_mise_installed "$BATS_TEST_TMPDIR/mise_match.toml"
  [ -n "${MISE_UNINSTALLED_COUNT+set}" ]
}

# ── check_dotfiles_git_health ─────────────────────────────────────────────────
# Build conflict markers at runtime so this file never contains a literal
# 7-character marker (which would trip the very check it exercises).
@test "check_dotfiles_git_health: clean repo + clean config → OK=true" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  local clean_cfg="$BATS_TEST_TMPDIR/gitconfig_clean"; touch "$clean_cfg"
  local repo="$BATS_TEST_TMPDIR/gitrepo_clean"; mkdir -p "$repo"
  git -C "$repo" init -q
  echo "hello world" > "$repo/file.txt"
  git -C "$repo" add file.txt
  export GIT_CONFIG_GLOBAL="$clean_cfg"
  check_dotfiles_git_health "$repo"
  [ "$DOTFILES_GIT_HEALTH_OK" = "true" ]
  [ "${#DOTFILES_CONFLICT_FILES[@]}" -eq 0 ]
}

@test "check_dotfiles_git_health: tracked file with markers → OK=false, file listed" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  local cm_begin cm_sep cm_end
  cm_begin=$(printf '<%.0s' {1..7})
  cm_sep=$(printf '=%.0s' {1..7})
  cm_end=$(printf '>%.0s' {1..7})
  local clean_cfg="$BATS_TEST_TMPDIR/gitconfig_clean"; touch "$clean_cfg"
  local repo="$BATS_TEST_TMPDIR/gitrepo_conflict"; mkdir -p "$repo"
  git -C "$repo" init -q
  {
    echo "$cm_begin HEAD"
    echo "ours"
    echo "$cm_sep"
    echo "theirs"
    echo "$cm_end branch"
  } > "$repo/conflicted.txt"
  git -C "$repo" add conflicted.txt
  export GIT_CONFIG_GLOBAL="$clean_cfg"
  check_dotfiles_git_health "$repo"
  [ "$DOTFILES_GIT_HEALTH_OK" = "false" ]
  printf '%s\n' "${DOTFILES_CONFLICT_FILES[@]}" | grep -q "conflicted.txt"
}

@test "check_dotfiles_git_health: broken global config → OK=false" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  local cm_begin
  cm_begin=$(printf '<%.0s' {1..7})
  local repo="$BATS_TEST_TMPDIR/gitrepo_clean2"; mkdir -p "$repo"
  git -C "$repo" init -q
  echo "hello world" > "$repo/file.txt"
  git -C "$repo" add file.txt
  local broken_cfg="$BATS_TEST_TMPDIR/gitconfig_broken"
  {
    echo "[user]"
    echo "  name = test"
    echo "$cm_begin HEAD"
  } > "$broken_cfg"
  export GIT_CONFIG_GLOBAL="$broken_cfg"
  check_dotfiles_git_health "$repo"
  [ "$DOTFILES_GIT_HEALTH_OK" = "false" ]
  [ "${#DOTFILES_GIT_HEALTH_ISSUES[@]}" -ge 1 ]
}

@test "check_dotfiles_git_health: non-git directory → OK=false" {
  if ! command -v git >/dev/null 2>&1; then skip "git not available"; fi
  local clean_cfg="$BATS_TEST_TMPDIR/gitconfig_clean"; touch "$clean_cfg"
  local nd="$BATS_TEST_TMPDIR/not_a_repo"; mkdir -p "$nd"
  export GIT_CONFIG_GLOBAL="$clean_cfg"
  check_dotfiles_git_health "$nd"
  [ "$DOTFILES_GIT_HEALTH_OK" = "false" ]
}

# ── check_gitconfig_include ───────────────────────────────────────────────────
setup_gci_dotfiles() {
  GCI_DOTFILES="$BATS_TEST_TMPDIR/gci_dotfiles"
  mkdir -p "$GCI_DOTFILES/home"
  touch "$GCI_DOTFILES/home/gitconfig"
}

@test "check_gitconfig_include: thin include file → OK=true" {
  setup_gci_dotfiles
  local h="$BATS_TEST_TMPDIR/gci_home_ok"; mkdir -p "$h"
  printf '[include]\n\tpath = %s/home/gitconfig\n' "$GCI_DOTFILES" > "$h/.gitconfig"
  check_gitconfig_include "$h" "$GCI_DOTFILES"
  [ "$GITCONFIG_INCLUDE_OK" = "true" ]
  [ -z "$GITCONFIG_INCLUDE_ISSUE" ]
}

@test "check_gitconfig_include: symlink → OK=false, issue mentions symlink" {
  setup_gci_dotfiles
  local h="$BATS_TEST_TMPDIR/gci_home_link"; mkdir -p "$h"
  ln -sf "$GCI_DOTFILES/home/gitconfig" "$h/.gitconfig"
  check_gitconfig_include "$h" "$GCI_DOTFILES"
  [ "$GITCONFIG_INCLUDE_OK" = "false" ]
  echo "$GITCONFIG_INCLUDE_ISSUE" | grep -q "symlink"
}

@test "check_gitconfig_include: missing ~/.gitconfig → OK=false" {
  setup_gci_dotfiles
  local h="$BATS_TEST_TMPDIR/gci_home_missing"; mkdir -p "$h"
  check_gitconfig_include "$h" "$GCI_DOTFILES"
  [ "$GITCONFIG_INCLUDE_OK" = "false" ]
  [ -n "$GITCONFIG_INCLUDE_ISSUE" ]
}

@test "check_gitconfig_include: file without include → OK=false" {
  setup_gci_dotfiles
  local h="$BATS_TEST_TMPDIR/gci_home_noinc"; mkdir -p "$h"
  printf '[user]\n\tname = test\n' > "$h/.gitconfig"
  check_gitconfig_include "$h" "$GCI_DOTFILES"
  [ "$GITCONFIG_INCLUDE_OK" = "false" ]
}

# ── check_brewfile_drift ──────────────────────────────────────────────────────
# Fake brew stub: `brew list --formula|--cask` prints the names in $FAKE_INSTALLED
# (space-separated), so the helper's snapshot sees them as installed; any other
# subcommand exits 0. Models "installed (any version)" vs "not installed".
setup_fake_brew() {
  FAKE_BIN="$BATS_TEST_TMPDIR/fakebin"
  mkdir -p "$FAKE_BIN"
  cat > "$FAKE_BIN/brew" << 'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "list" ]]; then
  for p in $FAKE_INSTALLED; do echo "$p"; done
  exit 0
fi
exit 0
EOF
  chmod +x "$FAKE_BIN/brew"
}

@test "check_brewfile_drift: brew absent → skipped, OK=true" {
  mkdir -p "$BATS_TEST_TMPDIR/empty_bin"
  ( set -e
    export PATH="$BATS_TEST_TMPDIR/empty_bin"
    check_brewfile_drift "$BATS_TEST_TMPDIR/whatever_Brewfile"
    [ "$BREWFILE_DRIFT_SKIPPED" = "true" ]
    [ "$BREWFILE_DRIFT_OK" = "true" ]
  )
}

@test "check_brewfile_drift: all entries installed → OK=true" {
  setup_fake_brew
  local bf="$BATS_TEST_TMPDIR/Brewfile_sync"
  printf 'brew "git"\ncask "ghostty"\n' > "$bf"
  ( set -e
    export PATH="$FAKE_BIN:$PATH"
    export FAKE_INSTALLED="git ghostty"
    check_brewfile_drift "$bf"
    [ "$BREWFILE_DRIFT_SKIPPED" = "false" ]
    [ "$BREWFILE_DRIFT_OK" = "true" ]
  )
}

@test "check_brewfile_drift: installed but outdated → OK=true (only missing counts)" {
  # Presence-based: an installed package is OK regardless of version, so the
  # check never warns merely because something is outdated.
  setup_fake_brew
  local bf="$BATS_TEST_TMPDIR/Brewfile_outdated"
  printf 'cask "dbeaver-community"\n' > "$bf"
  ( set -e
    export PATH="$FAKE_BIN:$PATH"
    export FAKE_INSTALLED="dbeaver-community"
    check_brewfile_drift "$bf"
    [ "$BREWFILE_DRIFT_OK" = "true" ]
  )
}

@test "check_brewfile_drift: a not-installed entry → OK=false, issue names it" {
  setup_fake_brew
  local bf="$BATS_TEST_TMPDIR/Brewfile_missing"
  printf 'brew "git"\nbrew "definitely-not-installed"\n' > "$bf"
  ( set -e
    export PATH="$FAKE_BIN:$PATH"
    export FAKE_INSTALLED="git"
    check_brewfile_drift "$bf"
    [ "$BREWFILE_DRIFT_OK" = "false" ]
    echo "$BREWFILE_DRIFT_ISSUE" | grep -q "definitely-not-installed"
  )
}

@test "check_brewfile_drift: comments and non-brew/cask lines are ignored" {
  setup_fake_brew
  local bf="$BATS_TEST_TMPDIR/Brewfile_comments"
  printf '# a comment\ntap "homebrew/cask"\nvscode "some.extension"\nbrew "git"\n' > "$bf"
  ( set -e
    export PATH="$FAKE_BIN:$PATH"
    export FAKE_INSTALLED="git"
    check_brewfile_drift "$bf"
    [ "$BREWFILE_DRIFT_OK" = "true" ]
  )
}

@test "check_brewfile_drift: missing Brewfile → OK=false, 'not found' issue" {
  setup_fake_brew
  ( set -e
    export PATH="$FAKE_BIN:$PATH"
    check_brewfile_drift "$BATS_TEST_TMPDIR/does_not_exist_Brewfile"
    [ "$BREWFILE_DRIFT_OK" = "false" ]
    echo "$BREWFILE_DRIFT_ISSUE" | grep -q "not found"
  )
}
