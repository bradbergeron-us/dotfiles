# Maven Configuration Template

This template provides a starting point for Maven configuration on work machines with corporate Nexus/Artifactory repositories.

## Installation

```bash
mkdir -p ~/.m2
cp ~/dotfiles/templates/m2/settings.xml.template ~/.m2/settings.xml
```

Then edit `~/.m2/settings.xml` to replace placeholder URLs with your organization's actual repository URLs.

## Configuration Steps

### 1. Update Repository URLs

Replace these placeholder URLs with your actual organization URLs:
- `https://nexus.example.com/repository/maven-public/`

### 2. Configure Credentials

Maven credentials should **never** be stored in plain text. Use one of these methods:

#### Option A: Maven Password Encryption (Recommended)

```bash
# Step 1: Create a master password
mvn --encrypt-master-password your-master-password

# Step 2: Store it in ~/.m2/settings-security.xml
cat > ~/.m2/settings-security.xml << 'EOF'
<settingsSecurity>
  <master>{YOUR-ENCRYPTED-MASTER-PASSWORD-HERE}</master>
</settingsSecurity>
EOF

# Step 3: Encrypt your server password
mvn --encrypt-password your-server-password

# Step 4: Add encrypted password to ~/.m2/settings.xml under <servers>
```

#### Option B: Environment Variables

```bash
# Add to ~/.zshrc.local
export MAVEN_USERNAME="your-username"
export MAVEN_PASSWORD="your-password"
```

Then reference in settings.xml:
```xml
<server>
  <id>nexus</id>
  <username>${env.MAVEN_USERNAME}</username>
  <password>${env.MAVEN_PASSWORD}</password>
</server>
```

#### Option C: Credential Helper (if available)

Some organizations provide credential helpers that integrate with your SSO or credential manager.

### 3. Verify Setup

```bash
# Test Maven can access your repository
mvn help:effective-settings

# Try a simple dependency download
mvn dependency:get -Dartifact=org.apache.commons:commons-lang3:3.12.0
```

## Troubleshooting

### "Unable to find valid certification path"

Your organization likely uses a custom SSL certificate. See [../continue/README.md](../continue/README.md) for certificate installation instructions.

### "Unauthorized" or "403 Forbidden"

Check your credentials are configured correctly. Verify with your organization's documentation.

### Repository returns 404 for valid artifacts

Verify your mirror and repository URLs are correct. Some organizations have separate repositories for releases vs snapshots.

## Security Notes

- **NEVER** commit `~/.m2/settings.xml` with real credentials
- Use encrypted passwords or credential helpers
- The `settings-security.xml` file should also not be committed
- Rotate your credentials regularly per your organization's policy

## See Also

- [Maven Password Encryption Guide](https://maven.apache.org/guides/mini/guide-encryption.html)
- [Maven Settings Reference](https://maven.apache.org/settings.html)
