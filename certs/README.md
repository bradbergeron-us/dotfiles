# Certificate Storage

This directory is for storing SSL/TLS certificates needed for corporate proxy environments (e.g., Zscaler, corporate CA certificates).

## Purpose

Some corporate networks use SSL inspection/proxies that require custom root certificates to be trusted by development tools. This directory provides a central location to store these certificates.

## Usage

### Obtaining Your Certificate

Contact your IT department or export from your browser:

**From Chrome/Edge:**
1. Visit any HTTPS site behind your corporate proxy
2. Click the lock icon → Connection is secure → Certificate is valid
3. Certificate Viewer → Details tab → Export
4. Save as `YourOrgRootCertificate.crt` (or your org's name)

**From Firefox:**
1. Preferences → Privacy & Security → View Certificates
2. Authorities tab → Find your organization's certificate
3. Export → Save as `YourOrgRootCertificate.crt`

**From macOS Keychain:**
1. Open Keychain Access
2. System or Login keychain → Certificates
3. Find your organization's root certificate
4. Right-click → Export → Save as .cer or .crt

### Installing Certificates

```bash
# Copy certificate to this directory
cp /path/to/YourOrgRootCertificate.crt ~/dotfiles/certs/

# Install for Node.js tools (Claude Code, Continue, npm, yarn)
mkdir -p ~/.continue/certs
cp ~/dotfiles/certs/YourOrgRootCertificate.crt ~/.continue/certs/

# Add to shell environment
echo 'export NODE_EXTRA_CA_CERTS="$HOME/.continue/certs/YourOrgRootCertificate.crt"' >> ~/.zshrc.local
source ~/.zshrc

# (Optional) Install to macOS system keychain for system-wide trust
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/dotfiles/certs/YourOrgRootCertificate.crt
```

## Security Notes

### ✅ Safe to Commit

- **Public root certificates** from trusted CAs (your organization's public root cert)
- These are public by design and contain no secrets

### ❌ NEVER Commit

- **Private keys** (`.key`, `.p12`, `.pfx` files)
- **Client certificates** with embedded private keys
- **Passwords** or passphrases for certificates

## Gitignore

This directory has a `.gitignore` that blocks most certificate file types by default. If you need to commit a public certificate, you can force-add it:

```bash
git add -f certs/YourPublicCert.crt
```

But be absolutely certain it's a public certificate with no embedded private key.

## Tools That Use These Certificates

- **Claude Code** - AI coding assistant via AWS Bedrock
- **Continue IDE** - VS Code AI extension via AWS Bedrock
- **npm/yarn** - Node.js package managers
- **curl** - Command-line HTTP client
- **Python requests** - Via `REQUESTS_CA_BUNDLE` or `CURL_CA_BUNDLE`
- **Git** - Via `http.sslCAInfo` config

## Troubleshooting

### Still getting SSL errors after installing cert

1. **Verify cert path is correct:**
   ```bash
   ls -la ~/.continue/certs/
   echo $NODE_EXTRA_CA_CERTS
   ```

2. **Validate certificate:**
   ```bash
   openssl x509 -in ~/.continue/certs/YourCert.crt -text -noout
   ```

3. **Check environment variable is set:**
   ```bash
   env | grep NODE_EXTRA_CA_CERTS
   env | grep CA_BUNDLE
   ```

4. **Restart terminal** after setting environment variables

5. **System keychain** may be needed for some tools:
   ```bash
   security find-certificate -a -c "YourOrgName" -p /Library/Keychains/System.keychain
   ```

### Certificate expired

Corporate certificates typically expire every 1-3 years. If you get expiration errors:

1. Obtain updated certificate from IT
2. Replace old certificate
3. Reinstall to system keychain if you used that method

### Which certificate do I need?

You typically need your organization's **root CA certificate**, not intermediate certificates. Ask your IT department for:
- "Root CA certificate for SSL inspection"
- "Corporate proxy root certificate"
- "Zscaler root certificate" (if using Zscaler)

## See Also

- [Continue Setup](../templates/continue/README.md) - Using certs with Continue IDE
- [Claude Code Setup](../templates/claude/README.md) - Using certs with Claude Code
- [OpenSSL Certificate Verification](https://www.openssl.org/docs/man1.1.1/man1/verify.html)
