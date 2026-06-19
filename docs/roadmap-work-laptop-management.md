# Work Laptop Management Roadmap

Strategic roadmap for enhancing the dotfiles repository from a work laptop fleet management perspective.

**Last Updated:** June 16, 2026
**Current Version:** v1.3.0

---

## Executive Summary

This roadmap focuses on scaling dotfiles from individual machine management to fleet-wide work laptop administration. Goals include:

- **Compliance & Security**: Audit trails, policy enforcement, security scanning
- **Fleet Management**: Multi-machine visibility, remote management, bulk operations
- **Team Enablement**: Onboarding automation, shared configurations, knowledge transfer
- **Operational Excellence**: Health monitoring, disaster recovery, troubleshooting

---

## Current State Assessment

### ✅ Strong Foundation (Already Implemented)

1. **Profile System** - Work/personal/minimal/server profiles with different package sets
2. **Work-Specific Configs** - Templates for Maven, Yarn, Continue, Claude, AWS
3. **Secrets Management** - sops + age encryption for sensitive data
4. **Safe Updates** - `--no-upgrade` flag for version-locked work machines
5. **Cleanup Automation** - Script to remove dotfile cruft
6. **Comprehensive Testing** - Bats test suite with CI/CD
7. **Documentation Site** - MkDocs Material site with guides

### 🔄 Gaps for Work Fleet Management

1. **No fleet-wide visibility** - Can't see status across multiple machines
2. **Manual onboarding** - New employee setup is not fully automated
3. **Limited compliance features** - No audit logs or policy enforcement
4. **No disaster recovery** - Machine loss requires manual rebuild
5. **Minimal health monitoring** - Verify script runs locally only
6. **No team configuration sharing** - Each person maintains their own dotfiles

---

## Roadmap: Prioritized Initiatives

### Phase 1: Fleet Visibility & Health Monitoring (Q3 2026)

**Goal:** Gain centralized visibility into work laptop health and configuration state.

#### 1.1 Remote Health Reporting

**Feature:** `scripts/report.sh` - Send machine health to central monitoring

**Why:** IT/managers need visibility into laptop configuration compliance without manually SSHing to each machine.

**Implementation:**
```bash
# Send health report to central endpoint
scripts/report.sh --endpoint https://dotfiles-monitor.company.com/api/report

# Report includes:
# - Machine hostname, profile, OS version
# - Last successful update timestamp
# - verify.sh results (broken symlinks, missing tools, etc.)
# - Installed package versions (brew list --versions)
# - Git repo status (clean/dirty, branch, last commit)
```

**Deliverables:**
- `scripts/report.sh` - Health report generator
- JSON schema for report format
- Optional webhook/API endpoint receiver (separate repo)
- Privacy controls (opt-out of sensitive data)

**Acceptance Criteria:**
- Reports sent securely (HTTPS + auth token)
- Can run on schedule (cron/launchd)
- Generates report even if network unavailable (queues for retry)
- Respects privacy (no secrets, no command history)

---

#### 1.2 Fleet Dashboard

**Feature:** Web dashboard showing all managed machines

**Why:** Visualize fleet health at a glance, identify outliers, track update adoption.

**Implementation:**
- Simple web app (Next.js or similar)
- Displays: machine list, health status, last-seen timestamp
- Filters: by profile, by health status, by OS version
- Alerts: machines not reporting in >7 days, verify failures

**Deliverables:**
- Dashboard web app (separate repo)
- Authentication (SSO integration)
- Role-based access (admins vs. read-only)

---

### Phase 2: Onboarding & Offboarding Automation (Q4 2026)

**Goal:** Reduce new hire setup time from hours to minutes, automate offboarding.

#### 2.1 Automated Onboarding Script

**Feature:** `scripts/onboard-employee.sh` - Complete new hire setup

**Why:** Consistent, repeatable onboarding reduces IT burden and ensures compliance from day one.

**Implementation:**
```bash
# Run on a fresh machine after OS install
bash ~/dotfiles/scripts/onboard-employee.sh \
  --employee "Jane Doe" \
  --email "jane.doe@company.com" \
  --team "Engineering" \
  --github-username "jdoe-company"

# Performs:
# 1. Sets machine profile to 'work'
# 2. Installs all work-specific packages
# 3. Configures git with work email + signing key
# 4. Sets up work-specific configs (Maven, Yarn, etc.)
# 5. Adds employee to company GitHub org
# 6. Installs company SSL certificates
# 7. Configures VPN/proxy settings
# 8. Enrolls machine in fleet monitoring
# 9. Generates onboarding report (what was installed, config applied)
```

**Deliverables:**
- `scripts/onboard-employee.sh`
- Onboarding questionnaire (team, role, projects)
- Integration with HR systems (optional)
- Onboarding checklist generator

---

#### 2.2 Offboarding Script

**Feature:** `scripts/offboard-employee.sh` - Remove work access when employee leaves

**Why:** Security requirement to revoke access quickly and audit what was on the machine.

**Implementation:**
```bash
# Run when employee leaves
bash ~/dotfiles/scripts/offboard-employee.sh \
  --backup-dir ~/offboarding-backup-$(date +%Y%m%d)

# Performs:
# 1. Creates encrypted backup of work files
# 2. Removes work-specific configs
# 3. Uninstalls work-only packages (optional)
# 4. Clears company secrets (AWS creds, SSH keys, etc.)
# 5. Generates offboarding report (what was removed)
# 6. De-registers machine from fleet monitoring
```

**Deliverables:**
- `scripts/offboard-employee.sh`
- Secure backup mechanism
- Offboarding audit report

---

### Phase 3: Compliance & Security (Q1 2027)

**Goal:** Ensure all work laptops meet security policies and are audit-ready.

#### 3.1 Policy Enforcement

**Feature:** `scripts/check-compliance.sh` - Verify machine meets security policies

**Why:** Compliance requirements (SOC2, ISO27001, etc.) require provable security controls.

**Implementation:**
```bash
# Check machine against company policy
scripts/check-compliance.sh --policy ~/.config/dotfiles/company-policy.yml

# Checks:
# - Full disk encryption enabled (FileVault on macOS)
# - Firewall enabled
# - Auto-update enabled
# - Screen lock timeout ≤ 10 minutes
# - Required security tools installed (1Password, Zscaler, etc.)
# - Prohibited software not present
# - OS version meets minimum (no unsupported versions)
# - SSH keys use strong algorithms (ed25519, not RSA 1024)
```

**Policy file format:**
```yaml
# ~/.config/dotfiles/company-policy.yml
name: "Accenture Federal Services Security Policy"
version: "2026.1"

required_encryption:
  full_disk: true

required_firewall:
  enabled: true

screen_lock:
  timeout_minutes: 10
  require_password: true

required_tools:
  - 1password-cli
  - zscaler

prohibited_tools:
  - teamviewer
  - anydesk

os_version:
  macos_minimum: "14.0"  # Sonoma or newer

ssh_keys:
  allowed_algorithms: [ed25519, ecdsa]
  minimum_bits: 256
```

**Deliverables:**
- `scripts/check-compliance.sh`
- Policy schema (YAML)
- Example company policies
- CI integration (fail builds if non-compliant)
- Remediation suggestions (auto-fix where possible)

---

#### 3.2 Audit Logging

**Feature:** Record all dotfiles operations for audit trail

**Why:** Compliance audits require proof of who changed what and when.

**Implementation:**
```bash
# All dotfiles operations log to ~/.config/dotfiles/audit.log
# Format: timestamp | user | machine | operation | status | details

2026-06-16T15:30:00Z | bbbergeron | AFSMW740493660 | bootstrap | success | profile=work packages=127
2026-06-16T15:45:00Z | bbbergeron | AFSMW740493660 | update | success | pulled_changes=3 upgraded_packages=5
2026-06-16T16:00:00Z | bbbergeron | AFSMW740493660 | secrets:encrypt | success | file=.env.production
```

**Deliverables:**
- Audit logging library (source from all scripts)
- Structured log format (JSON or structured text)
- Log rotation and retention policy
- Central log aggregation (optional)

---

#### 3.3 Security Scanning

**Feature:** Scan for exposed secrets, vulnerable packages, misconfigurations

**Why:** Proactive security prevents breaches.

**Implementation:**
```bash
# Run security scan
scripts/security-scan.sh

# Checks:
# - gitleaks: scan for secrets in git history
# - trufflehog: deep secret scanning
# - brew audit: vulnerable packages
# - File permissions: world-writable files in ~
# - SSH config: weak ciphers, PermitRootLogin
# - Known CVEs in installed tools
```

**Deliverables:**
- `scripts/security-scan.sh`
- Integration with security tools (gitleaks, trufflehog, osv-scanner)
- Remediation workflow
- Scheduled scanning (weekly)

---

### Phase 4: Team Configuration Management (Q2 2027)

**Goal:** Enable teams to share configuration without everyone maintaining separate forks.

#### 4.1 Team Configuration Overlays

**Feature:** Layer team-specific configs on top of personal dotfiles

**Why:** Teams (e.g., Platform Team, Data Team) have shared tools and configs that shouldn't burden everyone.

**Implementation:**
```bash
# Enable team config overlay
scripts/team-config.sh enable --team platform-team

# Downloads and applies:
# - ~/.config/dotfiles/team-configs/platform-team/Brewfile.team
# - ~/.config/dotfiles/team-configs/platform-team/zshrc.team
# - ~/.config/dotfiles/team-configs/platform-team/aliases.team

# Source in .zshrc:
[[ -f ~/.config/dotfiles/team-configs/*/zshrc.team ]] && source ~/.config/dotfiles/team-configs/*/zshrc.team
```

**Team config repo structure:**
```
team-configs/
├── platform-team/
│   ├── Brewfile.team        # kubectl, k9s, helm, terraform
│   ├── zshrc.team           # Kubernetes aliases, AWS shortcuts
│   └── README.md
├── data-team/
│   ├── Brewfile.team        # jupyter, pandas, dbt
│   ├── zshrc.team           # Python venv helpers
│   └── README.md
└── frontend-team/
    ├── Brewfile.team        # node, pnpm, playwright
    └── zshrc.team           # npm/pnpm aliases
```

**Deliverables:**
- `scripts/team-config.sh` (enable/disable/list teams)
- Team config repository template
- Documentation for creating team configs
- Automatic sync (pull team configs on update)

---

#### 4.2 Shared Aliases & Functions Library

**Feature:** Company-wide shell function library

**Why:** Reduce duplication - everyone shouldn't write their own `kubectl` aliases.

**Implementation:**
```bash
# ~/.config/dotfiles/company-functions.sh (auto-loaded)
# Shared functions all engineers can use

# Kubernetes shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'

# AWS shortcuts
function aws-assume-role() {
  local role_arn=$1
  aws sts assume-role --role-arn "$role_arn" --role-session-name "$(whoami)-$(date +%s)"
}

# Git shortcuts
function git-clean-branches() {
  git branch --merged main | grep -v "^\*\|main" | xargs -r git branch -d
}

# Jira integration
function jira-open() {
  local ticket=$1
  open "https://company.atlassian.net/browse/$ticket"
}
```

**Deliverables:**
- Shared function library
- Documentation site for all functions
- Contribution guidelines
- Testing for shared functions

---

### Phase 5: Disaster Recovery & Backup (Q3 2027)

**Goal:** Minimize downtime when machines are lost, stolen, or broken.

#### 5.1 Cloud Backup & Restore

**Feature:** Backup work configs to encrypted cloud storage

**Why:** Laptop theft/loss shouldn't mean days of reconfiguration.

**Implementation:**
```bash
# Backup work configs
scripts/backup.sh --to s3://company-dotfiles-backup/$(whoami)/

# Backs up:
# - ~/.zshrc.local
# - ~/.config/git/*.gitconfig
# - ~/.aws/
# - ~/.ssh/ (encrypted)
# - ~/.config/dotfiles/
# - List of installed packages (brew list, mise list)
# - VS Code extensions list

# Restore on new machine
scripts/restore.sh --from s3://company-dotfiles-backup/$(whoami)/
```

**Deliverables:**
- `scripts/backup.sh`
- `scripts/restore.sh`
- Encryption at rest (age/sops)
- Automated backup schedule
- Restore smoke tests

---

#### 5.2 Machine Clone

**Feature:** Clone one machine's config to another

**Why:** Useful for setting up a backup laptop with identical config.

**Implementation:**
```bash
# On source machine (work laptop)
scripts/export-config.sh > /tmp/machine-config.tar.gz.age

# Transfer to new machine and import
scripts/import-config.sh < machine-config.tar.gz.age
```

**Deliverables:**
- Export/import scripts
- Selective cloning (choose what to clone)
- Dry-run mode

---

### Phase 6: Advanced Fleet Operations (Q4 2027)

**Goal:** Enable bulk operations and remote management at scale.

#### 6.1 Remote Command Execution

**Feature:** Run scripts across multiple machines remotely

**Why:** Roll out urgent security patches or config changes without manual work.

**Implementation:**
```bash
# From admin machine
scripts/fleet-exec.sh \
  --target "team=engineering" \
  --command "bash ~/dotfiles/scripts/security-scan.sh" \
  --dry-run

# Executes command on all engineering team machines
# Uses SSH or webhook-based execution
```

**Deliverables:**
- `scripts/fleet-exec.sh`
- Target selection (by team, profile, hostname pattern)
- Dry-run mode
- Progress reporting
- Error handling and rollback

---

#### 6.2 Configuration Drift Detection

**Feature:** Identify machines with non-standard configurations

**Why:** Detect when machines deviate from approved configs (security risk).

**Implementation:**
```bash
# Compare machine against baseline
scripts/check-drift.sh --baseline team-configs/platform-team/baseline.yml

# Reports:
# - Extra packages installed
# - Missing required packages
# - Modified dotfiles (git diff)
# - Unapproved aliases/functions
```

**Deliverables:**
- Drift detection script
- Baseline configuration definition
- Automated drift reports
- Remediation workflow (reset to baseline)

---

## Implementation Priorities

### High Priority (Next 6 Months)

1. **Fleet Health Reporting** (1.1) - Visibility is the foundation
2. **Compliance Checking** (3.1) - Required for SOC2/ISO27001
3. **Onboarding Automation** (2.1) - High ROI, reduces IT burden

### Medium Priority (6-12 Months)

4. **Team Configuration Overlays** (4.1) - Enable team autonomy
5. **Audit Logging** (3.2) - Compliance requirement
6. **Cloud Backup** (5.1) - Disaster recovery insurance

### Lower Priority (12+ Months)

7. **Fleet Dashboard** (1.2) - Nice to have after reporting works
8. **Remote Command Execution** (6.1) - Only needed at scale (>50 machines)
9. **Configuration Drift** (6.2) - Useful but not urgent

---

## Success Metrics

### Key Performance Indicators (KPIs)

| Metric | Current | Target (12 months) |
|--------|---------|-------------------|
| New hire setup time | 4-8 hours | <30 minutes |
| Machines reporting health | 0% | 95% |
| Compliance violations | Unknown | 0 critical, <5 minor |
| Update adoption rate | Unknown | >90% within 1 week |
| Security incidents from misconfiguration | Unknown | 0 |
| Time to recover from laptop loss | 2-3 days | <2 hours |

### Qualitative Goals

- **Developer Satisfaction**: Onboarding is smooth, not painful
- **IT Productivity**: Less time firefighting, more time building
- **Security Posture**: Proactive detection, not reactive response
- **Audit Readiness**: Can produce compliance reports on-demand

---

## Resource Requirements

### Engineering Time

- **Phase 1**: 40-60 hours (1-2 sprints)
- **Phase 2**: 60-80 hours (2-3 sprints)
- **Phase 3**: 80-100 hours (3-4 sprints)
- **Phase 4**: 40-60 hours (2-3 sprints)
- **Phase 5**: 60-80 hours (2-3 sprints)
- **Phase 6**: 80-120 hours (3-5 sprints)

**Total: ~360-500 hours over 12-18 months**

### Infrastructure

- **Fleet Dashboard**: Hosting (Vercel/Netlify free tier or company AWS)
- **Health Reporting**: API endpoint (Lambda + DynamoDB or similar)
- **Cloud Backup**: S3 bucket with encryption (~$5-20/month)
- **Monitoring**: Free tier of Datadog/New Relic or self-hosted

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| **Privacy concerns** (employees don't want monitoring) | Clear privacy policy, opt-out options, only collect approved metrics |
| **Security of central reporting** | Encrypt reports in transit/at rest, auth tokens, audit logs |
| **Breaking changes to dotfiles** | Semantic versioning, staged rollouts, --no-upgrade flag |
| **Adoption resistance** | Demonstrate value early, gather feedback, iterate |
| **Maintenance burden** | Comprehensive tests, documentation, community contributions |

---

## Next Steps

1. **Socialize roadmap** - Share with team, gather feedback
2. **Prioritize Phase 1** - Start with fleet health reporting (highest ROI)
3. **Proof of concept** - Build minimal fleet dashboard in 1 sprint
4. **Pilot program** - Test with 5-10 volunteers before rolling out
5. **Iterate** - Adjust roadmap based on feedback and lessons learned

---

## Appendix: Related Resources

- [Work Machine Setup Guide](work-machine.md)
- [Profiles Documentation](profiles.md)
- [Secrets Management](secrets.md)
- [Contributing Guidelines](https://github.com/bradbergeron-us/dotfiles/blob/main/CONTRIBUTING.md)
- [Architecture Overview](architecture.md)

---

*This roadmap is a living document. Priorities and timelines will be adjusted based on business needs and feedback.*
