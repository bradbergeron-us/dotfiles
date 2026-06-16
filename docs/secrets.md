# Encrypted Secrets (sops + age)

This repo can store secrets (API tokens, `.env` files, credentials) **encrypted in git** using [sops](https://github.com/getsops/sops) with the [age](https://github.com/FiloSottile/age) backend. Encrypted files are safe to commit; only someone holding the matching age **private key** can decrypt them.

The encryption policy lives in [`.sops.yaml`](https://github.com/bradbergeron-us/dotfiles/blob/main/.sops.yaml). A small wrapper, [`scripts/secrets.sh`](https://github.com/bradbergeron-us/dotfiles/blob/main/scripts/secrets.sh), provides `edit` / `encrypt` / `decrypt` helpers.

!!! tip "Looking for the quick recipe?"
    This page is the reference and safety model. For a step-by-step task
    walkthrough (encrypt → edit → rotate a secret), see the
    **"Encrypt, edit & rotate a secret"** guide in the **How-to guides**
    section.

---

## How it works

- **age** is the encryption backend. You hold a key pair: a **public key** (`age1...`, safe to share/commit) and a **private key** (secret, never committed).
- **sops** encrypts only the *values* in structured files (YAML/JSON/env/etc.), leaving keys readable so diffs stay meaningful. It reads `.sops.yaml` to decide which files to encrypt and to which recipient(s).
- Your private key lives at `~/.config/sops/age/keys.txt` — **outside this repo**. sops finds it via the `SOPS_AGE_KEY_FILE` environment variable, which `scripts/secrets.sh` defaults to that path.

---

## Setup (one time per machine)

1. **Install the tools** (already in the core `Brewfile`):
   ```sh
   brew bundle --file=~/dotfiles/Brewfile   # installs sops + age
   ```
2. **Generate your age key pair**:
   ```sh
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```
   This prints a line like `# public key: age1qpz...`. The file also contains your **private** key — keep it secret.
3. **Register your public key** in [`.sops.yaml`](https://github.com/bradbergeron-us/dotfiles/blob/main/.sops.yaml): replace the placeholder recipient(s) under `creation_rules` with the `age1...` public key from step 2, then commit `.sops.yaml`.
   - To share secrets across multiple machines or teammates, list each public key as its own `age:` entry — every listed recipient can decrypt.
   - After changing recipients, re-key existing files with `sops updatekeys <file>`.

> **Backup your private key.** If you lose `~/.config/sops/age/keys.txt`, encrypted files become unrecoverable. Store a copy in a password manager or other secure vault — never in this repo.

---

## Daily usage

Files are matched by the `path_regex` rules in `.sops.yaml`. By default this repo encrypts files under a `secrets/` directory and files named `*.secret.*` / `*.enc.*` (e.g. `secrets/aws.yaml`, `config.secret.env`).

Edit a secret (decrypts to a temp file in `$EDITOR`, re-encrypts on save):
```sh
bash ~/dotfiles/scripts/secrets.sh edit secrets/aws.yaml
```

Encrypt an existing plaintext file in place:
```sh
bash ~/dotfiles/scripts/secrets.sh encrypt secrets/aws.yaml
```

Decrypt to a plaintext sibling file (`<file>.dec`, gitignored):
```sh
bash ~/dotfiles/scripts/secrets.sh decrypt secrets/aws.yaml
# → writes secrets/aws.yaml.dec  (delete it when done)
```

You can also call `sops` directly; the wrapper just sets `SOPS_AGE_KEY_FILE` and adds guard rails:
```sh
sops secrets/aws.yaml            # edit in place
sops --decrypt secrets/aws.yaml  # print plaintext to stdout
```

---

## Safety model

- **Never commit private keys.** `~/.config/sops/age/keys.txt` lives outside the repo. `.gitignore` also blocks stray copies inside it: `*.agekey`, `age-key.txt`, `keys.txt`.
- **Never commit decrypted output.** The `decrypt` command writes `*.dec` files, which `.gitignore` blocks. Delete them when finished.
- **Only commit sops-encrypted files.** Inspect a file before committing — an encrypted sops file contains `sops:` metadata and `ENC[...]` values. If you see raw plaintext secrets, stop and encrypt first.
- **Defense in depth.** The repo's `gitleaks` pre-commit hook and CI job scan for accidentally committed secrets, but the encryption boundary above is the primary protection.
- **Rotate on exposure.** If a private key or plaintext secret is ever exposed, rotate the affected credentials and generate a new age key, then `sops updatekeys` all files.

### Why values, not whole files

sops encrypts only the *values* in a structured file, leaving keys (and the
`sops:` metadata block) in cleartext. This is deliberate: `git diff` still shows
*which* keys changed without revealing secrets, code review stays meaningful, and
merge conflicts are tractable. The trade-off — key *names* are visible — is
acceptable because the sensitive material is the values. Avoid putting secrets in
key names.

## Rotating and re-keying

Two distinct operations are often conflated:

- **Rotating a secret value** (e.g. a leaked API token): change the secret at the
  source (revoke + reissue the credential), then update its encrypted value:
  ```sh
  bash ~/dotfiles/scripts/secrets.sh edit secrets/aws.yaml   # paste the new value, save
  ```
- **Re-keying recipients** (adding/removing a machine or teammate): edit the
  `age:` recipients under the matching `creation_rules` entry in `.sops.yaml`,
  commit it, then re-encrypt every existing file to the new recipient set:
  ```sh
  sops updatekeys secrets/aws.yaml   # repeat per file, or script across them
  ```
  Only recipients listed *before* a file was last re-keyed can decrypt it —
  removing a recipient from `.sops.yaml` does **not** retroactively lock them out
  of copies they already pulled, so rotate the underlying secret values too when
  revoking access.

## Related

- [Architecture](architecture.md#sopsyaml) — where `.sops.yaml` sits in the SSOT model.
- [Troubleshooting](troubleshooting.md#encrypted-secrets-sops-age) — fixes for
  missing keys and decryption failures.
- [Glossary](glossary.md#sops-age) — quick definitions of sops and age.
- The **How-to guides** section — the task-oriented encrypt/edit/rotate recipe.
