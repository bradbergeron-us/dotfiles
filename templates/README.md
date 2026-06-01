# Configuration Templates

This directory contains templates for work-specific configurations that can't be directly included in dotfiles due to environment-specific settings or security considerations.

## Overview

Templates provide a starting point for configuring:
- Maven (Java build tool) with corporate Nexus/Artifactory
- Yarn (Node.js package manager) with corporate npm registries
- AWS CLI for Bedrock (AI model access)
- Continue IDE for VS Code with AWS Bedrock
- Claude Code CLI with AWS Bedrock

## Quick Start

### Initial Setup

```bash
# Copy all templates at once (recommended for new machines)
bash ~/dotfiles/scripts/setup_work_configs.sh

# Or copy individually as needed (see sections below)
```

### Individual Templates

#### Maven
```bash
mkdir -p ~/.m2
cp ~/dotfiles/templates/m2/settings.xml.template ~/.m2/settings.xml
# Edit ~/.m2/settings.xml with your organization's repository URLs
```

#### Yarn
```bash
cp ~/dotfiles/templates/yarnrc.template ~/.yarnrc
# Edit ~/.yarnrc with your organization's registry URL
```

#### AWS CLI
```bash
mkdir -p ~/.aws
cp ~/dotfiles/templates/aws/config.template ~/.aws/config
aws configure sso --profile bedrock
```

#### Continue IDE
```bash
mkdir -p ~/.continue
cp ~/dotfiles/templates/continue/config.yaml.template ~/.continue/config.yaml
# Edit ~/.continue/config.yaml with your AWS profile and model IDs
```

#### Claude Code CLI
```bash
mkdir -p ~/.claude
cp ~/dotfiles/templates/claude/settings.json.template ~/.claude/settings.json
# Edit ~/.claude/settings.json with your username and AWS settings
```

## Template Structure

Each template directory contains:
- `*.template` - The configuration file template with placeholders
- `README.md` - Detailed setup instructions and troubleshooting

## Security

### ✅ Safe to Commit (Templates)

- Configuration structure and formats
- Public URLs (registry URLs, API endpoints)
- Documentation and instructions
- Example values and placeholders

### ❌ NEVER Commit

- AWS credentials (access keys, session tokens)
- Maven passwords
- NPM/Yarn auth tokens
- Private keys or certificates with private components
- API keys or secrets

All templates use placeholders like:
- `REPLACE_WITH_YOUR_USERNAME`
- `your-org.example.com`
- `{encrypted-password-here}`

Replace these with actual values after copying to your home directory.

## Template Locations

| Template | Destination | Purpose |
|----------|-------------|---------|
| `m2/settings.xml.template` | `~/.m2/settings.xml` | Maven repository config |
| `yarnrc.template` | `~/.yarnrc` | Yarn registry config |
| `aws/config.template` | `~/.aws/config` | AWS CLI profiles |
| `continue/config.yaml.template` | `~/.continue/config.yaml` | Continue IDE AI config |
| `claude/settings.json.template` | `~/.claude/settings.json` | Claude Code CLI config |

## Credential Management

### AWS Credentials

**Recommended**: Use AWS SSO
```bash
aws configure sso --profile bedrock
aws sso login --profile bedrock
```

**Alternative**: Use access keys (less secure)
```bash
aws configure --profile bedrock
# Credentials stored in ~/.aws/credentials (NOT tracked by dotfiles)
```

### Maven Credentials

**Recommended**: Use Maven password encryption
```bash
mvn --encrypt-master-password <password>
# Stored in ~/.m2/settings-security.xml (NOT tracked by dotfiles)
```

**Alternative**: Use environment variables
```bash
export MAVEN_USERNAME="your-username"
export MAVEN_PASSWORD="your-password"
```

### NPM/Yarn Credentials

**Recommended**: Use npm login
```bash
npm login --registry=https://registry.your-org.com/
# Token stored in ~/.npmrc (NOT tracked by dotfiles)
```

**Alternative**: Set auth token manually
```bash
npm config set //registry.your-org.com/:_authToken "YOUR-TOKEN"
```

## Common Workflows

### New Work Machine Setup

1. Clone dotfiles and run bootstrap:
   ```bash
   git clone https://github.com/bradbergeron-us/dotfiles.git ~/dotfiles
   bash ~/dotfiles/bootstrap.sh
   ```

2. Setup work configurations:
   ```bash
   bash ~/dotfiles/scripts/setup_work_configs.sh
   ```

3. Configure AWS credentials:
   ```bash
   aws configure sso --profile bedrock
   ```

4. Install certificates (if behind corporate proxy):
   ```bash
   bash ~/dotfiles/scripts/install_zscaler_cert.sh
   ```

5. Verify setup:
   ```bash
   mvn help:effective-settings
   yarn config list
   aws sts get-caller-identity --profile bedrock
   claude "Hello world"
   ```

### Updating Templates

When your organization changes URLs or configuration:

1. Update the template:
   ```bash
   cd ~/dotfiles
   git checkout -b update-maven-template
   # Edit templates/m2/settings.xml.template
   git add templates/m2/settings.xml.template
   git commit -m "Update Maven repository URL"
   git push
   ```

2. Update your local config:
   ```bash
   # Merge changes from template to your active config
   diff ~/dotfiles/templates/m2/settings.xml.template ~/.m2/settings.xml
   # Manually apply relevant changes
   ```

### Sharing Templates with Team

Templates are designed to be shared:

1. Document your organization's specific values in team wiki
2. Share the dotfiles repo with team members
3. Provide organization-specific README addendums
4. Keep templates up-to-date as infrastructure changes

## Troubleshooting

### Template is out of date

```bash
cd ~/dotfiles
git pull origin main
# Re-copy template if needed
cp ~/dotfiles/templates/m2/settings.xml.template ~/.m2/settings.xml
```

### Can't find where to put credentials

Each template's README has a "Configuration Steps" section with detailed credential setup instructions.

### Template placeholders not obvious

Search for these patterns in templates:
- `REPLACE_WITH_*`
- `your-org.example.com`
- `{encrypted-*-here}`
- `123456789012` (example account numbers)
- Comments with `Replace with...`

### Need help with specific tool

See individual READMEs:
- [Maven Setup](m2/README.md)
- [Yarn Setup](yarnrc.README.md)
- [AWS Setup](aws/README.md)
- [Continue IDE Setup](continue/README.md)
- [Claude Code Setup](claude/README.md)

## Future Enhancements

Planned improvements:
- [ ] Automated template validation
- [ ] Interactive setup wizard
- [ ] Environment-specific template variants (dev, staging, prod)
- [ ] Integration tests for templates
- [ ] Pre-commit hooks to prevent committing secrets

## Contributing

When adding new templates:

1. Use `.template` extension
2. Replace all sensitive values with placeholders
3. Add comprehensive README.md
4. Document credential management
5. Include troubleshooting section
6. Test on fresh machine
7. Add to this index

## See Also

- [Dotfiles README](../README.md) - Main dotfiles documentation
- [Work Machine Setup](../docs/work-machine.md) - Complete work setup guide
- [Certificates](../certs/README.md) - SSL certificate management
- [Installers](../installers/README.md) - Binary installer storage
