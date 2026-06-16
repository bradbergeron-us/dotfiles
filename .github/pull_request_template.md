## Summary
<!-- What does this change, and why? -->

## Type
- [ ] Feature
- [ ] Fix
- [ ] Refactor / chore
- [ ] Docs

## Validation
<!-- Tick what you ran — see CONTRIBUTING.md "Before you commit". -->
- [ ] `shellcheck -S warning` on changed bash; `zsh -n` on changed zsh files (`install.sh`, `home/zshrc`, …)
- [ ] Ran the bats suite (`bats scripts/tests/`)
- [ ] Exercised install/verify against an isolated `HOME=$(mktemp -d)` (if behavior changed)

## Checklist
- [ ] New tracked dotfile? Added a line to `config/symlinks.map` and a row to the README table
- [ ] Changed a real `bootstrap.sh` step? Updated its `--dry-run` preview in `scripts/lib/dryrun_helpers.sh`
- [ ] Updated docs (`README.md` / `docs/`) and the `CHANGELOG.md` `[Unreleased]` section as needed
- [ ] No secrets or machine-specific values committed (gitleaks runs in CI and pre-commit)

## Notes
<!-- Links, screenshots, or follow-ups. -->
