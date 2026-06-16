# Encrypted Secrets (sops + age)

This repo can store secrets (API tokens, `.env` files, credentials) **encrypted in git** using [sops](https://github.com/getsops/sops) with the [age](https://github.com/FiloSottile/age) backend. Encrypted files are safe to commit; only someone holding the matching age **private key** can decrypt them.

The encryption policy lives in [`.sops.yaml`](https://github.com/bradbergeron-us/dotfiles/blob/main/.sops.yaml). A small wrapper, [`scripts/secrets.sh`](https://github.com/bradbergeron-us/dotfiles/blob/main/scripts/secrets.sh), provides `edit` / `encrypt` / `decrypt` helpers.

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
