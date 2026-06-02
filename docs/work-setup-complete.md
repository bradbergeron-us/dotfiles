# Complete Work Machine Setup Guide

**Last Updated**: June 1, 2026
**Target**: Work laptops with corporate proxy, internal registries, and AWS Bedrock access

This guide walks you through setting up a fresh work laptop from a clean macOS installation to a fully configured development environment in under 30 minutes.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Phase 1: Bootstrap](#phase-1-bootstrap)
4. [Phase 2: Work Configurations](#phase-2-work-configurations)
5. [Phase 3: Certificates](#phase-3-certificates)
6. [Phase 4: Claude Code CLI](#phase-4-claude-code-cli)
7. [Phase 5: AWS Configuration](#phase-5-aws-configuration)
8. [Phase 6: VS Code Extensions](#phase-6-vs-code-extensions)
9. [Verification](#verification)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

### Required Access

- [ ] GitHub account with access to your dotfiles repository
- [ ] Corporate network access (VPN if remote)
- [ ] JFrog/Nexus registry credentials
- [ ] AWS Bedrock access (IAM user or SSO)

### Required Files

Obtain these from your IT department or download location:

- [ ] **Zscaler Root Certificate** (`ZscalerRootCertificate-2048-SHA256.crt`)
- [ ] **Claude Code installer** (if not using public download)
- [ ] **VS Code extensions** (.vsix files):
  - Continue (`continue-*.vsix`)
  - AFS Code Cred (`afs-code-cred-*.vsix`) - if applicable
  - Any other work-specific extensions

### System Requirements

- macOS 12.0 (Monterey) or later
- Admin/sudo access on the machine
- Active internet connection

---

## Quick Start

**TL;DR for experienced users:**

```bash
# 1. Clone and bootstrap
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh

# 2. Setup work configurations
bash scripts/setup_work_configs.sh

# 3. Install certificates
bash scripts/install_zscaler_cert.sh

# 4. Configure AWS
aws configure sso --profile bedrock

# 5. Verify
bash verify.sh
```

For detailed steps, continue reading below.

---

## Phase 1: Bootstrap

### Step 1.1: Clone Dotfiles Repository

```bash
# Clone your dotfiles (replace with your actual repo URL)
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Step 1.2: Run Bootstrap Script

This installs Homebrew, packages, and sets up your base configuration:

```bash
bash bootstrap.sh
```

**What it does:**
1. ✅ Installs Xcode Command Line Tools
2. ✅ Installs Homebrew
3. ✅ Installs packages from `Brewfile` and `Brewfile.work`
4. ✅ Configures shell (zsh with starship prompt)
5. ✅ Installs developer tools (Git, Node.js, Ruby, Java)
6. ✅ Sets up tmux with plugins
7. ✅ Creates dotfile symlinks
8. ✅ **Prompts for work-specific configurations** (new!)
9. ✅ Applies macOS defaults (optional)

**Duration:** ~10-15 minutes (depending on internet speed)

### Step 1.3: What to Expect

During bootstrap, you'll be prompted:

```
🏢  Work-specific configurations

  Setup work configs (.m2, .yarnrc, .continue, .claude, .aws)?

  Run work configuration setup? [y/N]
```

**Choose:**
- `y` - Run work config setup now (recommended for first-time setup)
- `n` - Skip for now, run manually later

If you choose `y`, you'll proceed directly to Phase 2. Otherwise, continue with manual setup below.

---

## Phase 2: Work Configurations

### Step 2.1: Run Work Configuration Setup

If you skipped this during bootstrap:

```bash
bash ~/dotfiles/scripts/setup_work_configs.sh
```

### Step 2.2: Interactive Prompts

You'll be asked about each configuration. Answer `y` or `n` for each:

#### Maven Configuration
```
Setup Maven (.m2/settings.xml)? [Y/n]
```

Creates `~/.m2/settings.xml` from template with:
- Nexus mirror configuration
- Repository profiles
- Plugin groups

**After installation:** Edit `~/.m2/settings.xml` and add server credentials if needed.

#### Yarn Configuration
```
Setup Yarn (.yarnrc)? [Y/n]
```

Creates `~/.yarnrc` with:
- JFrog registry URL
- Authentication settings
- SSL configuration for corporate proxy

#### Continue IDE Configuration
```
Setup Continue IDE (.continue/config.yaml)? [Y/n]
```

Creates `~/.continue/config.yaml` with:
- AWS Bedrock model configuration
- Claude 4.5 and 3.7 Sonnet models
- AWS profile settings

#### Claude Code Configuration
```
Setup Claude Code (.claude/settings.json)? [Y/n]
```

Creates `~/.claude/settings.json` with:
- AWS Bedrock environment variables
- Model configuration
- Certificate path

#### AWS Configuration
```
Setup AWS config (.aws/config)? [Y/n]
```

Creates `~/.aws/config` with:
- Profile configuration
- Region settings
- Output format

**Note:** This only creates the config file. Credentials are configured separately (see Phase 5).

#### Claude Code CLI
```
Install Claude Code CLI? [Y/n]
```

Searches for the Claude Code installer and installs to `~/.local/bin/claude`.

### Step 2.3: Backup Protection

The script automatically backs up existing configurations before overwriting:
- `settings.xml` → `settings.xml.backup`
- `.yarnrc` → `.yarnrc.backup`
- `config.yaml` → `config.yaml.backup`
- etc.

---

## Phase 3: Certificates

### Step 3.1: Obtain Zscaler Certificate

If you don't have the certificate yet:

1. Download from your IT portal, or
2. Extract from Claude Code installer package, or
3. Request from IT department

**File name:** `ZscalerRootCertificate-2048-SHA256.crt`

### Step 3.2: Install Certificate

```bash
bash ~/dotfiles/scripts/install_zscaler_cert.sh
```

**What it does:**
1. Searches for certificate in common locations
2. Installs to `~/.continue/certs/`
3. Optionally installs to macOS System Keychain (requires sudo)
4. Adds `NODE_EXTRA_CA_CERTS` to `~/.zshrc.local`
5. Copies certificate to `~/dotfiles/certs/` for future use

### Step 3.3: Certificate Locations

After installation, the certificate will be in:
- `~/.continue/certs/ZscalerRootCertificate-2048-SHA256.crt` - For Continue IDE
- `~/dotfiles/certs/ZscalerRootCertificate-2048-SHA256.crt` - Backup copy (git-ignored)
- `/Library/Keychains/System.keychain` - System-wide (if you chose to install)

### Step 3.4: Verify Installation

```bash
# Check certificate is in place
ls -la ~/.continue/certs/

# Verify NODE_EXTRA_CA_CERTS is set
grep NODE_EXTRA_CA_CERTS ~/.zshrc.local

# Restart shell to apply changes
exec zsh
```

---

## Phase 4: Claude Code CLI

### Option A: Automatic Installation (During Phase 2)

If you answered `y` to "Install Claude Code CLI?" during Phase 2, it's already installed.

### Option B: Manual Installation

```bash
bash ~/dotfiles/scripts/install_claude_code.sh
```

**The script will:**
1. Check if Claude Code is already installed
2. Search for installer in:
   - `~/dotfiles/installers/claude-code-installer`
   - `~/Downloads/ClaudeCode-macOS-*/claude-code-installer`
   - `~/Downloads/claude-code-installer`
3. Install to `~/.local/bin/claude`
4. Verify installation

### Option C: Manual Download and Install

If the script can't find the installer:

1. Download Claude Code from: https://claude.com/download
2. Place installer in `~/dotfiles/installers/` or `~/Downloads/`
3. Re-run: `bash ~/dotfiles/scripts/install_claude_code.sh`

### Verify Claude Code Installation

```bash
# Check version
claude --version

# Test connection (should connect to AWS Bedrock)
claude
```

---

## Phase 5: AWS Configuration

### Step 5.1: Configure AWS SSO (Recommended)

```bash
aws configure sso --profile bedrock
```

**Prompts:**
- SSO start URL: `https://your-org.awsapps.com/start` (get from IT)
- SSO region: `us-gov-west-1` (or your region)
- CLI default client region: `us-gov-west-1`
- CLI default output format: `json`
- CLI profile name: `bedrock`

### Step 5.2: Alternative - Access Keys (Less Secure)

If SSO is not available:

```bash
aws configure --profile bedrock
```

**You'll need:**
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-gov-west-1`
- Default output format: `json`

**Important:** Never commit credentials to git!

### Step 5.3: Test AWS Connection

```bash
# Set profile
export AWS_PROFILE=bedrock

# Test connection
aws sts get-caller-identity

# Test Bedrock access
aws bedrock list-foundation-models --region us-gov-west-1
```

### Step 5.4: Persist AWS Profile

Add to `~/.zshrc.local`:

```bash
# AWS Configuration
export AWS_PROFILE=bedrock
export AWS_REGION=us-gov-west-1
```

---

## Phase 6: VS Code Extensions

### Step 6.1: Obtain Extension Files

Get these .vsix files from:
- Internal file share
- IT portal
- Email from team
- Claude Code download package

**Required extensions:**
- `continue-*.vsix` - AI code assistant
- `afs-code-cred-*.vsix` - Credential management (if applicable)

### Step 6.2: Place Extensions

```bash
# Create directory
mkdir -p ~/dotfiles/vscode/extensions

# Copy .vsix files there
cp /path/to/continue-1.5.29.vsix ~/dotfiles/vscode/extensions/
cp /path/to/afs-code-cred-3.0.0.vsix ~/dotfiles/vscode/extensions/
```

### Step 6.3: Install Extensions

```bash
bash ~/dotfiles/scripts/install_vscode_work_extensions.sh
```

### Step 6.4: Verify Installation

```bash
# List installed extensions
code --list-extensions

# Should include:
# - Continue
# - afs-code-cred (if applicable)
```

---

## Verification

### Full System Check

Run the verification script:

```bash
bash ~/dotfiles/verify.sh
```

### Manual Verification Checklist

#### Shell & Tools
- [ ] `echo $SHELL` → `/bin/zsh`
- [ ] `starship --version` → Shows version
- [ ] `tmux -V` → Shows version

#### Development Tools
- [ ] `git --version` → Shows version
- [ ] `node --version` → Shows version
- [ ] `ruby --version` → Shows version
- [ ] `java -version` → Shows version
- [ ] `mvn --version` → Shows version

#### Work Configurations
- [ ] `ls ~/.m2/settings.xml` → Exists
- [ ] `ls ~/.yarnrc` → Exists
- [ ] `ls ~/.continue/config.yaml` → Exists
- [ ] `ls ~/.claude/settings.json` → Exists
- [ ] `ls ~/.aws/config` → Exists

#### Certificates
- [ ] `ls ~/.continue/certs/*.crt` → Exists
- [ ] `echo $NODE_EXTRA_CA_CERTS` → Shows path

#### Claude Code
- [ ] `which claude` → `~/.local/bin/claude`
- [ ] `claude --version` → Shows version
- [ ] `claude` → Launches successfully

#### AWS
- [ ] `aws --version` → Shows version
- [ ] `echo $AWS_PROFILE` → `bedrock`
- [ ] `aws sts get-caller-identity` → Shows your identity

#### VS Code
- [ ] `code --version` → Shows version
- [ ] `code --list-extensions | grep continue` → Shows Continue extension

---

## Troubleshooting

### Issue: Xcode Tools Not Installed

**Symptom:** Bootstrap fails immediately

**Solution:**
```bash
xcode-select --install
# Wait for installation to complete, then re-run bootstrap
bash ~/dotfiles/bootstrap.sh
```

### Issue: Homebrew Installation Fails

**Symptom:** Can't install Homebrew due to proxy

**Solution:**
```bash
# Configure proxy first
export HTTP_PROXY=http://your-proxy:port
export HTTPS_PROXY=http://your-proxy:port

# Then install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Issue: Claude Code Can't Connect

**Symptom:** `claude` command fails with SSL errors

**Solution:**
1. Verify certificate is installed:
   ```bash
   ls ~/.continue/certs/ZscalerRootCertificate-2048-SHA256.crt
   ```

2. Check NODE_EXTRA_CA_CERTS is set:
   ```bash
   echo $NODE_EXTRA_CA_CERTS
   ```

3. Restart shell:
   ```bash
   exec zsh
   ```

4. Try Claude Code again:
   ```bash
   claude
   ```

### Issue: AWS SSO Not Working

**Symptom:** `aws configure sso` fails

**Solution:**
1. Check VPN connection
2. Verify SSO URL with IT
3. Try access keys as fallback:
   ```bash
   aws configure --profile bedrock
   ```

### Issue: Maven Can't Download Dependencies

**Symptom:** Build fails with 401 or certificate errors

**Solution:**
1. Check `~/.m2/settings.xml` has correct repository URLs
2. Verify certificate is installed
3. Test Nexus connectivity:
   ```bash
   curl -I https://nexus.np.afsp.io/repository/maven-public/
   ```

### Issue: Yarn Can't Install Packages

**Symptom:** `yarn install` fails with certificate or auth errors

**Solution:**
1. Check `~/.yarnrc` exists and has correct registry
2. Verify certificate:
   ```bash
   echo $NODE_EXTRA_CA_CERTS
   ls -la $(echo $NODE_EXTRA_CA_CERTS)
   ```
3. Test JFrog connectivity:
   ```bash
   curl -I https://jfrog.accenturefederaldev.com/artifactory/api/npm/afs-npm-proxy/
   ```

### Issue: VS Code Extensions Won't Install

**Symptom:** `code --install-extension` fails

**Solution:**
1. Verify VS Code CLI is in PATH:
   ```bash
   which code
   ```
2. If not found, install CLI:
   - Open VS Code
   - Command Palette (⌘⇧P)
   - "Shell Command: Install 'code' command in PATH"
3. Try again:
   ```bash
   bash ~/dotfiles/scripts/install_vscode_work_extensions.sh
   ```

### Issue: `claude` Command Not Found

**Symptom:** Shell can't find `claude`

**Solution:**
1. Check installation:
   ```bash
   ls -la ~/.local/bin/claude
   ```
2. Verify PATH includes `~/.local/bin`:
   ```bash
   echo $PATH | grep -o ".local/bin"
   ```
3. If missing, add to `~/.zshrc.local`:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```
4. Restart shell:
   ```bash
   exec zsh
   ```

### Issue: tmux Doesn't Start

**Symptom:** `tmux` command fails or has errors

**Solution:**
1. Check tmux is installed:
   ```bash
   which tmux
   ```
2. If not installed:
   ```bash
   brew install tmux
   ```
3. Install tmux plugins:
   ```bash
   ~/.tmux/plugins/tpm/bin/install_plugins
   ```

---

## Updating Configurations

### Update All Dotfiles

```bash
cd ~/dotfiles
bash update.sh
```

### Update Work Configurations Only

```bash
# Pull latest changes
cd ~/dotfiles
git pull

# Re-run work config setup
bash scripts/setup_work_configs.sh
```

### Update Single Configuration

```bash
# Maven
cp ~/dotfiles/templates/m2/settings.xml.template ~/.m2/settings.xml

# Yarn
cp ~/dotfiles/templates/yarnrc.template ~/.yarnrc

# Continue
cp ~/dotfiles/templates/continue/config.yaml.template ~/.continue/config.yaml

# Claude Code
cp ~/dotfiles/templates/claude/settings.json.template ~/.claude/settings.json

# AWS
cp ~/dotfiles/templates/aws/config.template ~/.aws/config
```

---

## Advanced Topics

### Running Setup Scripts Individually

All scripts support individual execution:

```bash
# Setup all work configs
bash ~/dotfiles/scripts/setup_work_configs.sh

# Install Claude Code only
bash ~/dotfiles/scripts/install_claude_code.sh

# Install certificate only
bash ~/dotfiles/scripts/install_zscaler_cert.sh

# Install VS Code extensions only
bash ~/dotfiles/scripts/install_vscode_work_extensions.sh
```

### Dry Run Mode

To see what would happen without making changes:

```bash
# Review templates before applying
ls -la ~/dotfiles/templates/

# Check what files would be created
bash ~/dotfiles/scripts/setup_work_configs.sh
# Then answer 'n' to each prompt
```

### Customizing Templates

Templates are stored in `~/dotfiles/templates/`. To customize:

1. Edit the template file (ends with `.template`)
2. Do not commit secrets!
3. Re-run setup script to apply changes

### Multiple AWS Profiles

Edit `~/.aws/config` to add more profiles:

```ini
[profile bedrock]
region = us-gov-west-1
output = json

[profile commercial]
region = us-east-1
output = json
```

Switch profiles:
```bash
export AWS_PROFILE=commercial
```

---

## Security Best Practices

### Never Commit Secrets

These directories are git-ignored for security:
- `~/dotfiles/certs/*.crt` (actual certificate files)
- `~/dotfiles/installers/*` (binaries)
- `~/dotfiles/vscode/extensions/*.vsix` (extension files)

Only templates and documentation are committed.

### Credential Management

- **AWS**: Use SSO or aws-vault, never long-term access keys
- **Maven**: Use encrypted passwords or credential helpers
- **Yarn/npm**: Auth tokens go in `~/.npmrc` (not dotfiles)
- **Git**: Use SSH keys, not HTTPS passwords

### Certificate Handling

- Zscaler certificate is not secret but is environment-specific
- Store in `~/dotfiles/certs/` for convenience (git-ignored)
- System keychain installation is optional but recommended

---

## Getting Help

### Documentation

- [Main README](../README.md) - General dotfiles information
- [Work Machine Setup](work-machine.md) - Additional work-specific topics
- [Tools Guide](tools.md) - Tool-specific configuration
- [Performance](performance.md) - Optimization tips

### Support Channels

- **Dotfiles Issues**: Open issue on GitHub repository
- **AWS/Bedrock**: Contact your cloud team
- **Certificate Issues**: Contact IT security
- **Registry Access**: Contact DevOps team

### Useful Commands

```bash
# Check system health
bash ~/dotfiles/verify.sh

# Update everything
bash ~/dotfiles/update.sh

# View installed packages
brew list

# View installed VS Code extensions
code --list-extensions

# Check environment variables
env | grep -E "(AWS|NODE|CLAUDE)"
```

---

## Timeline

**Total Setup Time:** ~20-30 minutes

| Phase | Duration | Can Skip? |
|-------|----------|-----------|
| Bootstrap | 10-15 min | No |
| Work Configs | 2-3 min | Yes* |
| Certificates | 1-2 min | No |
| Claude Code | 1-2 min | Yes* |
| AWS Config | 2-3 min | Yes* |
| VS Code Extensions | 1-2 min | Yes* |
| Verification | 2-3 min | Recommended |

\* Can be done later if needed, but required for full functionality

---

## Next Steps After Setup

1. **Test Your Setup**
   ```bash
   bash ~/dotfiles/verify.sh
   ```

2. **Clone a Work Project**
   ```bash
   git clone <your-repo> ~/code/project
   cd ~/code/project
   ```

3. **Build Something**
   ```bash
   mvn clean install  # Java project
   yarn install       # JavaScript project
   bundle install     # Ruby project
   ```

4. **Use Claude Code**
   ```bash
   cd ~/code/project
   claude
   ```

5. **Keep Everything Updated**
   ```bash
   bash ~/dotfiles/update.sh  # Weekly recommended
   ```

---

**Setup Complete! 🎉**

You now have a fully configured work development environment. All tools, configurations, and credentials are in place and ready to use.

For ongoing maintenance, run `bash ~/dotfiles/update.sh` weekly to keep packages and configurations current.
