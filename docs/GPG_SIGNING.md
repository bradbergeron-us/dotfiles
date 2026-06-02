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

The main `~/.gitconfig` is already configured to sign all commits and tags.

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
