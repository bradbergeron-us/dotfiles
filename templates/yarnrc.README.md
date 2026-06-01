# Yarn Configuration Template

This template configures Yarn to use your organization's npm registry (JFrog Artifactory, Nexus, etc.).

## Installation

```bash
cp ~/dotfiles/templates/yarnrc.template ~/.yarnrc
```

Then edit `~/.yarnrc` to replace the placeholder registry URL.

## Configuration Steps

### 1. Update Registry URL

Replace `https://registry.example.com/artifactory/api/npm/npm-proxy/` with your organization's actual npm registry URL.

Common formats:
- JFrog Artifactory: `https://your-org.jfrog.io/artifactory/api/npm/npm-proxy/`
- Nexus: `https://nexus.your-org.com/repository/npm-group/`
- Azure Artifacts: `https://pkgs.dev.azure.com/your-org/_packaging/your-feed/npm/registry/`

### 2. Configure Authentication

Authentication credentials should be stored separately in `~/.npmrc`, not in `.yarnrc`.

```bash
# Set authentication for your registry
npm config set //registry.example.com/artifactory/api/npm/npm-proxy/:_authToken "YOUR-TOKEN-HERE"

# Or use npm login if your registry supports it
npm login --registry=https://registry.example.com/artifactory/api/npm/npm-proxy/
```

### 3. SSL Certificate (if required)

If your organization uses a custom SSL certificate (e.g., Zscaler), you may need to:

**Option A: Set strict-ssl to false** (less secure, but sometimes required)
```bash
yarn config set strict-ssl false
```

**Option B: Install the certificate** (more secure)
```bash
# See ../continue/README.md for certificate installation instructions
# Add to ~/.zshrc.local:
export NODE_EXTRA_CA_CERTS="$HOME/.continue/certs/YourOrgRootCertificate.crt"
```

### 4. Verify Setup

```bash
# Test yarn can access your registry
yarn config list

# Try installing a package
yarn add lodash
```

## Yarn vs NPM

This setup works for both Yarn and NPM since they share the `~/.npmrc` authentication config.

```bash
# Both should work after configuration
yarn add package-name
npm install package-name
```

## Troubleshooting

### "Couldn't find package" errors

Verify your registry URL is correct and accessible:
```bash
curl -I https://registry.example.com/artifactory/api/npm/npm-proxy/
```

### SSL/Certificate errors

Either install your organization's root certificate or set `strict-ssl false`.

### Authentication failures

Check your auth token is set correctly:
```bash
npm config get //registry.example.com/artifactory/api/npm/npm-proxy/:_authToken
```

## Security Notes

- **NEVER** commit auth tokens to `.yarnrc` or `.npmrc`
- Tokens should be stored in `~/.npmrc` (not tracked by dotfiles)
- The `.yarnrc` file is safe to commit (only contains public registry URLs)
- Rotate your tokens regularly per your organization's policy

## See Also

- [Yarn Configuration Docs](https://classic.yarnpkg.com/en/docs/yarnrc/)
- [NPM Config Docs](https://docs.npmjs.com/cli/v9/configuring-npm/npmrc)
- [JFrog Artifactory NPM Setup](https://www.jfrog.com/confluence/display/JFROG/npm+Registry)
