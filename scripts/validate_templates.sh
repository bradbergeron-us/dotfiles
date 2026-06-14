#!/usr/bin/env bash
# validate_templates.sh — assert template files carry placeholders, not secrets.
#
# Scans every tracked *.template file in the repo and FAILS if a file appears to
# contain a real secret (token, key, password, long base64/hex blob, or a
# credential-bearing URL/email) instead of a safe placeholder.
#
# Usage:
#   bash scripts/validate_templates.sh            # scan the whole repo
#   bash scripts/validate_templates.sh path ...   # scan only the given files
#   bash scripts/validate_templates.sh --help
#
# Exit codes:
#   0 = all scanned templates contain only placeholders (CI: pass)
#   1 = one or more suspected real secrets found              (CI: fail)
#   2 = usage / environment error
#
# ── Detection heuristics ──────────────────────────────────────────────────────
# Two tiers keep false positives low while still catching real leaks:
#
#   1. High-confidence signatures (ALWAYS flagged, even inside comments):
#      unambiguous credential formats — private-key blocks, AWS access key IDs,
#      GitHub/GitLab/Slack/Stripe tokens, Google API keys, JWTs, Vault tokens.
#      Placeholders effectively never match these, so they are never excused.
#
#   2. Entropy / shape heuristics (flagged UNLESS the line is a known placeholder):
#      contiguous base64 blobs (40+ chars), long hex strings (32+ chars),
#      secret-keyword assignments (password/token/secret/... = <long value>),
#      and credential-bearing URLs / "email:token" pairs.
#
# A line is treated as a SAFE placeholder (heuristics skipped, tier 1 still runs)
# when it matches the documented template placeholder conventions, e.g.
# `REPLACE_WITH_*`, `YOUR_*`, `your-org.example.com`, `{encrypted-*-here}`,
# `123456789012`, and "Replace with ..." / "for example" comments. Real model
# IDs, ARNs and registry URLs in the existing templates are short/segmented and
# do not trip the entropy heuristics, so they pass without an explicit allowlist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Reuse the shared output helpers (setup_colors, info, success, warn, step).
# shellcheck source=scripts/bootstrap_helpers.sh
source "$SCRIPT_DIR/bootstrap_helpers.sh"
# bootstrap_helpers.sh has no error(); define one consistent with preflight.sh.
error() { printf "${YELLOW}  ✗ %s${RESET}\n" "$*"; }
setup_colors

usage() {
  sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac

# ── Pattern definitions ───────────────────────────────────────────────────────
# Tier 1: high-confidence real-secret signatures (always flagged).
HIGH_CONFIDENCE=(
  '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
  '(AKIA|ASIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA)[A-Z0-9]{16}'
  'gh[pousr]_[A-Za-z0-9]{36}'
  'github_pat_[A-Za-z0-9_]{40,}'
  'glpat-[A-Za-z0-9_-]{20,}'
  'xox[abprs]-[A-Za-z0-9-]{10,}'
  'AIza[0-9A-Za-z_-]{35}'
  '(sk|rk)_(live|test)_[0-9A-Za-z]{16,}'
  'hvs\.[A-Za-z0-9]{24,}'
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
)

# Tier 2: entropy / shape heuristics (skipped on placeholder lines).
HEURISTIC=(
  '[A-Za-z0-9+/]{40,}={0,2}'
  '[0-9a-fA-F]{32,}'
  '(password|passwd|secret|token|api[_-]?key|access[_-]?key|auth[_-]?token|client[_-]?secret|private[_-]?key|secret[_-]?key)[[:space:]]*[:=][[:space:]]*.?[A-Za-z0-9+/_.-]{16,}'
  '[a-zA-Z][a-zA-Z0-9+.-]*://[^/[:space:]:@]+:[^/[:space:]@]{8,}@'
  '[A-Za-z0-9._%+-]+(@|%40)[A-Za-z0-9.-]+\.[A-Za-z]{2,}:[A-Za-z0-9+/=._-]{32,}'
)

# Lines matching any of these are treated as safe placeholders for tier-2 checks.
SAFE_MARKERS='(replace_with|replace with|your[_-]|your\.[a-z]|your-org|example\.(com|org|net)|\{encrypted|123456789012|placeholder|changeme|change-me|<[a-z _-]*(password|secret|token|key|username|value)[a-z _-]*>|for example|e\.g\.|todo|fixme|<your)'

# ── Finding bookkeeping ───────────────────────────────────────────────────────
FINDINGS=0
SCANNED=0
SEEN=""   # newline-delimited "file:line" keys, for de-duplication

# trim leading/trailing whitespace and cap length for readable output
snippet() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  if [[ ${#s} -gt 80 ]]; then
    s="${s:0:77}..."
  fi
  printf '%s' "$s"
}

report_finding() {
  local file="$1" lineno="$2" reason="$3" content="$4"
  local key="$file:$lineno"
  case "$SEEN" in
    *"|$key|"*) return 0 ;;  # already reported this line
  esac
  SEEN="$SEEN|$key|"
  error "$file:$lineno — $reason"
  info "$(snippet "$content")"
  FINDINGS=$(( FINDINGS + 1 ))
}

# scan_lines FILE PATTERN SKIP_PLACEHOLDERS REASON
#   SKIP_PLACEHOLDERS=1 → suppress matches on lines that look like placeholders.
scan_lines() {
  local file="$1" pattern="$2" skip="$3" reason="$4"
  local match lineno content
  while IFS= read -r match; do
    [[ -z "$match" ]] && continue
    lineno="${match%%:*}"
    content="${match#*:}"
    if [[ "$skip" == "1" ]] && printf '%s' "$content" | grep -iqE "$SAFE_MARKERS"; then
      continue
    fi
    report_finding "$file" "$lineno" "$reason" "$content"
  done < <(grep -niE "$pattern" "$file" 2>/dev/null || true)
}

scan_file() {
  local file="$1" pat
  SCANNED=$(( SCANNED + 1 ))
  for pat in "${HIGH_CONFIDENCE[@]}"; do
    scan_lines "$file" "$pat" 0 "high-confidence secret signature"
  done
  for pat in "${HEURISTIC[@]}"; do
    scan_lines "$file" "$pat" 1 "resembles a real secret"
  done
}

# ── Collect target files ──────────────────────────────────────────────────────
TEMPLATES=()
if [[ $# -gt 0 ]]; then
  for f in "$@"; do
    [[ -f "$f" ]] && TEMPLATES+=("$f")
  done
elif git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  while IFS= read -r f; do
    [[ -n "$f" ]] && TEMPLATES+=("$REPO_ROOT/$f")
  done < <(git -C "$REPO_ROOT" ls-files '*.template')
else
  while IFS= read -r f; do
    TEMPLATES+=("$f")
  done < <(find "$REPO_ROOT" -type f -name '*.template')
fi

echo ""
printf "${BOLD}  🔐  validate templates${RESET}  —  scanning for leaked secrets\n"
echo "  ─────────────────────────────────────────────────"

if [[ ${#TEMPLATES[@]} -eq 0 ]]; then
  warn "No *.template files found to scan"
  exit 0
fi

for tpl in "${TEMPLATES[@]}"; do
  scan_file "$tpl"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────────────────────"
if [[ "$FINDINGS" -gt 0 ]]; then
  printf "${BOLD}${YELLOW}  ❌  %d suspected secret(s) across %d template(s)${RESET}\n" "$FINDINGS" "$SCANNED"
  echo "  Replace real values with placeholders (REPLACE_WITH_*, YOUR_*, example.com)."
  echo "  ─────────────────────────────────────────────────"
  exit 1
fi

success "$SCANNED template(s) scanned — placeholders only, no secrets detected"
echo "  ─────────────────────────────────────────────────"
exit 0
