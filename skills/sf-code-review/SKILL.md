---
name: sf-code-review
description: |
  Review Salesforce Apex, LWC, and metadata code for security vulnerabilities,
  governor limit violations, and best practice adherence. Uses Salesforce Code
  Analyzer (sf code-analyzer) with PMD rules and a structured quality rubric. Use for
  code reviews, pull request checks, pre-deployment validation, and AppExchange
  security review preparation.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "3.0.0"
  tags: salesforce, code-review, security, pmd, code-analyzer, quality, runtime-validation
---

# Salesforce Code Review Guide

Review Salesforce code systematically using Salesforce Code Analyzer and a structured quality rubric. This guide helps you identify security vulnerabilities, governor limit violations, and best practice deviations before they reach production.

## Why Code Review Matters

**For Junior Developers:**
- Learn what "good" Salesforce code looks like
- Catch security issues before they become vulnerabilities
- Build habits that prevent governor limit errors
- Develop consistent coding standards

**For Teams:**
- Consistent, repeatable review process
- Measurable quality improvements
- Knowledge sharing across skill levels
- Faster pull request reviews

---

## Salesforce Code Analyzer Setup

### Installation

```bash
# Install the Code Analyzer plugin
sf plugins install @salesforce/plugin-code-analyzer

# Verify installation
sf code-analyzer --version

# Update rules to latest
# Rules are managed by the plugin automatically
```

### Available Rule Engines

| Engine | What It Checks |
|--------|----------------|
| **PMD** | Code style, best practices, performance |
| **ESLint** | JavaScript/LWC quality |
| **RetireJS** | Vulnerable JavaScript libraries |
| **Graph Engine** | Data flow analysis (advanced) |

**💡 Junior Developer Tip:** Start with PMD rules - they catch 80% of common issues without complex setup.

---

## Running Code Analyzer

### Basic Commands

```bash
# Full scan on force-app folder
sf code-analyzer run --workspace force-app/ --view table

# Scan specific file
sf code-analyzer run --workspace force-app/main/default/classes/MyClass.cls --view table

# Scan multiple paths
sf code-analyzer run --workspace force-app/main/default/classes/ --workspace force-app/main/default/triggers/ --view table

# Security-focused scan
sf code-analyzer run --workspace force-app/ --rule-selector Security --view table

# PMD rules only
sf code-analyzer run --workspace force-app/ --rule-selector pmd --view table
```

### Output Formats

```bash
# Table format (terminal display)
sf code-analyzer run --workspace force-app/ --view table

# CSV format (spreadsheet analysis)
sf code-analyzer run --workspace force-app/ --output-file results.csv

# JSON format (programmatic processing)
sf code-analyzer run --workspace force-app/ --output-file results.json

# HTML report (shareable)
sf code-analyzer run --workspace force-app/ --output-file report.html

# Multiple output formats simultaneously
sf code-analyzer run --workspace force-app/ --output-file results.csv --output-file results.html
```

### Severity Thresholds

```bash
# Fail if any Critical (1) or High (2) issues found
sf code-analyzer run --workspace force-app/ --severity-threshold 2

# Fail only on Critical issues
sf code-analyzer run --workspace force-app/ --severity-threshold 1

# Show violations but don't fail (Low severity)
sf code-analyzer run --workspace force-app/ --severity-threshold 4
```

| Severity | Level | Action |
|----------|-------|--------|
| 1 | Critical | Must fix before deploy |
| 2 | High | Should fix before deploy |
| 3 | Medium | Fix when possible |
| 4 | Low | Consider fixing |
| 5 | Info | Informational only |

---

## Quality Rubric (30 Points Total)

Score each category from 0-5 points. Total of 30 points possible (25 static + 5 runtime).

### Category 1: Security (0-5 points)

| Score | Criteria |
|-------|----------|
| 0 | No security considerations |
| 1 | Basic `with sharing` only |
| 2 | `with sharing` + some CRUD checks |
| 3 | CRUD checks on reads |
| 4 | Full CRUD/FLS with `WITH USER_MODE` |
| 5 | Full CRUD/FLS on reads AND writes + no injection risks |

**Checklist:**
- [ ] All classes declare `with sharing` or `inherited sharing`
- [ ] SOQL uses `WITH USER_MODE` or `AccessLevel.USER_MODE`
- [ ] DML uses `Security.stripInaccessible()`
- [ ] No string concatenation in dynamic SOQL
- [ ] No hardcoded IDs or credentials
- [ ] External callouts use Named Credentials

**Example - Score 5:**
```apex
public with sharing class AccountService {
    public List<Account> getAccounts(Set<Id> accountIds) {
        // WITH USER_MODE enforces CRUD/FLS
        return [
            SELECT Id, Name, Industry
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ];
    }

    public void updateAccounts(List<Account> accounts) {
        // stripInaccessible removes fields user can't edit
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            accounts
        );
        update decision.getRecords();
    }
}
```

### Category 2: Governor Limits (0-5 points)

| Score | Criteria |
|-------|----------|
| 0 | SOQL and/or DML inside loops |
| 1 | SOQL in loop but DML outside |
| 2 | No SOQL/DML in loops but inefficient |
| 3 | Efficient queries with Maps/Sets |
| 4 | Fully optimized, SOQL for-loops for large data |
| 5 | Optimal + considers CPU time + async when needed |

**Checklist:**
- [ ] No SOQL queries inside loops
- [ ] No DML statements inside loops
- [ ] Uses `Map<Id, SObject>` for lookups
- [ ] SELECT only needed fields
- [ ] Proper WHERE filters to limit rows
- [ ] Uses SOQL for-loops for large datasets

**Example - Score 5:**
```apex
// Collect IDs first
Set<Id> accountIds = new Set<Id>();
for (Contact c : contacts) {
    accountIds.add(c.AccountId);
}

// Single query with Map for O(1) lookup
Map<Id, Account> accountMap = new Map<Id, Account>([
    SELECT Id, Name FROM Account WHERE Id IN :accountIds
]);

// Process using Map lookup (no nested loop)
List<Contact> toUpdate = new List<Contact>();
for (Contact c : contacts) {
    Account acc = accountMap.get(c.AccountId);
    if (acc != null) {
        c.Description = 'Account: ' + acc.Name;
        toUpdate.add(c);
    }
}

// Single DML outside loop
update toUpdate;
```

### Category 3: Bulkification (0-5 points)

| Score | Criteria |
|-------|----------|
| 0 | Only handles single records |
| 1 | Handles multiple but inefficiently |
| 2 | Uses collections but has nested loops |
| 3 | Proper collection usage throughout |
| 4 | Handles 200+ records efficiently |
| 5 | Optimal for any volume + considers limits |

**Checklist:**
- [ ] Methods accept `List<SObject>` not single records
- [ ] Uses Sets for unique values
- [ ] Uses Maps for O(1) lookups
- [ ] Avoids nested for-loops on large collections
- [ ] Considers `Limits.getLimitDmlRows()` for batching

### Category 4: Patterns & Structure (0-5 points)

| Score | Criteria |
|-------|----------|
| 0 | No clear structure |
| 1 | Basic organization |
| 2 | Follows some naming conventions |
| 3 | Trigger handler pattern used |
| 4 | Service layer separation |
| 5 | Full separation + consistent naming + documented |

**Checklist:**
- [ ] Trigger delegates to handler (no logic in trigger)
- [ ] Service classes for business logic
- [ ] Selector classes for queries (optional)
- [ ] PascalCase for classes, camelCase for methods
- [ ] Descriptive naming (not `x`, `temp`, `data`)
- [ ] ApexDoc comments on public methods

### Category 5: Completeness (0-5 points)

| Score | Criteria |
|-------|----------|
| 0 | Incomplete or broken code |
| 1 | Works but missing error handling |
| 2 | Basic error handling present |
| 3 | Handles edge cases |
| 4 | Comprehensive + testable |
| 5 | Production-ready + documented + tested |

**Checklist:**
- [ ] Null checks for optional parameters
- [ ] Try-catch for external calls
- [ ] Test class with 75%+ coverage
- [ ] ApexDoc comments on public methods
- [ ] Handles empty collections gracefully

### Category 6: Runtime Validation (0-5 points)

| Score | Criteria |
|-------|----------|
| 0 | No runtime testing performed |
| 1 | Tests run but failures ignored |
| 2 | Tests pass locally |
| 3 | Tests pass in target org |
| 4 | Tests + manual smoke test |
| 5 | Full integration test suite passes |

**Checklist:**
- [ ] Deployment successful with no compile errors
- [ ] All custom objects/fields exist in target org
- [ ] FieldDefinition query confirms schema accessibility
- [ ] Test execution passes in target org
- [ ] Permission sets include required FLS

---

## Grade Scale

| Score | Grade | Meaning |
|-------|-------|---------|
| 28-30 | ⭐⭐⭐⭐⭐ Excellent | Production ready, exemplary code |
| 23-27 | ⭐⭐⭐⭐ Good | Minor improvements, deploy-ready |
| 18-22 | ⭐⭐⭐ Acceptable | Several issues to address |
| 12-17 | ⭐⭐ Needs Work | Significant refactoring required |
| 0-11 | ⭐ Critical | Major rewrite needed |

---

## Security Patterns to Flag

Use these patterns to search for common vulnerabilities:

| Vulnerability | Search Pattern | Fix |
|--------------|----------------|-----|
| Missing sharing | `public\s+class` without `sharing` | Add `with sharing` |
| System mode SOQL | `\[SELECT.*FROM.*\]` without `USER_MODE` | Add `WITH USER_MODE` |
| SOQL injection | `'SELECT.*'\s*\+` (string concat) | Use bind variables `:var` |
| Hardcoded secrets | `password\|apikey\|secret` in strings | Use Named Credentials |
| Debug with PII | `System\.debug.*SSN\|Password` | Remove PII from logs |
| Missing null check | Direct `.` after method call | Add null check |

---

## Runtime Validation

Static analysis catches code quality issues, but runtime validation catches deployment and schema issues that only appear when code executes in an org.

### Why Static Analysis Isn't Enough

Code Analyzer validates:
- ✅ Syntax correctness
- ✅ Security patterns (CRUD/FLS)
- ✅ Governor limit patterns (SOQL in loops)
- ✅ Best practice adherence

Code Analyzer does NOT validate:
- ❌ Schema existence (does the field exist in target org?)
- ❌ Permission assignments (does user have FLS?)
- ❌ Apex compilation against live schema
- ❌ Runtime behavior of queries

### Runtime Validation Checklist

After static analysis passes, perform these runtime checks:

#### 1. Schema Verification
```bash
# Verify custom fields exist and are accessible
sf data query --query "SELECT QualifiedApiName, DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'My_Object__c'" \
  --target-org myOrg --use-tooling-api
```

#### 2. Apex Compilation Check
```bash
# Force compile all Apex to verify against current schema
sf apex run -f scripts/apex/compile-check.apex --target-org myOrg
```

Where `compile-check.apex` queries each custom object to verify Apex can access fields:
```apex
try {
    SObject test = Database.query('SELECT Id, My_Field__c FROM My_Object__c LIMIT 1');
    System.debug('✅ My_Object__c.My_Field__c is queryable');
} catch (QueryException e) {
    System.debug('❌ Query failed: ' + e.getMessage());
}
```

#### 3. Test Execution
```bash
# Run tests to validate runtime behavior
sf apex run test --test-level RunLocalTests --target-org myOrg --wait 10
```

#### 4. Permission Validation
```bash
# Verify permission set includes required fields
sf data query --query "SELECT Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Parent.Name = 'My_Permission_Set' AND SobjectType = 'My_Object__c'" \
  --target-org myOrg --use-tooling-api
```

---

## Post-Deployment Verification

After successful deployment, verify the code works at runtime:

### Immediate Verification (Automated)

```bash
# 1. Run specific test classes for deployed components
sf apex run test --class-names MyServiceTest --target-org myOrg --wait 10

# 2. Check for async errors
sf apex tail log --target-org myOrg

# 3. Verify no outstanding deploy errors
sf project deploy report --target-org myOrg
```

### Verification Apex Script

Create a reusable verification script:

```apex
// scripts/apex/verify-deployment.apex

// Test schema accessibility
System.debug('=== Schema Verification ===');
Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

List<String> requiredObjects = new List<String>{
    'My_Object__c',
    'My_Child_Object__c'
};

for (String objName : requiredObjects) {
    if (globalDescribe.containsKey(objName)) {
        System.debug('✅ ' + objName + ' exists');

        // Verify key fields
        Schema.DescribeSObjectResult objDescribe = globalDescribe.get(objName).getDescribe();
        Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();

        List<String> requiredFields = new List<String>{
            'My_Field__c',
            'Another_Field__c'
        };

        for (String fieldName : requiredFields) {
            if (fields.containsKey(fieldName.toLowerCase())) {
                System.debug('  ✅ ' + fieldName + ' accessible');
            } else {
                System.debug('  ❌ ' + fieldName + ' NOT accessible');
            }
        }
    } else {
        System.debug('❌ ' + objName + ' NOT FOUND');
    }
}

// Test query execution
System.debug('=== Query Verification ===');
try {
    Integer count = [SELECT COUNT() FROM My_Object__c];
    System.debug('✅ Query succeeded: ' + count + ' records');
} catch (QueryException e) {
    System.debug('❌ Query failed: ' + e.getMessage());
}
```

### Manual Smoke Test Checklist

For UI components (LWC, Flows):

- [ ] Component renders without JavaScript errors
- [ ] Data loads correctly
- [ ] CRUD operations work (create, edit, delete)
- [ ] Error messages display properly
- [ ] Permission-restricted features hidden for regular users

---

## Diagnosing Schema Synchronization Issues

When Code Analyzer passes but Apex fails with "No such column" errors:

### Symptoms
1. Deployment reports success
2. Fields visible in Setup > Object Manager
3. FieldDefinition query shows fields
4. Apex test throws QueryException: "No such column 'X' on 'Y'"

### Root Cause
Apex runtime compiled against stale schema metadata. The compiler caches schema information.

### Diagnosis Commands

```bash
# Check field exists at metadata level
sf data query --query "SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName = 'My_Object__c'" \
  --target-org myOrg --use-tooling-api

# Check Apex class compilation status
sf data query --query "SELECT Name, Status, LastModifiedDate FROM ApexClass WHERE Name = 'MyService'" \
  --target-org myOrg --use-tooling-api
```

### Resolution Steps

1. **Add version comment to Apex**
   ```apex
   /**
    * @version 1.0.1 - Force recompile
    */
   ```

2. **Redeploy the Apex class**
   ```bash
   sf project deploy start -m ApexClass:MyService --target-org myOrg
   ```

3. **Verify with test run**
   ```bash
   sf apex run test --class-names MyServiceTest --target-org myOrg
   ```

### Prevention

Add to your deployment workflow:
1. Deploy objects/fields first
2. Verify with FieldDefinition query
3. Deploy Apex second
4. Run tests to confirm schema access

---

## Code Review Report Template

```markdown
# Code Review Report

**File(s) Reviewed:** {list of files}
**Reviewer:** {name or agent}
**Date:** {current date}
**Target Org:** {org alias}

## Static Analysis Results

### Code Analyzer Output
{Paste output from sf code-analyzer run}

### Quality Scores (Static)

| Category | Score | Notes |
|----------|-------|-------|
| Security | X/5 | {brief note} |
| Governor Limits | X/5 | {brief note} |
| Bulkification | X/5 | {brief note} |
| Patterns | X/5 | {brief note} |
| Completeness | X/5 | {brief note} |
| **Static Total** | **XX/25** | |

## Runtime Validation Results

### Deployment Status
- [ ] Deployment successful
- [ ] No compile errors

### Schema Verification
- [ ] All custom objects exist
- [ ] All custom fields accessible
- [ ] FieldDefinition query confirms fields

### Test Execution
- Tests Run: {count}
- Pass Rate: {percentage}
- Code Coverage: {percentage}

### Runtime Score

| Criteria | Score | Notes |
|----------|-------|-------|
| Runtime Validation | X/5 | {deployment, tests, verification} |

## Combined Score

| Section | Score |
|---------|-------|
| Static Analysis | XX/25 |
| Runtime Validation | X/5 |
| **Total** | **XX/30** |

## Critical Issues (Must Fix)
{list issues}

## Summary
{Overall assessment including both static and runtime findings}
```
