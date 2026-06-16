# Manage encrypted secrets

Encrypt secrets in git with [sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age). The policy lives in [`.sops.yaml`](https://github.com/bradbergeron-us/dotfiles/blob/main/.sops.yaml); [`scripts/secrets.sh`](https://github.com/bradbergeron-us/dotfiles/blob/main/scripts/secrets.sh) wraps the common operations. For the full safety model, see [Encrypted Secrets](../secrets.md).

## 1. Generate an age key (one time per machine)

`sops` and `age` ship in the core `Brewfile`. Generate your key pair:

```sh
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

This prints a `# public key: age1...` line. The file also holds your **private** key — it lives outside the repo and must never be committed.

!!! danger
    Back up `~/.config/sops/age/keys.txt` somewhere secure (a password manager). If you lose it, every file encrypted to it becomes unrecoverable.

## 2. Register the public key in `.sops.yaml`

Replace the placeholder recipient(s) under `creation_rules` with the `age1...` **public** key from step 1, then commit `.sops.yaml`. Only the public key goes here.

```yaml
creation_rules:
  - path_regex: (^|/)secrets/.*\.(ya?ml|json|env|ini|toml|txt)$
    age: >-
      age1yourpublickeyhere...
```

The default rules match files under a `secrets/` directory and files named `*.secret.*` / `*.enc.*`.

## 3. Encrypt, edit, and decrypt

`scripts/secrets.sh` sets `SOPS_AGE_KEY_FILE` to `~/.config/sops/age/keys.txt` and adds guard rails.

Encrypt an existing plaintext file in place:

```sh
bash ~/dotfiles/scripts/secrets.sh encrypt secrets/aws.yaml
```

Edit a secret (opens decrypted in `$EDITOR`, re-encrypts on save):

```sh
bash ~/dotfiles/scripts/secrets.sh edit secrets/aws.yaml
```

Decrypt to a gitignored `<file>.dec` sibling (delete it when done):

```sh
bash ~/dotfiles/scripts/secrets.sh decrypt secrets/aws.yaml
# → writes secrets/aws.yaml.dec
```

Before committing, confirm the file shows `sops:` metadata and `ENC[...]` values — never raw plaintext.

## 4. Rotate keys / recipients

To add a teammate or a new machine, append their `age1...` public key as another `age:` entry in `.sops.yaml`, then re-key existing files so the new recipient can decrypt:

```sh
sops updatekeys secrets/aws.yaml
```

If a private key or a plaintext secret is ever exposed: **rotate the affected credentials**, generate a fresh age key (`age-keygen`), update `.sops.yaml`, and run `sops updatekeys` on every encrypted file.

!!! warning
    `.gitignore` blocks `keys.txt`, `*.agekey`, `age-key.txt`, and `*.dec`. The `gitleaks` pre-commit hook and CI job are a backstop — the encryption boundary is the primary protection.

## See also

- [Encrypted Secrets](../secrets.md) — the full reference and safety model.
- [Troubleshooting](../troubleshooting.md) — fixes for missing keys and decryption errors.
