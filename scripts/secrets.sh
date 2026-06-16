#!/usr/bin/env bash
# secrets.sh — thin, safe wrapper around `sops` + `age` for encrypted secrets.
#
# Encryption policy (which files, which recipients) lives in .sops.yaml at the
# repo root. The age PRIVATE key lives OUTSIDE the repo at
# ~/.config/sops/age/keys.txt and is used to decrypt. See docs/secrets.md.
#
# Usage:
#   bash ~/dotfiles/scripts/secrets.sh edit    <file>   # open decrypted in $EDITOR, re-encrypt on save
#   bash ~/dotfiles/scripts/secrets.sh encrypt <file>   # encrypt <file> in place
#   bash ~/dotfiles/scripts/secrets.sh decrypt <file>   # write plaintext to <file>.dec (gitignored)
#   bash ~/dotfiles/scripts/secrets.sh --help

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=scripts/lib/bootstrap_helpers.sh
source "$DOTFILES_DIR/scripts/lib/bootstrap_helpers.sh"
setup_colors

# Default key location (override by exporting SOPS_AGE_KEY_FILE before running).
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

usage() {
  cat <<'USAGE'
Usage: bash secrets.sh <command> [file]

  edit <file>      Open <file> decrypted in $EDITOR; sops re-encrypts on save.
  encrypt <file>   Encrypt <file> in place using the recipients in .sops.yaml.
  decrypt <file>   Decrypt <file> to <file>.dec (gitignored — never commit it).
  --help, -h       Show this help.

Setup (one time):
  1. brew bundle --file=~/dotfiles/Brewfile     # installs sops + age
  2. age-keygen -o ~/.config/sops/age/keys.txt  # generates your key pair
  3. Put the printed public key (age1...) into .sops.yaml creation_rules.

The age PRIVATE key (~/.config/sops/age/keys.txt) and any decrypted *.dec
files must NEVER be committed. See docs/secrets.md for the full safety model.
USAGE
}

# require_cmd NAME — fail with guidance if a dependency is missing.
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    warn "required command '$1' not found"
    info "install it: brew bundle --file=\"$DOTFILES_DIR/Brewfile\""
    return 1
  fi
}

# require_file FILE — fail if the target file is missing.
require_file() {
  if [[ -z "${1:-}" ]]; then
    warn "no file given"
    info "usage: secrets.sh ${ACTION:-<command>} <file>"
    return 1
  fi
  if [[ ! -f "$1" ]]; then
    warn "file not found: $1"
    return 1
  fi
}

# warn_missing_key — soft warning if the age private key is absent.
warn_missing_key() {
  if [[ ! -f "$SOPS_AGE_KEY_FILE" ]]; then
    warn "age key not found at $SOPS_AGE_KEY_FILE"
    info "generate one: age-keygen -o \"$SOPS_AGE_KEY_FILE\""
  fi
}

cmd_edit() {
  local file="${1:-}"
  require_cmd sops
  require_file "$file"
  warn_missing_key
  info "opening $file in \$EDITOR (sops re-encrypts on save)"
  sops "$file"
}

cmd_encrypt() {
  local file="${1:-}"
  require_cmd sops
  require_file "$file"
  info "encrypting $file in place"
  sops --encrypt --in-place "$file"
  success "encrypted $file"
}

cmd_decrypt() {
  local file="${1:-}"
  require_cmd sops
  require_file "$file"
  warn_missing_key
  local out="$file.dec"
  sops --decrypt "$file" >"$out"
  success "decrypted to $out"
  warn "$out is plaintext and gitignored — delete it when done; never commit it"
}

main() {
  local action="${1:-}"
  ACTION="$action"
  case "$action" in
    edit)            shift; cmd_edit "$@" ;;
    encrypt)         shift; cmd_encrypt "$@" ;;
    decrypt)         shift; cmd_decrypt "$@" ;;
    --help|-h|help)  usage ;;
    "")              usage; exit 1 ;;
    *)               warn "unknown command '$action'"; usage; exit 1 ;;
  esac
}

main "$@"
