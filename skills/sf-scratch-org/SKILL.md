---
name: sf-scratch-org
description: |
  Create and manage Salesforce scratch orgs with proper configuration, feature
  enablement, deployment strategies, and troubleshooting. Covers scratch org
  lifecycle, edition selection, expiration management, and common schema
  synchronization issues.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, scratch-org, development, devhub, deployment
---

# Salesforce Scratch Org Management

Create, configure, and manage scratch orgs effectively for development and testing. This guide covers the full lifecycle from creation to deletion, with troubleshooting for common issues.

## Why Scratch Orgs?

**For Development:**
- Isolated development environments
- Safe to experiment and break
- Easy to recreate from scratch
- Source-controlled configuration

**For Testing:**
- Fresh state for each test cycle
- Consistent, reproducible environments
- No accumulated data or configuration drift

---

## Scratch Org Lifecycle

```
┌─────────────────┐
│   Define Org    │  project-scratch-def.json
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Create Org   │  sf org create scratch
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Deploy Code   │  sf project deploy start
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Assign Perms   │  sf org assign permset
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Import Data    │  sf data import tree
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Develop      │  iterate, test, deploy
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Delete Org    │  sf org delete scratch
└─────────────────┘
```

---

## Scratch Org Configuration

### project-scratch-def.json

```json
{
  "orgName": "My Feature Dev",
  "edition": "Enterprise",
  "features": [
    "EnableSetPasswordInApi",
    "Communities",
    "ServiceCloud"
  ],
  "settings": {
    "lightningExperienceSettings": {
      "enableS1DesktopEnabled": true
    },
    "securitySettings": {
      "passwordPolicies": {
        "enableSetPasswordInApi": true
      }
    },
    "mobileSettings": {
      "enableS1EncryptedStoragePref2": false
    }
  }
}
```

### Edition Selection

| Edition | Use Case | Limits | Cost |
|---------|----------|--------|------|
| **Developer** | Simple development | Lower limits | Cheapest |
| **Enterprise** | Complex features, flows | Higher limits | Standard |
| **Professional** | Testing Pro tier features | Pro-specific | Standard |
| **Group** | Testing Group tier | Very limited | Standard |

**💡 Tip:** Use Enterprise edition for most development. Developer edition has lower governor limits that may mask issues.

### Common Features

```json
{
  "features": [
    "EnableSetPasswordInApi",
    "Communities",
    "ServiceCloud",
    "SalesCloud",
    "ContactsToMultipleAccounts",
    "PersonAccounts",
    "StateAndCountryPicklist",
    "MultiCurrency",
    "AuthorApex",
    "PlatformEncryption",
    "FieldAuditTrail",
    "Entitlements"
  ]
}
```

**⚠️ Warning:** Not all features can be combined. Some features conflict with each other.

---

## Creating Scratch Orgs

### Basic Creation

```bash
# Create with defaults (7 days)
sf org create scratch -f config/project-scratch-def.json -a my-scratch

# Create with longer duration
sf org create scratch -f config/project-scratch-def.json -a my-scratch -d 30

# Create and set as default
sf org create scratch -f config/project-scratch-def.json -a my-scratch --set-default

# Specify dev hub explicitly
sf org create scratch -f config/project-scratch-def.json -a my-scratch -v my-devhub
```

### Creation Options

| Flag | Purpose | Example |
|------|---------|---------|
| `-f` | Config file | `-f config/project-scratch-def.json` |
| `-a` | Alias | `-a feature-dev` |
| `-d` | Duration (days) | `-d 30` (max 30) |
| `-v` | Dev Hub | `-v my-devhub` |
| `--set-default` | Set as default org | `--set-default` |
| `-w` | Wait time (minutes) | `-w 15` |

### Verify Creation

```bash
# Display org details
sf org display -o my-scratch

# Open in browser
sf org open -o my-scratch

# List all scratch orgs
sf org list --all
```

---

## Deploying to Fresh Scratch Orgs

### ⚠️ Critical: Phased Deployment Required

Fresh scratch orgs may have schema synchronization issues. Deploy in phases:

### Phase 1: Objects and Fields

```bash
# Deploy custom objects first
sf project deploy start -d force-app/main/default/objects/ \
  --target-org my-scratch --wait 10

# Verify fields are registered
sf data query \
  --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'My_Object__c'" \
  --target-org my-scratch --use-tooling-api
```

### Phase 2: Apex Classes

```bash
# Deploy Apex after objects are confirmed
sf project deploy start -d force-app/main/default/classes/ \
  -d force-app/main/default/triggers/ \
  --target-org my-scratch --wait 10
```

### Phase 3: Everything Else

```bash
# Deploy remaining components
sf project deploy start -d force-app/ \
  --target-org my-scratch --wait 10
```

### Why Phased Deployment?

When deploying atomically to a fresh org:
1. Objects and Apex deploy in the same transaction
2. Apex may compile before object metadata is fully registered
3. Compiled Apex has stale schema references
4. Runtime queries fail with "No such column" errors

---

## Schema Synchronization Issues

### Symptom

Deployment succeeds, but Apex tests fail with:
```
System.QueryException: No such column 'MyField__c' on entity 'MyObject__c'
```

### Diagnosis

```bash
# 1. Verify field exists at metadata level
sf data query \
  --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'MyObject__c'" \
  --target-org my-scratch --use-tooling-api

# 2. Check Apex class status
sf data query \
  --query "SELECT Name, Status FROM ApexClass WHERE Name = 'MyService'" \
  --target-org my-scratch --use-tooling-api
```

### Fix: Force Apex Recompilation

**Option 1: Add version comment**

```apex
/**
 * @description My Service
 * @version 1.0.1 - Force recompile against updated schema
 */
public with sharing class MyService {
    // ...
}
```

Then redeploy the class.

**Option 2: Touch all Apex files**

```bash
# Add timestamp to force change detection
find force-app -name "*.cls" -exec touch {} \;

# Redeploy
sf project deploy start -d force-app/main/default/classes/ \
  --target-org my-scratch
```

**Option 3: Delete and recreate scratch org**

Sometimes the cleanest solution is to start fresh:

```bash
sf org delete scratch -o my-scratch --no-prompt
sf org create scratch -f config/project-scratch-def.json -a my-scratch-v2
# Then use phased deployment
```

---

## Post-Creation Setup

### Assign Permission Sets

```bash
# Single permission set
sf org assign permset -n My_Permission_Set -o my-scratch

# Multiple permission sets
sf org assign permset -n Perm_Set_1 -n Perm_Set_2 -o my-scratch
```

### Import Sample Data

```bash
# Import from JSON files
sf data import tree -p data/sample-data-plan.json -o my-scratch

# Import from CSV
sf data import bulk -f data/accounts.csv -s Account -o my-scratch
```

### Run Setup Scripts

```bash
# Run Apex setup script
sf apex run -f scripts/apex/setup.apex -o my-scratch
```

---

## Managing Scratch Orgs

### List Orgs

```bash
# List all orgs (scratch and regular)
sf org list

# List only scratch orgs
sf org list --all | grep -i scratch

# Show detailed info
sf org display -o my-scratch
```

### Extending Duration

```bash
# Scratch orgs cannot be extended past original creation
# Instead, create a new one and migrate data if needed
```

### Deleting Orgs

```bash
# Delete specific org
sf org delete scratch -o my-scratch --no-prompt

# Delete expired orgs (automatic)
# Expired orgs are automatically deleted after expiration
```

---

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `No available licenses` | Dev Hub limit | Delete expired scratch orgs |
| `Feature not available` | Edition mismatch | Use Enterprise edition |
| `Can't find object X` | Schema not deployed | Deploy objects first |
| `No such column` | Apex compiled against stale schema | Force recompilation |
| `Active scratch org limit` | Too many active orgs | Delete unused orgs |

### Schema Verification Script

```apex
// scripts/apex/verify-schema.apex
System.debug('=== Schema Verification ===');

// List expected objects
List<String> expectedObjects = new List<String>{
    'My_Object__c',
    'My_Child_Object__c'
};

Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

for (String objName : expectedObjects) {
    if (globalDescribe.containsKey(objName)) {
        System.debug('✅ ' + objName + ' exists');

        Schema.DescribeSObjectResult objDesc = globalDescribe.get(objName).getDescribe();
        System.debug('   Fields: ' + objDesc.fields.getMap().keySet());
    } else {
        System.debug('❌ ' + objName + ' NOT FOUND');
    }
}
```

### Test Query Script

```apex
// scripts/apex/test-queries.apex
System.debug('=== Query Verification ===');

try {
    List<SObject> results = Database.query(
        'SELECT Id, My_Field__c FROM My_Object__c LIMIT 1'
    );
    System.debug('✅ Query successful: ' + results.size() + ' records');
} catch (QueryException e) {
    System.debug('❌ Query failed: ' + e.getMessage());
}
```

---

## Scratch Org Checklist

### Pre-Creation
- [ ] Dev Hub is authorized and set default
- [ ] project-scratch-def.json is correct
- [ ] Required features are listed
- [ ] Edition supports needed functionality

### Creation
- [ ] Org created successfully
- [ ] Alias is meaningful
- [ ] Duration is appropriate (use 30 for longer projects)

### Post-Creation
- [ ] **Phase 1:** Objects deployed and verified
- [ ] **Phase 2:** Apex deployed successfully
- [ ] **Phase 3:** Remaining components deployed
- [ ] Permission sets assigned
- [ ] Sample data imported (if needed)
- [ ] Tests run successfully

### Ongoing
- [ ] Track expiration date
- [ ] Commit all changes to source control
- [ ] Delete when no longer needed

---

## Best Practices

### 1. Use Meaningful Aliases
```bash
# Good
sf org create scratch -a feature-mrb-booking

# Bad
sf org create scratch -a scratch1
```

### 2. Script Your Setup
Create a setup script to automate post-creation steps:

```bash
#!/bin/bash
# scripts/setup-scratch.sh

ORG_ALIAS=$1

echo "Creating scratch org..."
sf org create scratch -f config/project-scratch-def.json -a $ORG_ALIAS -d 30 --wait 15

echo "Deploying objects..."
sf project deploy start -d force-app/main/default/objects/ -o $ORG_ALIAS --wait 10

echo "Deploying Apex..."
sf project deploy start -d force-app/main/default/classes/ -o $ORG_ALIAS --wait 10

echo "Deploying remaining..."
sf project deploy start -d force-app/ -o $ORG_ALIAS --wait 10

echo "Assigning permission sets..."
sf org assign permset -n My_Permission_Set -o $ORG_ALIAS

echo "Running tests..."
sf apex run test --test-level RunLocalTests -o $ORG_ALIAS --wait 10

echo "Opening org..."
sf org open -o $ORG_ALIAS
```

### 3. Clean Up Regularly
```bash
# List all scratch orgs
sf org list --all

# Delete orgs you're not using
sf org delete scratch -o old-scratch --no-prompt
```

### 4. Use Namespaces for Packages
When developing packages, use namespace-enabled scratch orgs to catch namespace issues early.

---

## Related Skills

- [sf-deploy](../sf-deploy/) - Deployment strategies and error handling
- [sf-test](../sf-test/) - Running tests in scratch orgs
- [sf-data](../sf-data/) - Importing test data
- [sf-permissions](../sf-permissions/) - Managing permission sets
