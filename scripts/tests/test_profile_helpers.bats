#!/usr/bin/env bats
# test_profile_helpers.bats — unit tests for scripts/lib/profile_helpers.sh
# Run: bats scripts/tests/test_profile_helpers.bats

load 'test_helper'

setup() {
  # shellcheck source=/dev/null
  source "$LIB_DIR/profile_helpers.sh"
  # Baseline: isolate from the real machine's profile file / env for all tests.
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/baseline-none"
  unset DOTFILES_PROFILE 2>/dev/null || true
}

# ── valid_profile ─────────────────────────────────────────────────────────────
@test "valid_profile: known profiles accepted" {
  valid_profile personal
  valid_profile work
  valid_profile minimal
  valid_profile server
}

@test "valid_profile: unknown profile rejected" {
  run valid_profile bogus
  [ "$status" -ne 0 ]
}

# ── resolve_profile (precedence: flag > env > file > default) ──────────────────
@test "resolve_profile: nothing set → default personal" {
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/none"
  unset DOTFILES_PROFILE
  [ "$(resolve_profile "")" = "personal" ]
}

@test "resolve_profile: persisted file → work" {
  printf 'work\n' > "$BATS_TEST_TMPDIR/pf_work"
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/pf_work"
  unset DOTFILES_PROFILE
  [ "$(resolve_profile "")" = "work" ]
}

@test "resolve_profile: env overrides file" {
  printf 'work\n' > "$BATS_TEST_TMPDIR/pf_work"
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/pf_work"
  [ "$(DOTFILES_PROFILE=server resolve_profile "")" = "server" ]
}

@test "resolve_profile: flag overrides env" {
  printf 'work\n' > "$BATS_TEST_TMPDIR/pf_work"
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/pf_work"
  [ "$(DOTFILES_PROFILE=server resolve_profile "minimal")" = "minimal" ]
}

@test "resolve_profile: invalid flag falls through to env" {
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/none"
  [ "$(DOTFILES_PROFILE=server resolve_profile "bogus")" = "server" ]
}

@test "resolve_profile: invalid file content → default" {
  printf 'garbage\n' > "$BATS_TEST_TMPDIR/pf_bad"
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/pf_bad"
  unset DOTFILES_PROFILE
  [ "$(resolve_profile "")" = "personal" ]
}

# ── current_profile ───────────────────────────────────────────────────────────
@test "current_profile: reads persisted file" {
  printf 'work\n' > "$BATS_TEST_TMPDIR/pf_work"
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/pf_work"
  unset DOTFILES_PROFILE
  [ "$(current_profile)" = "work" ]
}

# ── persist_profile ───────────────────────────────────────────────────────────
@test "persist_profile: writes a valid profile" {
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/pp"
  persist_profile work
  [ "$(cat "$BATS_TEST_TMPDIR/pp")" = "work" ]
}

@test "persist_profile: rejects invalid name and writes nothing" {
  DOTFILES_PROFILE_FILE="$BATS_TEST_TMPDIR/pp_bad"
  run persist_profile bogus
  [ "$status" -ne 0 ]
  [ ! -f "$BATS_TEST_TMPDIR/pp_bad" ]
}

# ── profile_includes ──────────────────────────────────────────────────────────
@test "profile_includes: empty/core apply to all" {
  profile_includes minimal ""
  profile_includes server "core"
}

@test "profile_includes: gui → personal/work only" {
  profile_includes personal gui
  profile_includes work gui
  ! profile_includes minimal gui
  ! profile_includes server gui
}

@test "profile_includes: work tag → work only" {
  profile_includes work work
  ! profile_includes personal work
}

@test "profile_includes: exact profile-name tag" {
  profile_includes server server
  ! profile_includes personal server
}

@test "profile_includes: multi-tag union" {
  profile_includes personal "gui,work"
  profile_includes work "gui,work"
  ! profile_includes server "gui,work"
}

# ── profile_brewfiles ─────────────────────────────────────────────────────────
@test "profile_brewfiles: minimal/server → core only" {
  local bfd="$BATS_TEST_TMPDIR/bf"; mkdir -p "$bfd"
  : > "$bfd/Brewfile"; : > "$bfd/Brewfile.personal"; : > "$bfd/Brewfile.work"
  [ "$(profile_brewfiles minimal "$bfd" | wc -l | tr -d '[:space:]')" = "1" ]
  [ "$(profile_brewfiles server "$bfd" | wc -l | tr -d '[:space:]')" = "1" ]
}

@test "profile_brewfiles: personal → core + personal" {
  local bfd="$BATS_TEST_TMPDIR/bf"; mkdir -p "$bfd"
  : > "$bfd/Brewfile"; : > "$bfd/Brewfile.personal"; : > "$bfd/Brewfile.work"
  [ "$(profile_brewfiles personal "$bfd" | wc -l | tr -d '[:space:]')" = "2" ]
}

@test "profile_brewfiles: work → core + personal + work" {
  local bfd="$BATS_TEST_TMPDIR/bf"; mkdir -p "$bfd"
  : > "$bfd/Brewfile"; : > "$bfd/Brewfile.personal"; : > "$bfd/Brewfile.work"
  [ "$(profile_brewfiles work "$bfd" | wc -l | tr -d '[:space:]')" = "3" ]
}

@test "profile_brewfiles: missing overlay files are omitted" {
  local bfd="$BATS_TEST_TMPDIR/bf"; mkdir -p "$bfd"
  : > "$bfd/Brewfile"
  [ "$(profile_brewfiles work "$bfd" | wc -l | tr -d '[:space:]')" = "1" ]
}

# ── profile_component_summary ─────────────────────────────────────────────────
@test "profile_component_summary: minimal → core only, no GUI/work/macOS" {
  run profile_component_summary minimal
  [ "$status" -eq 0 ]
  grep -qE 'Package overlay +core only' <<<"$output"
  grep -qE 'GUI apps \+ dotfiles +no' <<<"$output"
  grep -qE 'Work configs +no' <<<"$output"
  grep -qE 'macOS defaults +no' <<<"$output"
}

@test "profile_component_summary: personal → GUI overlay, macOS yes, work no" {
  run profile_component_summary personal
  grep -qE 'core \+ GUI \(Brewfile.personal\)' <<<"$output"
  grep -qE 'GUI apps \+ dotfiles +yes' <<<"$output"
  grep -qE 'macOS defaults +yes' <<<"$output"
  grep -qE 'Work configs +no' <<<"$output"
}

@test "profile_component_summary: work → GUI + work overlay, work yes" {
  run profile_component_summary work
  grep -qE '\+ work \(Brewfile.work\)' <<<"$output"
  grep -qE 'Work configs +yes' <<<"$output"
  grep -qE 'macOS defaults +yes' <<<"$output"
}

@test "profile_component_summary: server → core only, no GUI" {
  run profile_component_summary server
  grep -qE 'Package overlay +core only' <<<"$output"
  grep -qE 'GUI apps \+ dotfiles +no' <<<"$output"
}
