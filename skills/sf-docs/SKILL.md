---
name: sf-docs
description: |
  Create comprehensive Salesforce documentation and navigate official resources.
  Covers ApexDoc standards, README templates, code commenting best practices,
  release notes, runbooks, and finding the right official documentation.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, documentation, apexdoc, standards, reference
---

# Salesforce Documentation Guide

Create and maintain high-quality documentation for Salesforce projects. This guide covers ApexDoc standards, code commenting, project documentation, and navigating official Salesforce resources.

## ApexDoc Standards

### Class-Level Documentation

Every Apex class must have a header comment:

```apex
/**
 * @description Service class for Account-related business operations.
 *              Handles account creation, updates, and related contact management.
 *
 * @author      John Smith (john.smith@company.com)
 * @date        2024-03-15
 * @version     1.0
 *
 * @group       Account Services
 * @see         AccountTriggerHandler
 * @see         AccountSelector
 *
 * @changelog
 *   2024-03-15  John Smith  Initial version
 *   2024-03-20  Jane Doe    Added bulk account creation method
 */
public with sharing class AccountService {
    // ...
}
```

### Method-Level Documentation

```apex
/**
 * @description Creates accounts with associated contacts and returns the created Account IDs.
 *              Validates input data and handles governor limit considerations.
 *
 * @param accountsToCreate List of AccountWrapper objects containing account and contact data
 * @param bypassValidation If true, skips custom validation rules (requires admin permission)
 *
 * @return List<Id> IDs of successfully created Accounts
 *
 * @throws AccountException if validation fails or DML error occurs
 * @throws InsufficientAccessException if user lacks create permission
 *
 * @example
 * List<AccountWrapper> wrappers = new List<AccountWrapper>();
 * wrappers.add(new AccountWrapper('ACME Corp', 'Technology'));
 * List<Id> accountIds = AccountService.createAccounts(wrappers, false);
 */
public static List<Id> createAccounts(List<AccountWrapper> accountsToCreate, Boolean bypassValidation) {
    // Implementation
}
```

### ApexDoc Tags Reference

| Tag | Required | Description |
|-----|----------|-------------|
| `@description` | ✅ | What the class/method does |
| `@author` | ✅ | Who wrote it (email preferred) |
| `@date` | ✅ | Creation date (YYYY-MM-DD) |
| `@param` | ✅* | Parameter name and description (*if parameters exist) |
| `@return` | ✅* | Return type and description (*if not void) |
| `@throws` | ✅* | Exception types and conditions (*if throws) |
| `@example` | ⚠️ | Usage example (recommended) |
| `@see` | ⚠️ | Related classes/methods |
| `@group` | ⚠️ | Logical grouping |
| `@version` | ⚠️ | Version number |
| `@changelog` | ⚠️ | History of changes |

### Test Class Documentation

```apex
/**
 * @description Test class for AccountService with coverage for:
 *              - Positive scenarios (successful operations)
 *              - Negative scenarios (validation failures)
 *              - Bulk operations (200+ records)
 *              - Permission scenarios (different user contexts)
 *
 * @author      Jane Doe
 * @date        2024-03-16
 * @coverage    AccountService (97%)
 *
 * @group       Tests
 * @see         AccountService
 */
@IsTest
private class AccountServiceTest {

    /**
     * @description Tests successful account creation with valid data.
     *              Verifies:
     *              - Accounts are inserted
     *              - Contacts are associated
     *              - Return IDs match inserted records
     */
    @IsTest
    static void createAccounts_ValidData_CreatesRecords() {
        // Arrange, Act, Assert
    }
}
```

---

## Code Commenting Best Practices

### When to Comment

| Do Comment | Don't Comment |
|------------|---------------|
| Complex business logic | Obvious code (`i++; // increment i`) |
| Governor limit workarounds | Every line |
| Non-obvious decisions | Self-documenting code |
| TODO/FIXME items | Commented-out code (remove it) |
| Integration specifics | Personal notes |

### Inline Comment Patterns

```apex
// BAD: Obvious comment
account.Name = 'Test'; // Set the name

// GOOD: Explains business rule
// Per finance policy, subsidiaries inherit parent's billing address
account.BillingAddress = parentAccount.BillingAddress;

// GOOD: Explains technical decision
// Using SOQL for-loop to avoid heap limits on large result sets
for (Account acc : [SELECT Id, Name FROM Account WHERE Industry = 'Technology']) {
    processAccount(acc);
}

// GOOD: Governor limit awareness
// Bulk insert outside loop - single DML for all records
insert accountsToInsert; // Max 10,000 records per transaction
```

### TODO Comments

```apex
// TODO: Implement retry logic for callout failures (JIRA-1234)
// FIXME: Race condition when multiple users update same record
// HACK: Workaround for platform bug in Winter '24 - remove after fix
// NOTE: This sequence must match external system's expected order
```

---

## Project Documentation

### README Template

```markdown
# Project Name

Brief description of the Salesforce project and its purpose.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)

## Overview

Detailed description of:
- What problem this solves
- Key features
- Target users

## Prerequisites

- Salesforce CLI (`sf`) installed
- Access to target org with System Administrator profile
- DevHub enabled (for scratch orgs)

## Installation

### Option 1: Scratch Org (Development)
\`\`\`bash
# Clone repository
git clone https://github.com/company/project.git
cd project

# Create scratch org
sf org create scratch -f config/project-scratch-def.json -a myscratch -d 7

# Deploy source
sf project deploy start --target-org myscratch

# Assign permission set
sf org assign permset --name My_Permission_Set --target-org myscratch

# Import sample data
sf data import tree -p data/sample-plan.json --target-org myscratch
\`\`\`

### Option 2: Sandbox/Production
\`\`\`bash
sf project deploy start -d force-app/ --target-org mySandbox --test-level RunLocalTests
\`\`\`

## Configuration

### Custom Settings
Navigate to Setup → Custom Settings → [Setting Name] to configure:
- `API_Endpoint__c`: External API URL
- `Batch_Size__c`: Number of records per batch

### Custom Metadata
Deploy configuration via:
\`\`\`bash
sf project deploy start -m CustomMetadata:Config__mdt.Production --target-org myOrg
\`\`\`

## Usage

### Feature 1: Account Processing
1. Navigate to Account record
2. Click "Process Account" button
3. Confirm the action

## Testing

\`\`\`bash
# Run all tests
sf apex run test --test-level RunLocalTests --target-org myscratch

# Run specific test class
sf apex run test --class-names AccountServiceTest --target-org myscratch
\`\`\`

## Deployment

See [deployment guide](docs/DEPLOYMENT.md) for:
- Pre-deployment checklist
- Deployment steps
- Rollback procedures

## Contributing

1. Create feature branch from `develop`
2. Follow naming convention: `feature/JIRA-123-description`
3. Ensure 85%+ code coverage
4. Submit pull request with description
```

### Folder Documentation

Create README.md in key folders:

```
force-app/
├── main/
│   └── default/
│       ├── classes/
│       │   └── README.md  ← Document class organization
│       ├── lwc/
│       │   └── README.md  ← Document component library
│       └── flows/
│           └── README.md  ← Document automation
```

**Example: classes/README.md**
```markdown
# Apex Classes

## Organization

| Folder/Prefix | Purpose |
|---------------|---------|
| `*Service` | Business logic services |
| `*Selector` | SOQL query classes |
| `*Domain` | Domain layer classes |
| `*TriggerHandler` | Trigger handler classes |
| `*Controller` | LWC/Aura controllers |
| `*Test` | Test classes |
| `*Batch` | Batch Apex classes |
| `*Queueable` | Queueable Apex classes |

## Key Classes

- **AccountService**: Account business operations
- **AccountSelector**: Account SOQL queries
- **AccountTriggerHandler**: Account trigger logic
```

---

## Runbook Documentation

### Runbook Template

```markdown
# [Feature Name] Runbook

## Overview
Brief description of the feature/process this runbook covers.

## When to Use
- Scenario 1 that requires this runbook
- Scenario 2

## Prerequisites
- [ ] Access to production org
- [ ] Permission set assigned
- [ ] Data backup completed

## Procedure

### Step 1: Preparation
1. Log in to Salesforce
2. Navigate to [location]
3. Verify [condition]

### Step 2: Execution
\`\`\`bash
# Command to execute (if applicable)
sf apex run -f scripts/feature.apex --target-org prod
\`\`\`

### Step 3: Verification
- [ ] Check [specific record/log]
- [ ] Verify [expected outcome]
- [ ] Confirm [success criteria]

## Rollback Procedure

If issues occur:
1. Stop the process
2. Execute rollback script:
   \`\`\`bash
   sf apex run -f scripts/rollback.apex --target-org prod
   \`\`\`
3. Notify [team/stakeholder]

## Troubleshooting

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| Error message X | Missing permission | Assign permission set |
| Process hangs | Governor limit | Reduce batch size |

## Contacts

| Role | Name | Contact |
|------|------|---------|
| Primary Support | John Smith | john@company.com |
| Escalation | Jane Doe | jane@company.com |
```

---

## Official Salesforce Documentation

### Developer Guides

| Guide | URL | Use For |
|-------|-----|---------|
| Apex Developer Guide | `developer.salesforce.com/docs/atlas.en-us.apexcode.meta/` | Apex classes, triggers, async, limits |
| SOQL/SOSL Reference | `developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/` | Query syntax, aggregates |
| LWC Developer Guide | `developer.salesforce.com/docs/platform/lwc/guide/` | LWC components, wire |
| Metadata API Reference | `developer.salesforce.com/docs/atlas.en-us.api_meta.meta/` | Metadata types |
| REST API Guide | `developer.salesforce.com/docs/atlas.en-us.api_rest.meta/` | REST endpoints |
| Bulk API 2.0 | `developer.salesforce.com/docs/atlas.en-us.api_asynch.meta/` | Bulk operations |
| Platform Events | `developer.salesforce.com/docs/atlas.en-us.platform_events.meta/` | Event-driven |
| Agentforce | `developer.salesforce.com/docs/einstein/genai/guide/` | AI agents |

### Finding Documentation by Task

| Task | Start Here |
|------|-----------|
| Write Apex | Apex Developer Guide |
| Write SOQL | SOQL/SOSL Reference |
| Build LWC | LWC Developer Guide |
| Build Flow | help.salesforce.com → Flow Builder |
| Deploy | Salesforce DX Developer Guide |
| Build Integration | REST API Guide |
| Security | Apex Security Guide |
| Build AI Agent | Agentforce Developer Guide |

### CLI Help Commands

```bash
# Get help for any command
sf project deploy start --help
sf apex run test --help
sf data query --help

# Search commands
sf search deploy

# List all commands
sf commands
```

---

## Documentation Generation

### Generate ApexDoc HTML

```bash
# Install ApexDoc
npm install -g apexdocs

# Generate documentation
apexdocs -s force-app/main/default/classes -t docs/apex
```

### Generate Package.xml Documentation

```bash
# List what's in your package
sf project generate manifest -d force-app/ --output-dir docs/
```

---

## Workflow Summary

### New Feature Documentation Workflow

1. **Before Coding**
   - Document requirements
   - Create design doc

2. **During Development**
   - Add ApexDoc to all classes/methods
   - Add inline comments for complex logic

3. **Before PR**
   - Update README if needed
   - Add/update runbook
   - Document configuration

4. **After Deployment**
   - Update release notes
   - Notify stakeholders