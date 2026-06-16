# Set up a work laptop

This tutorial walks a fresh **work** Mac from clone to a verified state using the
`work` profile. The `work` profile is a superset of `personal`: it adds the work
package overlay (`Brewfile.work`), `work`-tagged dotfiles, and the work-configs
prompt for corporate Maven/Yarn/Bundle/Continue/Claude/AWS setup.

This page focuses on the work-specific decisions — the profile, the work-configs
prompt, secrets, and commit signing. For an annotated walkthrough of the generic
steps, do the [Getting started](getting-started.md) tutorial first. For the
exhaustive corporate reference (certificates, AWS Bedrock, VS Code extensions),
see the [Complete Work Machine Setup Guide](../work-setup-complete.md).

!!! note "Before you start"
    Have on hand: access to your dotfiles repo, corporate network/VPN access, and
    any registry or AWS credentials your team uses. macOS 12+ with admin access.

## Step 1 — Clone and bootstrap with the work profile

Clone the repo, then bootstrap with `--profile work` so you never have to touch
the picker:

```sh
git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
bash ~/dotfiles/bootstrap.sh --profile work
```

Passing `--profile work` resolves and **persists** the `work` profile to
`~/.config/dotfiles/profile`, so `update.sh`, `verify.sh`, and `status.sh` all
treat this machine as a work machine afterward. The component summary confirms
the work-specific rows are enabled:

```text
  Profile  work
  ─────────────────────────────────────────────────
  This profile sets up
  Runtimes (mise)      yes
  Core CLI + dotfiles  yes
  Package overlay      core + GUI (Brewfile.personal) + work (Brewfile.work)
  GUI apps + dotfiles  yes
  Work configs         yes
  macOS defaults       yes
  ─────────────────────────────────────────────────
```

Note the package overlay line: `work` installs the core `Brewfile`,
`Brewfile.personal` (GUI), **and** `Brewfile.work`, in that order.

## Step 2 — Set up commit signing (SSH key)

During the **SSH key for commit signing** step, if you have no
`~/.ssh/id_ed25519`, bootstrap generates an Ed25519 key, registers it for local
signature verification (`~/.config/git/allowed_signers`), and copies the public
key to your clipboard. It then pauses with instructions:

```text
  Action required: add your key to GitHub

  Your public key is already on your clipboard. Go to:
    https://github.com/settings/ssh/new

  Title:    e.g. 'MacBook Pro — commit signing'
  Key type: Signing Key  ← not Authentication Key
  Key:      paste from clipboard
```

Add the key to GitHub as a **Signing Key** (not an Authentication Key), then
press Enter to continue. From here every commit is SSH-signed and GitHub shows a
**Verified** badge.

!!! tip "Already have a key?"
    If `~/.ssh/id_ed25519` exists, bootstrap skips generation and keeps your
    current key. To use GPG instead of SSH signing, see
    [GPG Commit Signing](../GPG_SIGNING.md).

## Step 3 — Answer the work-configs prompt

Because the profile is `work`, bootstrap reaches the **Work-specific
configurations** step (other profiles skip it entirely). It prompts:

```text
  Setup work configs (.m2, .yarnrc, .continue, .claude, .aws)?

  Run work configuration setup? [y/N]
```

Answer `y` to run `scripts/setup_work_configs.sh` now (recommended on first
setup). It interactively offers to create each corporate config — Maven
(`~/.m2/settings.xml`), Yarn (`~/.yarnrc`), Bundle (`~/.bundle/config`), Continue
(`~/.continue/config.yaml`), Claude Code (`~/.claude/settings.json`), and AWS
(`~/.aws/config`) — backing up any existing file first.

If you answer `n`, you can run it manually any time:

```sh
bash ~/dotfiles/scripts/setup_work_configs.sh
```

!!! info "Corporate certificates and Claude Code SSL"
    Behind a corporate proxy you will likely also need the Zscaler root
    certificate and `NODE_EXTRA_CA_CERTS`. Those steps live in the
    [Complete Work Machine Setup Guide](../work-setup-complete.md) and
    [Claude Code SSL Fix](../claude-code-ssl-fix.md).

## Step 4 — Encrypt your work secrets (sops + age)

Store work tokens and credentials **encrypted in git** with sops + age. `sops`
and `age` ship in the core `Brewfile`, so they are already installed. One-time
key setup per machine:

```sh
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

This prints your `age1...` **public key**. Register it as a recipient in
`.sops.yaml`, commit that file, then edit secrets through the wrapper:

```sh
bash ~/dotfiles/scripts/secrets.sh edit secrets/work.yaml
```

!!! warning "Back up the private key"
    `~/.config/sops/age/keys.txt` lives **outside** the repo and is never
    committed. If you lose it, encrypted files become unrecoverable — store a
    copy in your password manager. Full details, including re-keying and the
    safety model, are in [Encrypted Secrets](../secrets.md).

## Step 5 — Tune updates for pinned tooling

Work machines often pin tool versions. Run the daily loop in `--no-upgrade` mode
so it still pulls dotfiles, re-symlinks, and verifies, but skips
brew/mise/rustup/gem upgrades:

```sh
bash ~/dotfiles/update.sh --no-upgrade
```

To make that the persistent default — including for the scheduled launchd job,
which does **not** source your shell rc — set it in the per-machine config file:

```sh
mkdir -p ~/.config/dotfiles
printf 'NO_UPGRADE=true\n' >> ~/.config/dotfiles/update.conf
```

`update.sh` reads `~/.config/dotfiles/update.conf` directly on every run. See
[Usage & lifecycle](../usage.md#per-machine-defaults-updateconf) for the full
precedence (config file < environment < flags).

## Step 6 — Reach a verified state

Open a new shell and run the health check:

```sh
exec zsh
bash ~/dotfiles/verify.sh
```

`verify.sh` prints the active profile in its banner (`Profile  work`) and uses it
to filter the symlink check and Brewfile-drift check — so it validates the core,
personal, **and** work Brewfiles together. Aim for:

```text
  ✅  All checks passed  (3s)
```

A quick repeatable snapshot afterward:

```sh
dotstatus
```

It reports the active profile, the repo's git state, and the result of the last
`update.sh` run.

## You're done

Your work laptop is now on the `work` profile with corporate configs, encrypted
secrets, verified commit signing, and an update loop tuned for pinned tooling.

## Where to next

- [Complete Work Machine Setup Guide](../work-setup-complete.md) — certificates,
  AWS Bedrock/SSO, registries, and VS Code extensions in depth.
- [Encrypted Secrets](../secrets.md) — the full sops + age workflow.
- [Profiles reference](../profiles.md) — how the `work` profile gates each
  component.
- [Adopt a profile on an existing machine](adopt-profile.md) — switch an
  existing machine to (or from) `work`.
