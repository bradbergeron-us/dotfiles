# Continue IDE Configuration Template

This template configures the Continue IDE extension to use AWS Bedrock models (Claude Sonnet).

## Prerequisites

- AWS account with Bedrock access
- AWS CLI installed (`brew install awscli`)
- Continue IDE extension for VS Code
- AWS credentials configured (see [../aws/README.md](../aws/README.md))

## Installation

```bash
mkdir -p ~/.continue
cp ~/dotfiles/templates/continue/config.yaml.template ~/.continue/config.yaml
```

Then edit `~/.continue/config.yaml` to customize for your environment.

## Configuration Steps

### 1. Update Model Configuration

Replace these placeholders in `config.yaml`:

```yaml
# Model ID or ARN - check AWS Bedrock console for available models
model: us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0

# AWS region where Bedrock is enabled
region: us-gov-west-1

# AWS profile name from ~/.aws/config
profile: bedrock
```

#### Finding Your Model ID

**For AWS Commercial:**
```bash
aws bedrock list-foundation-models --region us-east-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)].modelId'
```

**For AWS GovCloud:**
```bash
aws bedrock list-foundation-models --region us-gov-west-1 \
  --query 'modelSummaries[?contains(modelId, `claude`)].modelId' \
  --profile your-govcloud-profile
```

Common model IDs:
- Commercial: `anthropic.claude-3-5-sonnet-20241022-v2:0`
- GovCloud: `us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0`

### 2. Configure AWS Credentials

See [../aws/README.md](../aws/README.md) for detailed AWS credential setup.

Quick start:
```bash
# For SSO (recommended)
aws configure sso --profile bedrock

# Test access
aws bedrock list-foundation-models --region us-gov-west-1 --profile bedrock
```

### 3. Install SSL Certificate (if behind corporate proxy)

If your organization uses a custom SSL certificate (e.g., Zscaler), you'll need to install it.

#### Obtaining the Certificate

Ask your IT department for your organization's root certificate, or export it from your browser:

**From Chrome/Edge:**
1. Visit any HTTPS site
2. Click the lock icon → Connection is secure → Certificate is valid
3. Certificate Viewer → Details → Export
4. Save as `YourOrgRootCertificate.crt`

**From Firefox:**
1. Preferences → Privacy & Security → View Certificates
2. Authorities tab → Select your org's certificate
3. Export → Save as `YourOrgRootCertificate.crt`

#### Installing the Certificate

```bash
# Create certs directory
mkdir -p ~/.continue/certs

# Copy certificate
cp /path/to/YourOrgRootCertificate.crt ~/.continue/certs/

# Add to Node.js environment
echo 'export NODE_EXTRA_CA_CERTS="$HOME/.continue/certs/YourOrgRootCertificate.crt"' >> ~/.zshrc.local

# Reload shell
source ~/.zshrc
```

#### System Keychain (optional but recommended)

Install to macOS System Keychain for system-wide trust:
```bash
sudo security add-trusted-cert -d -r trustRoot \
  -k /Library/Keychains/System.keychain \
  ~/.continue/certs/YourOrgRootCertificate.crt
```

### 4. Verify Setup

```bash
# Check AWS credentials work
aws bedrock list-foundation-models --region us-gov-west-1 --profile bedrock

# Test Continue in VS Code
# 1. Open VS Code
# 2. Open Continue panel (Cmd+L or click Continue icon)
# 3. Type a test prompt: "Hello, can you help me write code?"
```

## Customization

### Adding Additional Models

You can add more models to support different use cases:

```yaml
models:
  - name: Claude Opus (Powerful)
    provider: bedrock
    model: anthropic.claude-opus-4-20250514-v1:0
    env:
      region: us-east-1
      profile: bedrock
    roles: [chat, edit]

  - name: Claude Haiku (Fast)
    provider: bedrock
    model: anthropic.claude-3-5-haiku-20241022-v1:0
    env:
      region: us-east-1
      profile: bedrock
    roles: [chat]
    defaultCompletionOptions:
      temperature: 0.3
      maxTokens: 4096
```

### Custom Rules

Modify the `rules` section to customize AI behavior:

```yaml
rules:
  - Use TypeScript for all JavaScript code
  - Follow Airbnb style guide for JavaScript/TypeScript
  - Always include JSDoc comments for public functions
  - Write Jest tests for all new functions
  - Use functional programming patterns when possible
```

### Context Providers

Enable/disable context providers based on your workflow:

```yaml
context:
  - provider: codebase      # Semantic code search
  - provider: code          # Code snippets
  - provider: open          # Open files
  - provider: problems      # Linter errors
  - provider: currentFile   # Current file
  - provider: docs          # Documentation
  - provider: diff          # Git diff
  - provider: folder        # Folder tree
  - provider: terminal      # Terminal output
  # - provider: postgres    # Database schema (requires setup)
  # - provider: database    # General database
```

## Troubleshooting

### "Unable to invoke model" error

**Cause**: Bedrock access not enabled for your AWS account/region

**Solution**:
1. Go to AWS Bedrock console
2. Navigate to "Model access" in the left sidebar
3. Click "Manage model access"
4. Enable access for Claude models
5. Wait 1-2 minutes for access to be granted

### SSL Certificate errors

**Symptoms**: `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_HAS_EXPIRED`, `SELF_SIGNED_CERT_IN_CHAIN`

**Solution**: Install your organization's root certificate (see step 3 above)

### "Invalid AWS credentials" error

**Cause**: AWS profile not configured or credentials expired

**Solution**:
```bash
# For SSO, re-login
aws sso login --profile bedrock

# For access keys, reconfigure
aws configure --profile bedrock
```

### Models appear but don't respond

**Cause**: Network/firewall blocking AWS Bedrock API calls

**Solution**:
1. Check corporate proxy settings
2. Verify `NO_PROXY` environment variable doesn't block AWS
3. Test with `curl` to verify connectivity:
   ```bash
   aws bedrock-runtime invoke-model \
     --model-id anthropic.claude-3-5-sonnet-20241022-v2:0 \
     --body '{"anthropic_version":"bedrock-2023-05-31","messages":[{"role":"user","content":"Hello"}],"max_tokens":100}' \
     --region us-east-1 \
     --profile bedrock \
     /dev/stdout
   ```

### Continue extension not loading config

**Location**: Verify config file is in the correct location:
```bash
ls -la ~/.continue/config.yaml
```

**Reload**: Restart VS Code or reload the window (Cmd+Shift+P → "Reload Window")

## Security Notes

- **NEVER** commit AWS credentials to this config file
- Use AWS profiles (references to `~/.aws/credentials`)
- Rotate AWS access keys regularly per your organization's policy
- Use AWS SSO/IAM Identity Center when available (more secure than access keys)
- Certificate files are safe to commit (public certificates only)

## See Also

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Continue Documentation](https://docs.continue.dev/)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
