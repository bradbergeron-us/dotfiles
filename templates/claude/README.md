# Claude Code Configuration Template

This template configures Claude Code CLI to use AWS Bedrock models.

## Prerequisites

- Claude Code CLI installed (see installation instructions below)
- AWS account with Bedrock access
- AWS CLI installed and configured
- SSL certificate installed (if behind corporate proxy)

## Installation

### 1. Install Claude Code CLI

**Option A: Download from Claude.ai**
```bash
# Download from https://claude.com/download
# Or use the installer from your Downloads folder

# Make installation directory
mkdir -p ~/.local/bin

# Run installer (adjust path to your downloaded installer)
bash ~/Downloads/ClaudeCode-macOS-*/claude-code-installer --prefix="$HOME/.local/bin"

# Verify installation
claude --version
```

**Option B: Manual Installation**
```bash
# If you already have the binary
mkdir -p ~/.local/bin
cp /path/to/claude ~/.local/bin/
chmod +x ~/.local/bin/claude

# Ensure ~/.local/bin is in your PATH (already set in dotfiles zshrc)
```

### 2. Configure Claude Code Settings

```bash
mkdir -p ~/.claude
cp ~/dotfiles/templates/claude/settings.json.template ~/.claude/settings.json
```

Then edit `~/.claude/settings.json` to customize:

#### Update Placeholders

1. **Username**: Replace `REPLACE_WITH_YOUR_USERNAME` with your actual username
   ```bash
   # Quick replace with sed
   sed -i '' "s/REPLACE_WITH_YOUR_USERNAME/$USER/g" ~/.claude/settings.json
   ```

2. **Model IDs**: Update if your organization uses different models
   - Check available models: `aws bedrock list-foundation-models --region us-gov-west-1 --profile bedrock`

3. **AWS Region**: Update if you're using a different region
   - Commercial: `us-east-1`, `us-west-2`, etc.
   - GovCloud: `us-gov-west-1`, `us-gov-east-1`

4. **AWS Profile**: Update to match your AWS CLI profile name
   - Check profiles: `aws configure list-profiles`
   - Create new profile: `aws configure sso --profile bedrock`

5. **Certificate Path**: Update if your certificate is in a different location
   - Or remove `NODE_EXTRA_CA_CERTS` line if not behind corporate proxy

#### Settings Explanation

```json
{
  "env": {
    // Primary model for Claude Code
    "ANTHROPIC_MODEL": "model-id-here",

    // AWS region where Bedrock is available
    "AWS_REGION": "us-gov-west-1",

    // AWS CLI profile to use (from ~/.aws/config)
    "AWS_PROFILE": "bedrock",

    // Enable Bedrock mode (required for AWS Bedrock)
    "CLAUDE_CODE_USE_BEDROCK": "1",

    // Disable telemetry (optional, for air-gapped environments)
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",

    // Smaller/faster model for quick operations
    "ANTHROPIC_SMALL_FAST_MODEL": "anthropic.claude-3-7-sonnet-20250219-v1:0",

    // Maximum tokens for long responses
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "64000",

    // Thinking tokens (extended thinking mode)
    "MAX_THINKING_TOKENS": "1024",

    // Corporate SSL certificate (if required)
    "NODE_EXTRA_CA_CERTS": "/path/to/cert.crt"
  },

  // Enable extended thinking for complex problems
  "alwaysThinkingEnabled": false,

  // UI theme (light or dark)
  "theme": "light"
}
```

### 3. Configure AWS Credentials

See [../aws/README.md](../aws/README.md) for detailed AWS setup.

Quick start:
```bash
# Configure AWS SSO (recommended)
aws configure sso --profile bedrock

# Login
aws sso login --profile bedrock

# Test Bedrock access
aws bedrock list-foundation-models --region us-gov-west-1 --profile bedrock
```

### 4. Install SSL Certificate (if required)

If behind a corporate proxy/firewall, install your organization's root certificate:

```bash
# Create certs directory (Continue uses the same location)
mkdir -p ~/.continue/certs

# Copy certificate
cp /path/to/YourOrgRootCertificate.crt ~/.continue/certs/

# Update certificate path in settings.json
# Replace:  "/Users/REPLACE_WITH_YOUR_USERNAME/.continue/certs/YourOrgRootCertificate.crt"
# With:     "/Users/yourusername/.continue/certs/YourOrgRootCertificate.crt"
```

See [../continue/README.md](../continue/README.md) for detailed certificate installation instructions.

### 5. Verify Setup

```bash
# Test Claude Code
claude --version

# Test with a simple prompt
claude "What is 2+2?"

# Test code generation
cd /tmp
claude "Create a hello world Python script"
```

If everything is configured correctly, Claude Code should:
1. Authenticate using your AWS profile
2. Connect to Bedrock
3. Return a response

## Usage

### Basic Commands

```bash
# Ask a question
claude "How do I reverse a string in Python?"

# Work on current directory
cd ~/projects/my-app
claude "Add error handling to the login function"

# Code review
claude "Review this file for security issues" --file auth.py

# Git integration
claude "Help me write a commit message for these changes"

# Interactive mode
claude
```

### Advanced Usage

```bash
# Use specific model
ANTHROPIC_MODEL=anthropic.claude-opus-4-20250514-v1:0 claude "Complex task here"

# Extended thinking mode
claude "Solve this complex algorithm problem" --thinking

# Different AWS profile
AWS_PROFILE=prod-bedrock claude "Check production logs"

# Specify working directory
claude --cwd /path/to/project "Analyze this codebase"
```

## Troubleshooting

### "Command not found: claude"

**Cause**: `~/.local/bin` not in PATH

**Solution**: Check that `~/.local/bin` is in PATH (should be set by dotfiles zshrc):
```bash
echo $PATH | grep -q ".local/bin" && echo "✓ In PATH" || echo "✗ Not in PATH"

# If not in PATH, reload shell config
source ~/.zshrc

# Or manually add to current session
export PATH="$HOME/.local/bin:$PATH"
```

### "Unable to locate credentials"

**Cause**: AWS credentials not configured or expired

**Solution**:
```bash
# Check AWS profile exists
aws configure list-profiles | grep bedrock

# Re-login to SSO
aws sso login --profile bedrock

# Or configure access keys
aws configure --profile bedrock
```

### SSL Certificate errors

**Symptoms**: `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `SELF_SIGNED_CERT_IN_CHAIN`

**Solution**:
1. Verify certificate is installed: `ls -la ~/.continue/certs/`
2. Check `NODE_EXTRA_CA_CERTS` path in `settings.json`
3. Verify certificate is valid: `openssl x509 -in ~/.continue/certs/*.crt -text -noout`

### "Access denied" or "ThrottlingException"

**Cause**: Bedrock access not enabled or rate limits hit

**Solution**:
1. Enable Bedrock model access in AWS Console → Bedrock → Model access
2. Wait 1-2 minutes after enabling
3. Check IAM permissions include `bedrock:InvokeModel`
4. For rate limits, wait a moment and retry

### Environment variables not loading

**Cause**: Settings file not in correct location or malformed JSON

**Solution**:
```bash
# Check file exists
ls -la ~/.claude/settings.json

# Validate JSON
python3 -m json.tool ~/.claude/settings.json

# Check for syntax errors
cat ~/.claude/settings.json
```

### Different model needed

Update `ANTHROPIC_MODEL` in `settings.json`:

```json
{
  "env": {
    "ANTHROPIC_MODEL": "anthropic.claude-3-5-sonnet-20241022-v2:0"
  }
}
```

Available models (check with AWS CLI):
```bash
aws bedrock list-foundation-models \
  --region us-gov-west-1 \
  --profile bedrock \
  --query 'modelSummaries[?contains(modelId, `claude`)].{ID:modelId,Name:modelName}'
```

## Security Notes

- **NEVER** commit AWS credentials to this config file
- Use AWS profiles that reference `~/.aws/credentials` or SSO
- `settings.json` is safe to commit (contains no secrets, only env var configs)
- Certificate files (public certs) are safe to commit if needed
- Rotate AWS credentials regularly per your organization's policy

## Configuration for Multiple Environments

If you work with multiple AWS accounts/regions:

**Option 1: Multiple settings files**
```bash
# Development
cp ~/.claude/settings.json ~/.claude/settings.dev.json

# Production
cp ~/.claude/settings.json ~/.claude/settings.prod.json

# Use with symlink
ln -sf ~/.claude/settings.dev.json ~/.claude/settings.json
```

**Option 2: Shell aliases**
```bash
# Add to ~/.zshrc.local
alias claude-dev='AWS_PROFILE=dev-bedrock AWS_REGION=us-east-1 claude'
alias claude-prod='AWS_PROFILE=prod-bedrock AWS_REGION=us-west-2 claude'
alias claude-gov='AWS_PROFILE=gov-bedrock AWS_REGION=us-gov-west-1 claude'
```

## See Also

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [Continue IDE Setup](../continue/README.md) - Similar configuration for VS Code
