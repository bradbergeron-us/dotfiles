# GPG Commit Signing Setup

This guide covers setting up GPG signing for your Git commits on Bitbucket, GitHub, and other Git hosting providers.

## Quick Setup

Run the automated setup script:

```bash
zsh scripts/setup_gpg_signing.sh
```

This script will:
1. Check if GPG is installed (or install via `brew install gnupg`)
2. List existing GPG keys or help you create a new one
3. Configure your signing key in `~/.config/git/local.gitconfig`
4. Display your public key for uploading to your Git provider

## Manual Setup

### 1. Install GPG

```bash
brew install gnupg
```

### 2. Generate a GPG Key

```bash
gpg --full-generate-key
```

Choose:
- Key type: RSA (default)
- Key size: 4096 bits
- Expiration: 0 (key does not expire) or set an expiration date
- Enter your name and email (use your work email for work repos)
- Set a secure passphrase (recommended)

### 3. List Your Keys

```bash
gpg --list-secret-keys --keyid-format=long
```

Output will look like:
```
sec   rsa4096/EFF15FEC389D0F89 2026-06-02 [SC]
      C1B65DCB44FC8C42E2762273EFF15FEC389D0F89
uid                 [ultimate] Your Name <your.email@example.com>
```

The key ID is `EFF15FEC389D0F89` (after the `/` on the `sec` line).

### 4. Configure Git

Edit `~/.config/git/local.gitconfig`:

```gitconfig
[user]
	signingkey = EFF15FEC389D0F89
```

The main `~/.gitconfig` sets `gpg.format = openpgp` and points Git at your `gpg` program, but leaves `commit.gpgsign = false` by default. To sign every commit on this machine, also enable signing in `~/.config/git/local.gitconfig`:

```gitconfig
[commit]
	gpgsign = true
```

To sign only in specific directories instead, leave the global default off and use [Per-Organization (Conditional) Signing](#per-organization-conditional-signing) below — those configs enable signing automatically.

### 5. Export Your Public Key

```bash
gpg --armor --export EFF15FEC389D0F89
```

Copy the entire output (including the `-----BEGIN PGP PUBLIC KEY BLOCK-----` and `-----END PGP PUBLIC KEY BLOCK-----` lines).

### 6. Upload to Your Git Provider

#### Bitbucket

1. Go to: https://bitbucket.org/account/settings/gpg-keys/
2. Click "Add key"
3. Paste your public key
4. Click "Add key"

#### GitHub

1. Go to: https://github.com/settings/keys
2. Click "New GPG key"
3. Paste your public key
4. Click "Add GPG key"

#### GitLab

1. Go to: https://gitlab.com/-/profile/gpg_keys
2. Paste your public key
3. Click "Add key"

## Per-Organization (Conditional) Signing

The committed `gitconfig` can select a different identity and signing key automatically based on which directory a repository lives in, using Git's `includeIf` directives. This is useful when you contribute to multiple organizations that each require a different email and signed commits.

### Organize repositories by organization

```
~/Code/
├── work1/      # Organization 1 — auto-signs with org 1 email + key
├── work2/      # Organization 2 — auto-signs with org 2 email + key
└── personal/   # Personal projects
```

### How it works

The main `gitconfig` pulls in an organization-specific config when you work under the matching directory:

```gitconfig
[includeIf "gitdir:~/Code/work1/"]
    path = ~/.config/git/work1.gitconfig

[includeIf "gitdir:~/Code/work2/"]
    path = ~/.config/git/work2.gitconfig
```

Each organization config overrides `user.email` and `user.signingkey`, and sets `commit.gpgsign = true`, so commits made anywhere under that directory are signed with the right key.

### Set up an organization

1. Generate a key for the organization and upload its public key to that org's Git host (see [Manual Setup](#manual-setup) above).
2. Create the organization config from the template (it is never committed):
   ```bash
   cp ~/dotfiles/templates/config/git/work.gitconfig.template ~/.config/git/work1.gitconfig
   # Edit ~/.config/git/work1.gitconfig: set the organization email and signing key ID
   ```
   Repeat for `work2`, etc. The directories matched by `includeIf` (`~/Code/work1/`, `~/Code/work2/`) are defined in `gitconfig` — adjust them there if your layout differs.

### Verify

```bash
bash ~/dotfiles/scripts/verify_git_signing.sh
```

This checks that repositories under each configured organization directory resolve to the expected email, signing key, and `commit.gpgsign = true`, reading the per-organization `~/.config/git/*.gitconfig` files. It prints a `PASS` / `FAIL` line per organization and exits non-zero if any are misconfigured.

## Verify Signing

Make a test commit:

```bash
git commit --allow-empty -m "Test GPG signing"
git log --show-signature -1
```

You should see `gpg: Good signature from "Your Name <your.email@example.com>"`.

Push to Bitbucket and check the commit — it should show a "Verified" badge.

## Troubleshooting

### GPG prompts for passphrase on every commit

Install `pinentry-mac` to cache your passphrase:

```bash
brew install pinentry-mac
echo "pinentry-program $(which pinentry-mac)" >> ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

### "gpg failed to sign the data" error

Check your GPG agent:

```bash
echo "test" | gpg --clearsign
```

If this fails, restart the GPG agent:

```bash
gpgconf --kill gpg-agent
gpg-agent --daemon
```

### Commits are not signed at all

The committed `gitconfig` ships with `commit.gpgsign = false`. Confirm signing is enabled and see which config provides each value:

```bash
git config --show-origin --get commit.gpgsign
git config --show-origin --list | grep -E 'user\.(email|signingkey)|commit\.gpgsign'
```

Enable it globally in `~/.config/git/local.gitconfig` (`[commit] gpgsign = true`), or rely on the per-organization configs described above.

### Disable signing globally (emergency rollback)

```bash
git config --global commit.gpgsign false
```

### Wrong key being used

Make sure `~/.config/git/local.gitconfig` has the correct key ID:

```bash
git config --get user.signingkey
```

Update it if needed:

```bash
git config --local user.signingkey EFF15FEC389D0F89
```

## SSH Signing (Alternative)

If you prefer SSH signing instead of GPG:

1. In `~/.gitconfig`, change:
   ```gitconfig
   [gpg]
       format = ssh
   ```

2. In `~/.config/git/local.gitconfig`:
   ```gitconfig
   [user]
       signingkey = ~/.ssh/id_ed25519.pub
   ```

3. Create `~/.config/git/allowed_signers`:
   ```
   your.email@example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
   ```

SSH signing is simpler but may not be supported by all Git providers.

## References

- [GitHub: Signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)
- [Bitbucket: Use GPG keys](https://support.atlassian.com/bitbucket-cloud/docs/use-gpg-keys/)
- [GitLab: Signing commits with GPG](https://docs.gitlab.com/ee/user/project/repository/gpg_signed_commits/)
