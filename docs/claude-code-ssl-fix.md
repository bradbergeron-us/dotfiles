# Claude Code SSL Certificate Fix

If Claude Code fails with:
```
Unable to connect to API: SSL certificate verification failed
```

This happens when behind corporate SSL inspection (Zscaler, BlueCoat, etc.). The
fixes below go in `~/.zshrc.local` — your machine-local, un-committed shell
config — so they never leak into the tracked dotfiles. On a `work` machine the
certificate is usually set up as part of the [work setup](work-setup-complete.md).

## Quick Fix

### Option 1: Use Corporate Certificate (Recommended)

1. Locate your corporate root certificate:
   ```bash
   # Common locations:
   ~/Downloads/ClaudeCode-macOS-*/ZscalerRootCertificate-*.crt
   /Library/Application Support/ZscalerRootCertificate.crt
   ```

2. Add to `~/.zshrc.local`:
   ```bash
   export NODE_EXTRA_CA_CERTS="$HOME/path/to/ZscalerRootCertificate.crt"
   ```

3. Reload shell:
   ```bash
   source ~/.zshrc
   ```

### Option 2: Disable SSL Verification (Less Secure)

Only use if you cannot obtain the corporate certificate.

Add to `~/.zshrc.local`:
```bash
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

Reload shell:
```bash
source ~/.zshrc
```

## Verify Fix

```bash
claude --version
# Should show version without SSL errors
```

## Finding Your Certificate

If you have a ClaudeCode download folder from IT:
```bash
find ~/Downloads -name "*Zscaler*" -o -name "*root*cert*" 2>/dev/null
```

Or check system keychain:
```bash
security find-certificate -a -p /Library/Keychains/System.keychain | grep -B 5 Zscaler
```

Contact your IT department if you cannot locate the certificate.

## See also

- [Set up a work laptop](tutorials/work-laptop.md) — the full `work`-profile setup flow.
- [Complete Work Machine Setup Guide](work-setup-complete.md) — corporate certificates and proxy setup in depth.
- [Troubleshooting](troubleshooting.md) — other common failures and fixes.
