---
name: sf-deploy
description: |
  Execute Salesforce deployments with proper dependency resolution, error handling,
  CI/CD pipeline patterns, rollback strategies, and release management. Covers
  SFDX deployments, package development, JWT authentication, delta deployments,
  destructive changes, and multi-org deployment patterns.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, deployment, ci-cd, devops, github-actions, release-management
---

# Salesforce Deployment Guide

Execute deployments safely with proper dependency resolution, testing, rollback strategies, and CI/CD integration. This guide covers everything from simple pushes to complex multi-org release pipelines.

## Understanding Salesforce Deployments

### Deployment Methods Comparison

| Method | Best For | Tracking | Rollback | CI/CD |
|--------|----------|----------|----------|-------|
| **SFDX Deploy** | Dev teams, automation | Source control | Manual | ✅ |
| **Change Sets** | Point-and-click | Limited | Very hard | ❌ |
| **Packages (Unlocked)** | Modular orgs | Version history | Uninstall | ✅ |
| **Packages (Managed)** | ISV, AppExchange | Full | Uninstall | ✅ |
| **Metadata API** | Programmatic | Source control | Manual | ✅ |
| **DevOps Center** | GitHub integration | UI-based | Promote/Rollback | ✅ |

**💡 Junior Developer Tip:** Always use source control (Git) with SFDX deployments. Never deploy directly without version control.

### Deployment Lifecycle

```
┌─────────────────┐
│  Development    │  Local development in VS Code
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Validate     │  Check deployment without committing
│   (Dry Run)     │  --dry-run flag
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Run Tests     │  Execute test classes
└────────┬────────┘
         │ Pass?
    ┌────┴────┐
   No        Yes
    │         │
    ▼         ▼
┌─────────┐  ┌─────────────────┐
│  Debug  │  │     Deploy      │
│  & Fix  │  │  (Commit to Org)│
└─────────┘  └────────┬────────┘
                      │
                      ▼
              ┌─────────────────┐
              │    Validate     │  Post-deploy verification
              └─────────────────┘
```

---

## Pre-Deployment Checklist

### Before Every Deployment

- [ ] Source is committed to Git
- [ ] Target org is correct (double-check alias!)
- [ ] Dependencies are already in target org
- [ ] Tests pass locally
- [ ] No merge conflicts
- [ ] Backup critical data if destructive changes
- [ ] Validate (dry-run) before actual deploy

### Verify Target Org

```bash
# CRITICAL: Always verify before deploying!
sf org display --target-org myOrg

# Output shows:
# - Username
# - Org ID
# - Instance URL
# - Expiration (scratch orgs)
```

**⚠️ Warning:** Many accidents happen by deploying to the wrong org. Set your default org carefully:
```bash
sf config set target-org myOrg --global
```

---

## SFDX Deploy Commands

### Basic Deployment

```bash
# Deploy entire source directory
sf project deploy start -d force-app/main/default/ --target-org myOrg

# Deploy specific metadata types
sf project deploy start -m ApexClass:AccountService --target-org myOrg

# Deploy multiple types
sf project deploy start -m ApexClass:AccountService,ApexClass:AccountServiceTest \
  --target-org myOrg
```

### Validation (Dry Run)

```bash
# Validate WITHOUT deploying
sf project deploy start -d force-app/ --dry-run --target-org myOrg

# Validate with tests
sf project deploy start -d force-app/ --dry-run \
  --test-level RunLocalTests --target-org myOrg
```

### Quick Deploy

After successful validation, use Quick Deploy to skip test re-execution:

```bash
# Get validation job ID from dry run output
# Then quick deploy (within 10 days)
sf project deploy quick --job-id 0Af... --target-org myOrg
```

**💡 Junior Developer Tip:** Quick Deploy is great for production where tests take hours. Validate overnight, quick deploy in morning.

### Preview Changes

```bash
# See what would be deployed (no action)
sf project deploy preview -d force-app/ --target-org myOrg
```

---

## Dependency Resolution

### Deployment Order

Deploy in this order to avoid dependency failures:

```
┌────────────────────────────────────────────────────┐
│  LAYER 1 - Schema & Configuration                  │
│  Objects, Fields, Record Types, Picklist Values   │
└───────────────────────┬────────────────────────────┘
                        ▼
┌────────────────────────────────────────────────────┐
│  LAYER 2 - Labels & Metadata                       │
│  Custom Labels, Custom Metadata Types, Settings   │
└───────────────────────┬────────────────────────────┘
                        ▼
┌────────────────────────────────────────────────────┐
│  LAYER 3 - Security                                │
│  Permission Sets, Custom Permissions              │
└───────────────────────┬────────────────────────────┘
                        ▼
┌────────────────────────────────────────────────────┐
│  LAYER 4 - Code                                    │
│  Apex Classes (utilities → services → triggers)   │
└───────────────────────┬────────────────────────────┘
                        ▼
┌────────────────────────────────────────────────────┐
│  LAYER 5 - Automation                              │
│  Flows, Validation Rules, Workflow Rules          │
└───────────────────────┬────────────────────────────┘
                        ▼
┌────────────────────────────────────────────────────┐
│  LAYER 6 - UI                                      │
│  LWC, Aura, Lightning Pages, Layouts              │
└────────────────────────────────────────────────────┘
```

### Common Dependency Errors

| Error | Missing Dependency | Fix |
|-------|-------------------|-----|
| `Entity not found: MyObject__c` | Custom Object | Deploy object first |
| `Variable does not exist: MY_LABEL` | Custom Label | Deploy label first |
| `Invalid type: MyClass` | Apex Class | Deploy dependent class first |
| `c:myComponent not found` | LWC | Deploy LWC before Lightning Page |
| `Permission Bypass_Automation not found` | Custom Permission | Deploy permission first |

### Handling Circular Dependencies

Sometimes two classes reference each other:

**Solution 1: Interface Pattern**
```apex
// Deploy interface first
public interface IAccountService {
    Account getAccount(Id accountId);
}

// Then implementation
public class AccountService implements IAccountService { ... }
```

**Solution 2: Late Binding**
```apex
// Use Type.forName for dynamic instantiation
Type serviceType = Type.forName('AccountService');
IAccountService service = (IAccountService) serviceType.newInstance();
```

---

## Test Levels

| Level | Usage | Test Execution |
|-------|-------|----------------|
| `NoTestRun` | Non-prod, metadata-only | None |
| `RunSpecifiedTests` | Known affected tests | Listed tests only |
| `RunLocalTests` | Production (standard) | All local tests (excludes managed packages) |
| `RunAllTestsInOrg` | Full validation | All tests including managed |

### Production Requirements

- **75% code coverage** across ALL Apex
- **Each trigger must have coverage**
- Tests must pass (no failures)

```bash
# Production deployment
sf project deploy start -d force-app/ \
  --test-level RunLocalTests \
  --target-org production

# With specific tests (faster)
sf project deploy start -d force-app/ \
  --test-level RunSpecifiedTests \
  --tests AccountServiceTest,ContactServiceTest \
  --target-org production
```

---

## Authentication for CI/CD

### JWT Bearer Flow (Recommended for CI/CD)

**Step 1: Create Connected App**
1. Setup → App Manager → New Connected App
2. Enable OAuth Settings
3. Callback URL: `http://localhost:1717/OauthRedirect`
4. Scopes: `api`, `refresh_token`, `web`
5. Enable "Use Digital Signatures"
6. Upload public certificate

**Step 2: Generate Certificates**
```bash
# Generate private key
openssl genrsa -out server.key 2048

# Generate certificate
openssl req -new -x509 -key server.key -out server.crt -days 365

# Upload server.crt to Connected App
```

**Step 3: Pre-authorize User**
```bash
# One-time authorization (interactive)
sf org login web --client-id <ConsumerKey> --instance-url https://login.salesforce.com
```

**Step 4: CI/CD Authentication**
```bash
# In CI/CD pipeline (headless)
sf org login jwt \
  --client-id <ConsumerKey> \
  --jwt-key-file server.key \
  --username deploy@myorg.com \
  --instance-url https://login.salesforce.com \
  --alias ci-org
```

### SFDX Auth URL (Simpler)

```bash
# Generate auth URL from existing login
sf org display --verbose --target-org myOrg | grep "Sfdx Auth Url"

# Store in CI/CD secrets, then login:
echo "$SF_AUTH_URL" > authUrl.txt
sf org login sfdx-url --sfdx-url-file authUrl.txt --alias ci-org
rm authUrl.txt  # Clean up
```

---

## CI/CD Pipeline Patterns

### GitHub Actions

```yaml
# .github/workflows/salesforce-ci.yml
name: Salesforce CI/CD

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main]

env:
  SF_DISABLE_TELEMETRY: true
  SF_USE_PROGRESS_BAR: false

jobs:
  # ===== VALIDATE on Pull Request =====
  validate:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for delta

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Authenticate to Org
        run: |
          echo "${{ secrets.SF_AUTH_URL_SANDBOX }}" > authUrl.txt
          sf org login sfdx-url --sfdx-url-file authUrl.txt --alias ci-sandbox
          rm authUrl.txt

      - name: Run Code Analyzer
        run: |
          sf plugins install @salesforce/plugin-code-analyzer
          sf code-analyzer run --workspace force-app/ --output-file results.sarif
        continue-on-error: true

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: results.sarif

      - name: Validate Deployment
        run: |
          sf project deploy start -d force-app/ \
            --dry-run \
            --test-level RunLocalTests \
            --target-org ci-sandbox

  # ===== DEPLOY on Push to Main =====
  deploy:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production  # Requires manual approval
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Authenticate to Production
        run: |
          echo "${{ secrets.SF_AUTH_URL_PROD }}" > authUrl.txt
          sf org login sfdx-url --sfdx-url-file authUrl.txt --alias ci-prod
          rm authUrl.txt

      - name: Deploy to Production
        run: |
          sf project deploy start -d force-app/ \
            --test-level RunLocalTests \
            --target-org ci-prod

      - name: Post-Deploy Verification
        run: |
          sf apex run -f scripts/verify-deployment.apex --target-org ci-prod
```

### Delta Deployments (Changed Files Only)

```bash
# Install delta plugin
sf plugins install sfdx-git-delta

# Generate delta package
sfdx sgd:source:delta \
  --from "origin/main" \
  --to "HEAD" \
  --output "delta/" \
  --generate-delta

# Deploy only changed files
sf project deploy start -d delta/force-app/ --target-org myOrg

# With destructive changes
sf project deploy start -d delta/force-app/ \
  --pre-destructive-changes delta/destructiveChangesPre.xml \
  --post-destructive-changes delta/destructiveChangesPost.xml \
  --target-org myOrg
```

---

## Destructive Changes

### When to Use Destructive Changes

- Renaming components (delete old, deploy new)
- Removing deprecated features
- Cleaning up technical debt

### Pre vs Post Destructive

| File | Timing | Use Case |
|------|--------|----------|
| `destructiveChangesPre.xml` | BEFORE deploy | Remove blocking dependencies |
| `destructiveChangesPost.xml` | AFTER deploy | Clean up replaced components |

### Example Destructive Manifest

```xml
<!-- destructiveChangesPost.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>OldClass</members>
        <members>DeprecatedService</members>
        <name>ApexClass</name>
    </types>
    <types>
        <members>Old_Flow</members>
        <name>Flow</name>
    </types>
    <version>62.0</version>
</Package>
```

```bash
# Deploy with destructive changes
sf project deploy start -d force-app/ \
  --post-destructive-changes manifest/destructiveChangesPost.xml \
  --target-org myOrg
```

### Destructive Change Limitations

| Component | Can Delete? | Notes |
|-----------|-------------|-------|
| Apex Class | ✅ | Must have no references |
| Custom Field | ✅ | Must clear data first in prod |
| Custom Object | ✅ | Must delete all records first |
| Flow | ✅ | Must deactivate first |
| Profile | ❌ | Cannot delete profiles |
| Standard Fields | ❌ | Cannot delete |
| Picklist Values | ⚠️ | Can only remove unused values |

---

## Rollback Strategies

### Strategy 1: Git Revert + Redeploy

```bash
# Find the commit to revert
git log --oneline -10

# Revert the bad commit
git revert <commit-hash>

# Redeploy previous state
sf project deploy start -d force-app/ --target-org myOrg
```

### Strategy 2: Version Tags

```bash
# Before deploying, tag the working state
git tag -a "pre-release-1.2.0" -m "Before feature X deployment"
git push origin pre-release-1.2.0

# If rollback needed:
git checkout pre-release-1.2.0
sf project deploy start -d force-app/ --target-org myOrg
```

### Strategy 3: Package Versions (Unlocked Packages)

```bash
# Deploy specific version
sf package install --package 04t... --target-org myOrg

# To rollback, install previous version
sf package install --package 04t...(previous) --target-org myOrg
```

### Components That Are Hard to Rollback

| Component | Challenge | Mitigation |
|-----------|-----------|------------|
| Data changes | No auto-rollback | Export backup before |
| Field deletions | Data is lost | Archive data before |
| Record Type changes | May affect data | Plan migration |
| Permission removals | Affects users immediately | Test thoroughly |

---

## Error Diagnosis

### Common Deployment Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Code coverage is below 75%` | Insufficient tests | Add test coverage |
| `Entity not found` | Missing dependency | Deploy dependency first |
| `Dependent class is invalid` | Compile error | Fix dependent class |
| `Test failure: assertion failed` | Test expecting wrong data | Fix test data/logic |
| `INSUFFICIENT_ACCESS` | Permission issue | Check deployed permissions |
| `DUPLICATE_VALUE` | Unique field violation | Fix duplicate in test |
| `FIELD_CUSTOM_VALIDATION_EXCEPTION` | Validation blocking test | Bypass or fix test data |
| `Component timeout` | Apex took >10s | Optimize code |

### Debugging Failed Deployments

```bash
# Get detailed deployment status
sf project deploy report --job-id <deploymentId>

# Resume watching long deployment
sf project deploy resume --job-id <deploymentId>

# Get coverage report
sf project deploy report --job-id <deploymentId> --coverage-formatters text
```

### Log Analysis

Look for these in deployment logs:
- `Dependent class is invalid` → Check class dependencies
- `duplicate value found` → Check External IDs
- `FIELD_FILTER_VALIDATION_EXCEPTION` → Check lookup filter

---

## Package Development

### Unlocked Packages (Recommended for Orgs)

```bash
# Create package
sf package create --name "My Feature" \
  --package-type Unlocked \
  --path force-app/main/default \
  --target-dev-hub devhub

# Create version
sf package version create --package "My Feature" \
  --installation-key test1234 \
  --wait 20 \
  --target-dev-hub devhub

# Install in org
sf package install --package "My Feature@1.0.0" \
  --installation-key test1234 \
  --target-org sandbox
```

### Version Promotion

```bash
# Promote to released (not beta)
sf package version promote --package "My Feature@1.0.0-1" \
  --target-dev-hub devhub

# Installing released versions doesn't require key
sf package install --package 04t... --target-org production
```

---

## Scratch Org Development

### Creating Scratch Orgs

```bash
# Basic scratch org
sf org create scratch -f config/project-scratch-def.json \
  --alias scratch1 -d 7

# With org shape (copies settings from real org)
sf org create scratch --source-org myProdOrg \
  --alias scratch1 -d 7
```

### Scratch Org Definition

```json
{
  "orgName": "My Company - Scratch",
  "edition": "Developer",
  "features": ["EnableSetPasswordInApi", "PersonAccounts"],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    }
  }
}
```

### Scratch Org Workflow

```bash
# Create
sf org create scratch -f config/project-scratch-def.json -a scratch1

# Push source
sf project deploy start --target-org scratch1

# Assign permission sets
sf org assign permset --name MyPermSet --target-org scratch1

# Import test data
sf data import tree -p data/plan.json --target-org scratch1

# Open and test
sf org open --target-org scratch1
```

---

## Workflow Summary

### Simple Deployment Workflow

```
1. DEVELOP
   └─ Make changes locally
   └─ Commit to Git branch

2. VALIDATE
   └─ sf project deploy start -d force-app/ --dry-run

3. DEPLOY
   └─ sf project deploy start -d force-app/

4. VERIFY
   └─ Test in target org
```

### Production Release Workflow

```
1. PREPARE
   └─ Complete all development in sandbox
   └─ Ensure 75%+ code coverage
   └─ Create release branch/tag

2. VALIDATE (afternoon before release)
   └─ sf project deploy start -d force-app/ --dry-run \
        --test-level RunLocalTests --target-org production
   └─ Save job ID for quick deploy

3. RELEASE WINDOW
   └─ sf project deploy quick --job-id <validationId>
   └─ Much faster (tests already ran)

4. VERIFY
   └─ Smoke test in production
   └─ Monitor debug logs
   └─ Check error reports

5. DOCUMENT
   └─ Update release notes
   └─ Tag in Git
```

### Emergency Hotfix Workflow

```
1. CREATE hotfix branch from production tag

2. FIX issue with minimal changes

3. VALIDATE in sandbox (fast)

4. DEPLOY to production
   └─ Use RunSpecifiedTests for speed
   └─ Only test affected code

5. MERGE back to main branch

6. POST-MORTEM
   └─ Why wasn't this caught?
   └─ Add regression test
```
