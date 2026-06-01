# AWS CLI Configuration Template

This template provides starting configurations for AWS CLI profiles needed for Bedrock, work accounts, and GovCloud.

## Installation

```bash
mkdir -p ~/.aws
cp ~/dotfiles/templates/aws/config.template ~/.aws/config
chmod 600 ~/.aws/config
```

Then edit `~/.aws/config` to customize for your environment.

## Configuration Methods

### Option 1: AWS SSO (Recommended - Most Secure)

AWS Single Sign-On integrates with your organization's identity provider.

```bash
# Configure SSO profile
aws configure sso --profile bedrock

# Follow the prompts:
# - SSO start URL: https://your-org.awsapps.com/start (or your org's URL)
# - SSO region: us-gov-west-1 (or your region)
# - Select account and role when prompted
# - CLI default region: us-gov-west-1
# - CLI output format: json

# Login (opens browser)
aws sso login --profile bedrock

# Test access
aws sts get-caller-identity --profile bedrock
aws bedrock list-foundation-models --profile bedrock
```

#### Using SSO

```bash
# Login when token expires (every 1-8 hours depending on org settings)
aws sso login --profile bedrock

# Use in commands
aws bedrock list-foundation-models --profile bedrock

# Set as default for shell session
export AWS_PROFILE=bedrock

# Auto-refresh with aws-sso-util (optional)
brew install aws-sso-util
aws-sso-util configure populate --profile bedrock
```

### Option 2: Access Keys (Less Secure, but Simpler)

For environments where SSO is not available.

```bash
# Configure profile with access keys
aws configure --profile bedrock

# Enter when prompted:
# - AWS Access Key ID: AKIAIOSFODNN7EXAMPLE
# - AWS Secret Access Key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
# - Default region: us-gov-west-1
# - Default output format: json

# Test access
aws sts get-caller-identity --profile bedrock
```

**Security Note**: Access keys are less secure than SSO. If you must use them:
- Store in `~/.aws/credentials` (never commit this file!)
- Rotate keys every 90 days
- Use MFA when possible
- Never share or commit keys

### Option 3: Environment Variables (Temporary)

For testing or temporary access:

```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=us-gov-west-1

# Use without --profile flag
aws bedrock list-foundation-models
```

## Profile Configuration

### Bedrock Profile (for Claude Code and Continue)

Edit `~/.aws/config`:

**For SSO:**
```ini
[profile bedrock]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-gov-west-1
sso_account_id = 123456789012
sso_role_name = BedrockUserRole
region = us-gov-west-1
output = json
```

**For Access Keys:**
```ini
[profile bedrock]
region = us-gov-west-1
output = json
```

Then add to `~/.aws/credentials`:
```ini
[bedrock]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

### GovCloud vs Commercial

**Commercial AWS:**
- Regions: `us-east-1`, `us-west-2`, etc.
- SSO URL: Usually `https://yourorg.awsapps.com/start`
- Model example: `anthropic.claude-3-5-sonnet-20241022-v2:0`

**GovCloud:**
- Regions: `us-gov-west-1`, `us-gov-east-1`
- SSO URL: Varies by agency
- Model example: `us-gov.anthropic.claude-sonnet-4-5-20250929-v1:0`

### Multiple Profiles

```ini
# Development
[profile dev-bedrock]
sso_start_url = https://dev.awsapps.com/start
sso_region = us-east-1
sso_account_id = 111111111111
sso_role_name = Developer
region = us-east-1

# Production
[profile prod-bedrock]
sso_start_url = https://prod.awsapps.com/start
sso_region = us-west-2
sso_account_id = 222222222222
sso_role_name = BedrockUser
region = us-west-2

# GovCloud
[profile gov-bedrock]
sso_start_url = https://gov.awsapps.com/start
sso_region = us-gov-west-1
sso_account_id = 333333333333
sso_role_name = GovCloudUser
region = us-gov-west-1
```

## Enable Bedrock Model Access

Before using Bedrock models, you must enable access:

1. **Login to AWS Console**
   ```bash
   # For SSO profiles
   aws sso login --profile bedrock
   ```

2. **Navigate to Bedrock**
   - Go to: https://console.aws.amazon.com/bedrock/
   - Or: AWS Console → Services → Bedrock

3. **Request Model Access**
   - Left sidebar → "Model access"
   - Click "Manage model access"
   - Select checkboxes for:
     - ✓ Anthropic Claude 3.5 Sonnet
     - ✓ Anthropic Claude 3.7 Sonnet
     - ✓ Anthropic Claude Opus (if available)
   - Click "Request model access"
   - Wait 1-2 minutes for approval (usually instant)

4. **Verify Access**
   ```bash
   aws bedrock list-foundation-models --region us-gov-west-1 --profile bedrock
   ```

## Testing Your Configuration

### Test AWS CLI Access

```bash
# Test authentication
aws sts get-caller-identity --profile bedrock

# Should return:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/yourname"
# }
```

### Test Bedrock Access

```bash
# List available models
aws bedrock list-foundation-models \
  --region us-gov-west-1 \
  --profile bedrock \
  --query 'modelSummaries[?contains(modelId, `claude`)].[modelId,modelName]' \
  --output table

# Invoke a model (test actual inference)
aws bedrock-runtime invoke-model \
  --model-id anthropic.claude-3-5-sonnet-20241022-v2:0 \
  --region us-east-1 \
  --profile bedrock \
  --body '{"anthropic_version":"bedrock-2023-05-31","messages":[{"role":"user","content":"Hello"}],"max_tokens":100}' \
  /dev/stdout
```

### Test with Claude Code

```bash
# Set profile
export AWS_PROFILE=bedrock

# Test Claude Code
claude "What is 2+2?"
```

## Required IAM Permissions

Your IAM user or role needs these permissions for Bedrock:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:ListFoundationModels",
        "bedrock:GetFoundationModel",
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    }
  ]
}
```

Contact your AWS administrator if you lack these permissions.

## Troubleshooting

### SSO token expired

**Error**: `The SSO session associated with this profile has expired`

**Solution**:
```bash
aws sso login --profile bedrock
```

SSO tokens typically expire every 1-8 hours depending on your organization's settings.

### Profile not found

**Error**: `The config profile (bedrock) could not be found`

**Solution**: Check your profile name:
```bash
aws configure list-profiles
cat ~/.aws/config
```

### Access denied to Bedrock

**Error**: `AccessDeniedException` or `UnauthorizedException`

**Solutions**:
1. Enable model access in Bedrock console (see "Enable Bedrock Model Access" above)
2. Check IAM permissions include `bedrock:InvokeModel`
3. Verify you're using the correct region
4. Wait 1-2 minutes after enabling model access

### Wrong region

**Error**: Model not found or not available

**Solution**: Bedrock is not available in all regions. Use:
- Commercial: `us-east-1`, `us-west-2`, `eu-west-1`
- GovCloud: `us-gov-west-1`, `us-gov-east-1`

Check available regions:
```bash
aws ec2 describe-regions --query 'Regions[].RegionName' --output table
```

### Credentials file permissions

**Error**: `Unable to locate credentials`

**Solution**: Ensure proper permissions:
```bash
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
ls -la ~/.aws/
```

Files should be readable only by you (`-rw-------`).

## Security Best Practices

### ✅ DO:
- Use AWS SSO when available
- Use MFA (multi-factor authentication)
- Rotate access keys every 90 days
- Use separate profiles for dev/prod
- Set `chmod 600` on AWS config files
- Use principle of least privilege (minimal IAM permissions)
- Keep AWS CLI updated: `brew upgrade awscli`

### ❌ DON'T:
- Commit `~/.aws/credentials` to git
- Share AWS access keys
- Use root account access keys
- Store keys in environment variables permanently
- Disable MFA for convenience
- Use wildcard permissions (`"Resource": "*"`) unless necessary

## Shell Aliases for Multiple Profiles

Add to `~/.zshrc.local`:

```bash
# AWS profile switchers
alias aws-bedrock='export AWS_PROFILE=bedrock'
alias aws-dev='export AWS_PROFILE=dev'
alias aws-prod='export AWS_PROFILE=prod'
alias aws-gov='export AWS_PROFILE=govcloud'
alias aws-default='unset AWS_PROFILE'

# Check current profile
alias aws-whoami='aws sts get-caller-identity'

# SSO login helpers
alias aws-login-bedrock='aws sso login --profile bedrock'
alias aws-login-dev='aws sso login --profile dev'
alias aws-login-prod='aws sso login --profile prod'
```

Usage:
```bash
# Switch to bedrock profile
aws-bedrock

# Check current identity
aws-whoami

# Use Claude with current profile
claude "Hello world"
```

## See Also

- [AWS CLI Configuration Docs](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS SSO Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
