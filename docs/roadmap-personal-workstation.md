# Personal Workstation Roadmap

!!! note "Status: future ideas — not implemented"
    This page is a **backlog**. Nothing here is built yet, and none of it should
    be implemented as a side effect of other work. It captures directions the
    `dotfiles` CLI could grow in, so ideas are not lost. Each item is a sketch of
    a possible future command, not a committed design.

The unified [`dotfiles` CLI](cli.md) gives us one place to add higher-level
workflows over time. The themes below are candidate subcommands; they would be
added incrementally, each behind its own review, with the same guardrails the
rest of the repo follows (no secrets, prefer wrapping existing tools, keep
behavior reversible and previewable).

## Project bootstrap

Scaffold sensible per-project defaults so new repos start consistent.

Possible commands:

```bash
dotfiles project init rails
dotfiles project init node
dotfiles project init python
dotfiles project init va-gov
```

Possible generated files: `.envrc`, `.mise.toml`, `.editorconfig`,
`.pre-commit-config.yaml`, `.vscode/settings.json`, `.gitignore`.

## AI workstation support

Manage local AI tooling (Claude Code, Continue, model/cert config) coherently.

Possible commands:

```bash
dotfiles ai status
dotfiles ai setup
dotfiles ai doctor
```

Possible prompt templates: `templates/prompts/code-review.md`,
`templates/prompts/refactor-plan.md`, `templates/prompts/debugging.md`,
`templates/prompts/pr-description.md`.

## Security scan

A convenience wrapper over existing security checks.

Possible command:

```bash
dotfiles security scan
```

Possible checks: gitleaks, unsafe file permissions, accidental `.env` commits,
SSH config issues, missing Git signing config.

## Backup and restore

Capture and restore the *unmanaged* parts of a machine (the managed dotfiles are
already reproducible from the repo).

Possible commands:

```bash
dotfiles backup create
dotfiles backup restore
dotfiles backup list
```

Safe default backup candidates: `~/.zshrc.local`, `~/.config/git/*.gitconfig`,
the VS Code extension list, `brew leaves`, mise-installed runtimes, Ghostty local
overrides. **Never** back up private SSH keys by default.

## Package / profile management

Make Brewfile and profile drift easy to inspect and explain.

Possible commands:

```bash
dotfiles packages list
dotfiles packages missing
dotfiles packages outdated
dotfiles packages explain ghostty
```

## Neovim improvements

Keep this conservative. Future direction:

- Preserve the dependency-free baseline (`config/nvim/init.lua`).
- Organize config into modules only if it earns its keep.
- Add optional local overrides.
- Avoid turning it into a heavy plugin distribution unless there is a real need.

## Definition of done (for this page)

- The roadmap exists and clearly separates future ideas from current behavior.
- No future feature is implemented just because it is listed here.
