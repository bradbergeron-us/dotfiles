#!/usr/bin/env bash
# profile_helpers.sh — pure, side-effect-light helpers for machine profiles.
#
# A "profile" is the durable identity of a managed machine. It is persisted at
# ~/.config/dotfiles/profile and honored by bootstrap/install/update/verify/
# status so one repo can serve several distinct devices (today: a personal and
# a work laptop) from a shared core. Helpers echo values or return status only —
# no UI, no exit — so they are unit-testable.
# shellcheck disable=SC2034  # globals are consumed by the sourcing scripts

# Canonical profiles. `personal` and `work` map to real managed devices today;
# `minimal` and `server` are presets (and CI fixtures) for future use.
DOTFILES_PROFILES="minimal personal work server"
DOTFILES_DEFAULT_PROFILE="personal"
# Override DOTFILES_PROFILE_FILE in tests; defaults to the XDG-style location.
DOTFILES_PROFILE_FILE="${DOTFILES_PROFILE_FILE:-$HOME/.config/dotfiles/profile}"

# valid_profile NAME — return 0 if NAME is a known profile.
valid_profile() {
  # `case` membership avoids splitting $DOTFILES_PROFILES, which bash splits but
  # zsh does not — important because install.sh (zsh) sources this file.
  case " $DOTFILES_PROFILES " in
    *" $1 "*) return 0 ;;
    *)        return 1 ;;
  esac
}

# resolve_profile [FLAG] — echo the active profile, in increasing precedence:
#   1. default ($DOTFILES_DEFAULT_PROFILE)
#   2. persisted file ($DOTFILES_PROFILE_FILE)
#   3. $DOTFILES_PROFILE environment variable
#   4. FLAG argument (e.g. from `--profile <name>`)
# Higher sources win; an unrecognized value at any level is ignored (falls
# through) so a typo can never select an invalid profile. Always echoes a valid
# profile.
resolve_profile() {
  # if-based control flow (no bare `A && B`) so this is safe under both bash and
  # zsh errexit — install.sh (zsh) resolves the profile via current_profile.
  local flag="${1:-}" result="$DOTFILES_DEFAULT_PROFILE" v
  if [[ -f "$DOTFILES_PROFILE_FILE" ]]; then
    v="$(tr -d '[:space:]' < "$DOTFILES_PROFILE_FILE" 2>/dev/null || true)"
    if valid_profile "$v"; then result="$v"; fi
  fi
  v="${DOTFILES_PROFILE:-}"
  if [[ -n "$v" ]] && valid_profile "$v"; then result="$v"; fi
  if [[ -n "$flag" ]] && valid_profile "$flag"; then result="$flag"; fi
  echo "$result"
}

# current_profile — resolve with no flag (env / persisted file / default).
# Convenience for update.sh / verify.sh / status.sh.
current_profile() { resolve_profile ""; }

# persist_profile NAME — validate NAME and write it to the profile file.
# Returns 1 on an invalid name (caller reports). Creates the parent dir.
persist_profile() {
  local name="$1"
  valid_profile "$name" || return 1
  mkdir -p "$(dirname "$DOTFILES_PROFILE_FILE")" 2>/dev/null || true
  printf '%s\n' "$name" > "$DOTFILES_PROFILE_FILE"
}

# profile_includes PROFILE TAGS — return 0 if items tagged TAGS apply to PROFILE.
# TAGS is a comma/space-separated list (from symlinks.map / Brewfile overlays).
# Empty TAGS applies everywhere. Matching is a union over the tags:
#   (none) / core -> all profiles
#   gui            -> personal, work   (machines with a GUI)
#   work           -> work
#   <profile-name> -> that profile exactly (minimal | personal | work | server)
profile_includes() {
  local profile="$1" tags="${2:-}" tag rest
  [[ -z "$tags" ]] && return 0
  rest="${tags//,/ }"  # normalize commas to spaces
  # Walk tokens with parameter expansion only (no word-splitting, so this works
  # the same in bash and zsh).
  while [[ -n "$rest" ]]; do
    tag="${rest%% *}"            # first token (whole string if no space)
    if [[ "$rest" == *" "* ]]; then rest="${rest#* }"; else rest=""; fi
    [[ -z "$tag" ]] && continue  # skip empties from repeated separators
    case "$tag" in
      core) return 0 ;;
      gui)  if [[ "$profile" == "personal" || "$profile" == "work" ]]; then return 0; fi ;;
      work) if [[ "$profile" == "work" ]]; then return 0; fi ;;
      *)    if [[ "$profile" == "$tag" ]]; then return 0; fi ;;
    esac
  done
  return 1
}

# profile_brewfiles PROFILE DOTFILES_DIR — echo the Brewfile paths to install for
# PROFILE, one per line: the core Brewfile always, plus Brewfile.personal for GUI
# profiles (personal/work) and Brewfile.work for work. minimal/server get core
# only. Only files that exist are emitted.
profile_brewfiles() {
  local profile="$1" dir="$2"
  printf '%s\n' "$dir/Brewfile"
  if profile_includes "$profile" gui && [[ -f "$dir/Brewfile.personal" ]]; then
    printf '%s\n' "$dir/Brewfile.personal"
  fi
  if profile_includes "$profile" work && [[ -f "$dir/Brewfile.work" ]]; then
    printf '%s\n' "$dir/Brewfile.work"
  fi
}
