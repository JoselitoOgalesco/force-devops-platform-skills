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
  version: "2.0.0"
  tags: salesforce, code-review, security, pmd, code-analyzer, quality
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

## Quality Rubric (25 Points Total)

Score each category from 0-5 points. Total of 25 points possible.

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

---

## Grade Scale

| Score | Grade | Meaning |
|-------|-------|---------|
| 23-25 | ⭐⭐⭐⭐⭐ Excellent | Production ready, exemplary code |
| 19-22 | ⭐⭐⭐⭐ Good | Minor improvements, deploy-ready |
| 15-18 | ⭐⭐⭐ Acceptable | Several issues to address |
| 10-14 | ⭐⭐ Needs Work | Significant refactoring required |
| 0-9 | ⭐ Critical | Major rewrite needed |

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

### grep Commands for Quick Checks

```bash
# Find classes without sharing declaration
grep -rn "public class" force-app/main/default/classes/ | grep -v "sharing"

# Find SOQL without USER_MODE
grep -rn "\[SELECT" force-app/main/default/classes/ | grep -v "USER_MODE"

# Find potential SOQL injection
grep -rn "SELECT.*FROM.*WHERE.*'\s*\+" force-app/main/default/classes/

# Find hardcoded IDs
grep -rn "'001\|'003\|'005\|'00D" force-app/main/default/classes/

# Find System.debug with potential PII
grep -rn "System\.debug.*password\|System\.debug.*secret" force-app/main/default/classes/
```

---

## Code Review Report Template

```markdown
# Code Review Report

**File(s) Reviewed:** {list of files}
**Reviewer:** {name or agent}
**Date:** {current date}

## Code Analyzer Results

{Paste output from sf code-analyzer run}

## Quality Scores

| Category | Score | Notes |
|----------|-------|-------|
| Security | X/5 | {brief note} |
| Governor Limits | X/5 | {brief note} |
| Bulkification | X/5 | {brief note} |
| Patterns | X/5 | {brief note} |
| Completeness | X/5 | {brief note} |
| **Total** | **XX/25** | **Grade: ⭐⭐⭐⭐** |

## Critical Issues (Must Fix)

1. **{Issue Title}**
   - **Location:** {file}:{line}
   - **Problem:** {description}
   - **Fix:** {recommendation}
   - **Code:**
     ```apex
     // ❌ Before
     {problematic code}

     // ✅ After
     {fixed code}
     ```

## Warnings (Should Fix)

1. **{Issue Title}**
   - **Location:** {file}:{line}
   - **Fix:** {recommendation}

## Suggestions (Nice to Have)

1. {Improvement suggestion}

## Summary

{Overall assessment and recommended next steps}
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Code Review
on:
  pull_request:
    paths:
      - 'force-app/**'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Install Code Analyzer
        run: sf plugins install @salesforce/plugin-code-analyzer

      - name: Run Security Scan
        run: |
          sf code-analyzer run \
            --workspace force-app/ \
            --rule-selector Security \
            --severity-threshold 2 \
            --output-file results.sarif

      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: results.sarif
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running Salesforce Code Analyzer..."
sf code-analyzer run --workspace force-app/ --severity-threshold 2

if [ $? -ne 0 ]; then
    echo "❌ Code Analyzer found critical issues. Fix before committing."
    exit 1
fi

echo "✅ Code review passed!"
```

---

## Common Mistakes & Fixes

### Mistake 1: Ignoring Scanner Warnings

```bash
# ❌ Just running and ignoring output
sf code-analyzer run --workspace force-app/

# ✅ Setting severity threshold to fail on issues
sf code-analyzer run --workspace force-app/ --severity-threshold 2
```

### Mistake 2: Only Scanning Changed Files

```bash
# ❌ Only scanning one file misses cross-file issues
sf code-analyzer run --workspace force-app/main/default/classes/OneFile.cls

# ✅ Scan the full folder to catch dependencies
sf code-analyzer run --workspace force-app/main/default/classes/
```

### Mistake 3: Skipping Security Rules

```bash
# ❌ Default scan uses only Recommended rules
sf code-analyzer run --workspace force-app/

# ✅ Explicitly include Security rules
sf code-analyzer run --workspace force-app/ --rule-selector "Security,BestPractices"
```

---

## Related Skills

- [sf-security](../sf-security/) - Deep dive on CRUD/FLS and sharing
- [sf-apex](../sf-apex/) - Apex coding patterns and governor limits
- [sf-test](../sf-test/) - Writing test classes for reviewed code
- [sf-deploy](../sf-deploy/) - CI/CD pipeline integration
- [sf-eval](../sf-eval/) - Detailed evaluation rubric
