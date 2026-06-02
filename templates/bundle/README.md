# Bundle Configuration for Ruby Gems

Configuration for Ruby's Bundle/RubyGems to authenticate with JFrog Artifactory.

## Purpose

This configuration allows Ruby projects to install private gems hosted on JFrog Artifactory. Without it, `bundle install` will fail for projects that depend on internal gems.

## Installation

### Automated (Recommended)

Run the work configuration setup script:
```bash
bash ~/dotfiles/scripts/setup_work_configs.sh
```

Select "Yes" when prompted for Bundle configuration.

### Manual Installation

```bash
# 1. Create directory
mkdir -p ~/.bundle

# 2. Copy template
cp ~/dotfiles/templates/bundle/config.template ~/.bundle/config

# 3. Edit with your credentials
# Use your preferred editor to replace placeholders
```

## Getting Your JFrog Token

1. **Log in to JFrog**: https://jfrog.accenturefederaldev.com
2. **Navigate to Profile**: Click your avatar → Edit Profile
3. **Generate API Key**: Click "Generate API Key"
4. **Copy the token**: Save it securely

## Configuration Format

```yaml
---
BUNDLE_JFROG__ACCENTUREFEDERALDEV__COM: "your.email%40domain.com:TOKEN"
```

**Important Notes**:
- Replace `@` with `%40` in your email (URL encoding)
- Token format: Base64-encoded string from JFrog
- Do NOT commit actual credentials to git

## Testing

Verify your configuration works:

```bash
# Test with a Ruby project that uses JFrog gems
cd ~/your-ruby-project
bundle install
```

If successful, you'll see gems downloading from JFrog.

## Troubleshooting

### Bundle Install Fails with 401 Unauthorized

**Cause**: Invalid or expired JFrog token

**Solution**:
1. Regenerate API token in JFrog
2. Update `~/.bundle/config`
3. Try `bundle install` again

### Cannot Find Private Gems

**Cause**: Gemfile not configured to use JFrog

**Solution**: Ensure your `Gemfile` has:
```ruby
source 'https://jfrog.accenturefederaldev.com/artifactory/api/gems/afs-gems-proxy/'
```

### SSL Certificate Errors

**Cause**: Missing Zscaler certificate

**Solution**:
```bash
bash ~/dotfiles/scripts/install_zscaler_cert.sh
```

## Security

- ✅ Template is safe to commit (no secrets)
- ❌ NEVER commit `~/.bundle/config` with actual tokens
- ✅ Tokens should be regenerated periodically
- ✅ Use JFrog's built-in token expiration

## Related Configuration

All three package managers use the same JFrog Artifactory:

- **Maven** (Java) - [templates/m2/settings.xml.template](../m2/README.md)
- **Yarn** (npm) - [templates/yarnrc.template](../yarnrc.README.md)
- **Bundle** (Ruby) - This configuration

## Environment Variables

Bundle also supports authentication via environment variables:

```bash
# Add to ~/.zshrc.local if preferred
export BUNDLE_JFROG__ACCENTUREFEDERALDEV__COM="your.email%40domain.com:TOKEN"
```

However, the config file method is recommended for consistency with other tools.

---

*Last updated: June 1, 2026*
