---
name: sf-eval
description: |
  Evaluate and benchmark Salesforce code quality. Compares code against a
  Salesforce-specific rubric covering security, governor limits, bulkification,
  patterns, and completeness. Use for code reviews, skill evaluation, or
  quality assessments.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, evaluation, benchmark, quality, code-review
---

# Salesforce Code Evaluation Guide

This guide helps you evaluate Salesforce code quality using a structured rubric. Whether you're reviewing your own code, a colleague's code, or evaluating AI-generated code, this framework ensures consistent, comprehensive quality assessments.

## Why Code Evaluation Matters

**For Junior Developers:**
- Learn what "good" Salesforce code looks like
- Understand common mistakes before they reach production
- Build habits that prevent governor limit issues
- Develop security-first thinking

**For Teams:**
- Consistent code review standards
- Measurable quality improvements
- Knowledge sharing across skill levels

## The Salesforce Quality Rubric

Score each category from 0-5 (25 points total):

| Category | What to Check | Why It Matters |
|----------|---------------|----------------|
| **Security** | CRUD/FLS checks, sharing rules, injection prevention | Protect data, prevent unauthorized access |
| **Governor Limits** | No SOQL/DML in loops, efficient queries | Prevent runtime failures in production |
| **Bulkification** | Handles 200+ records, uses collections | Triggers receive up to 200 records at once |
| **Patterns** | Trigger handlers, service layers, naming | Maintainable, testable code |
| **Completeness** | Requirements met, edge cases, error handling | Production-ready code |

## Category 1: Security (0-5 points)

### What to Look For

| Score | Criteria |
|-------|----------|
| 0 | No security considerations at all |
| 1 | Basic `with sharing` but no CRUD/FLS |
| 2 | Has `with sharing` and some CRUD checks |
| 3 | CRUD checks on read, `with sharing` throughout |
| 4 | Full CRUD/FLS on reads (WITH USER_MODE), `with sharing` |
| 5 | Full CRUD/FLS on reads AND writes (stripInaccessible), no injection risks |

### Security Checklist

- [ ] **Class sharing**: Uses `with sharing` (or `inherited sharing` with justification)
- [ ] **SOQL security**: Uses `WITH USER_MODE` or checks `Schema.sObjectType.*.isAccessible()`
- [ ] **DML security**: Uses `Security.stripInaccessible()` before insert/update
- [ ] **Dynamic SOQL**: Uses `String.escapeSingleQuotes()` for user input
- [ ] **No hardcoded IDs**: Uses Custom Metadata or Custom Settings instead
- [ ] **No credentials in code**: Uses Named Credentials for callouts

### Examples

**❌ Score 0 - No security:**
```apex
public class AccountService {
    public List<Account> getAccounts() {
        return [SELECT Id, Name, AnnualRevenue FROM Account];
    }
}
```

**✅ Score 5 - Full security:**
```apex
public with sharing class AccountService {
    public List<Account> getAccounts() {
        // WITH USER_MODE enforces CRUD/FLS automatically
        return [SELECT Id, Name, AnnualRevenue FROM Account WITH USER_MODE];
    }

    public void updateAccounts(List<Account> accounts) {
        // Strip fields user can't access before DML
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            accounts
        );
        update decision.getRecords();
    }
}
```

## Category 2: Governor Limits (0-5 points)

### What to Look For

| Score | Criteria |
|-------|----------|
| 0 | SOQL and/or DML inside loops |
| 1 | SOQL in loop but DML outside |
| 2 | No SOQL/DML in loops but inefficient queries |
| 3 | Efficient queries, proper use of Maps/Sets |
| 4 | Fully optimized, uses SOQL for-loops for large data |
| 5 | Optimal patterns, considers CPU time, uses async when appropriate |

### Governor Limits Checklist

- [ ] **No SOQL in loops**: Query before loop, use `Map<Id, SObject>` for lookups
- [ ] **No DML in loops**: Collect records in List, DML once after loop
- [ ] **Efficient queries**: SELECT only needed fields, proper WHERE filters
- [ ] **Map-based lookups**: Use `Map<Id, SObject>` instead of nested loops
- [ ] **Consider row counts**: Filter to reduce `Limits.getQueryRows()` usage
- [ ] **CPU awareness**: Avoid string concatenation in loops, cache describe calls

### Examples

**❌ Score 0 - SOQL and DML in loops:**
```apex
// This will fail with 200 records!
for (Account acc : Trigger.new) {
    Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];  // SOQL in loop!
    c.Description = 'Updated';
    update c;  // DML in loop!
}
```

**✅ Score 5 - Optimal pattern:**
```apex
// Query all needed data upfront
Set<Id> accountIds = new Set<Id>();
for (Account acc : Trigger.new) {
    accountIds.add(acc.Id);
}

// Single query, indexed by AccountId for O(1) lookup
Map<Id, Contact> contactsByAccountId = new Map<Id, Contact>();
for (Contact c : [SELECT Id, AccountId, Description
                  FROM Contact
                  WHERE AccountId IN :accountIds]) {
    contactsByAccountId.put(c.AccountId, c);
}

// Collect updates
List<Contact> contactsToUpdate = new List<Contact>();
for (Account acc : Trigger.new) {
    Contact c = contactsByAccountId.get(acc.Id);
    if (c != null) {
        c.Description = 'Updated';
        contactsToUpdate.add(c);
    }
}

// Single DML operation
if (!contactsToUpdate.isEmpty()) {
    update contactsToUpdate;
}
```

## Category 3: Bulkification (0-5 points)

### What to Look For

| Score | Criteria |
|-------|----------|
| 0 | Only handles single record (Trigger.new[0]) |
| 1 | Loops through records but with issues |
| 2 | Handles multiple records but not efficiently |
| 3 | Proper bulk handling with collections |
| 4 | Full bulk handling, efficient collection use |
| 5 | Bulk handling with batch size awareness, graceful degradation |

### Bulkification Checklist

- [ ] **No Trigger.new[0]**: Always loop through entire list
- [ ] **Uses collections**: `List`, `Set`, `Map` for data organization
- [ ] **Handles empty lists**: Checks `.isEmpty()` before processing
- [ ] **Batch awareness**: Considers that triggers receive up to 200 records
- [ ] **No assumptions about size**: Works with 1 record or 200 records

### Examples

**❌ Score 0 - Single record only:**
```apex
trigger AccountTrigger on Account (before insert) {
    // WRONG: Only processes first record!
    Account acc = Trigger.new[0];
    acc.Description = 'Processed';
}
```

**✅ Score 5 - Full bulk handling:**
```apex
trigger AccountTrigger on Account (before insert) {
    // Processes ALL records
    for (Account acc : Trigger.new) {
        acc.Description = 'Processed';
    }
}

// In handler class:
public void handleBeforeInsert(List<Account> newAccounts) {
    if (newAccounts == null || newAccounts.isEmpty()) {
        return;  // Guard against empty input
    }

    for (Account acc : newAccounts) {
        // Process each record
        acc.Description = 'Processed';
    }
}
```

## Category 4: Patterns (0-5 points)

### What to Look For

| Score | Criteria |
|-------|----------|
| 0 | Logic directly in trigger body, no structure |
| 1 | Some separation but no clear pattern |
| 2 | Basic handler class but mixed concerns |
| 3 | Proper trigger handler pattern |
| 4 | Handler + service layer separation |
| 5 | Full separation: Handler → Service → Selector, proper naming |

### Patterns Checklist

- [ ] **Trigger handler**: Logic in handler class, not trigger body
- [ ] **Single trigger per object**: One trigger calls handler
- [ ] **Service layer**: Business logic in service classes
- [ ] **Selector layer**: Queries in selector classes (optional but good)
- [ ] **Naming conventions**: `AccountTriggerHandler`, `AccountService`, `AccountSelector`
- [ ] **Test coverage**: Each layer independently testable

### Trigger Handler Pattern

**Trigger (thin - just routes to handler):**
```apex
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    AccountTriggerHandler handler = new AccountTriggerHandler();
    handler.run();
}
```

**Handler (orchestrates logic):**
```apex
public class AccountTriggerHandler extends TriggerHandler {

    private List<Account> newAccounts;
    private Map<Id, Account> oldAccountsMap;

    public AccountTriggerHandler() {
        this.newAccounts = (List<Account>) Trigger.new;
        this.oldAccountsMap = (Map<Id, Account>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        AccountService.setDefaultValues(newAccounts);
    }

    public override void afterInsert() {
        AccountService.createRelatedRecords(newAccounts);
    }

    public override void beforeUpdate() {
        AccountService.validateChanges(newAccounts, oldAccountsMap);
    }
}
```

**Service (business logic):**
```apex
public with sharing class AccountService {

    public static void setDefaultValues(List<Account> accounts) {
        for (Account acc : accounts) {
            if (String.isBlank(acc.Industry)) {
                acc.Industry = 'Other';
            }
        }
    }

    public static void createRelatedRecords(List<Account> accounts) {
        // Business logic here
    }

    public static void validateChanges(List<Account> newAccounts, Map<Id, Account> oldMap) {
        // Validation logic here
    }
}
```

## Category 5: Completeness (0-5 points)

### What to Look For

| Score | Criteria |
|-------|----------|
| 0 | Incomplete, doesn't meet requirements |
| 1 | Basic functionality only |
| 2 | Meets main requirements, missing edge cases |
| 3 | Meets requirements with some error handling |
| 4 | Full requirements, edge cases, error handling |
| 5 | Production-ready: error handling, logging, documentation |

### Completeness Checklist

- [ ] **Requirements met**: Does it do what was asked?
- [ ] **Null checks**: Handles null inputs gracefully
- [ ] **Empty collections**: Checks `.isEmpty()` before processing
- [ ] **Error handling**: Try/catch with meaningful error messages
- [ ] **Edge cases**: Handles unusual but valid inputs
- [ ] **Documentation**: Class/method comments explaining purpose
- [ ] **Test coverage**: 75%+ code coverage with meaningful assertions

### Error Handling Example

```apex
public with sharing class AccountService {

    /**
     * Updates account ratings based on related opportunities.
     * @param accountIds Set of Account IDs to process
     * @return Results with success/failure counts
     * @throws AccountServiceException if validation fails
     */
    public static ProcessingResult updateAccountRatings(Set<Id> accountIds) {
        ProcessingResult result = new ProcessingResult();

        // Guard clause for null/empty input
        if (accountIds == null || accountIds.isEmpty()) {
            result.message = 'No accounts provided';
            return result;
        }

        try {
            // Query accounts with related opportunities
            List<Account> accounts = [
                SELECT Id, Name, Rating,
                    (SELECT Id, Amount, StageName FROM Opportunities WHERE IsClosed = false)
                FROM Account
                WHERE Id IN :accountIds
                WITH USER_MODE
            ];

            List<Account> accountsToUpdate = new List<Account>();

            for (Account acc : accounts) {
                try {
                    // Calculate new rating
                    String newRating = calculateRating(acc.Opportunities);
                    if (acc.Rating != newRating) {
                        acc.Rating = newRating;
                        accountsToUpdate.add(acc);
                    }
                    result.successCount++;
                } catch (Exception e) {
                    result.failureCount++;
                    result.errors.add('Account ' + acc.Name + ': ' + e.getMessage());
                }
            }

            // Bulk update with partial success
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] saveResults = Database.update(
                    Security.stripInaccessible(AccessType.UPDATABLE, accountsToUpdate).getRecords(),
                    false  // Allow partial success
                );

                for (Database.SaveResult sr : saveResults) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            result.errors.add(err.getMessage());
                        }
                    }
                }
            }

        } catch (Exception e) {
            result.message = 'Unexpected error: ' + e.getMessage();
            // Log for monitoring
            System.debug(LoggingLevel.ERROR, 'AccountService.updateAccountRatings: ' + e.getStackTraceString());
        }

        return result;
    }

    private static String calculateRating(List<Opportunity> opportunities) {
        if (opportunities == null || opportunities.isEmpty()) {
            return 'Cold';
        }

        Decimal totalAmount = 0;
        for (Opportunity opp : opportunities) {
            totalAmount += opp.Amount != null ? opp.Amount : 0;
        }

        if (totalAmount > 1000000) return 'Hot';
        if (totalAmount > 100000) return 'Warm';
        return 'Cold';
    }

    // Inner class for results
    public class ProcessingResult {
        public Integer successCount = 0;
        public Integer failureCount = 0;
        public String message;
        public List<String> errors = new List<String>();
    }
}
```

## Evaluation Workflow

### Step 1: Quick Scan
Look for immediate red flags:
- SOQL or DML inside `for` loops
- Missing `with sharing`
- `Trigger.new[0]` instead of looping
- Hardcoded IDs
- Missing null checks

### Step 2: Score Each Category
Use the rubric tables above to assign 0-5 for each category.

### Step 3: Calculate Total
Add up the five scores for a total out of 25.

### Step 4: Determine Quality Level

| Score | Quality Level | Action |
|-------|---------------|--------|
| 0-10 | Poor | Major refactoring needed |
| 11-15 | Below Average | Significant improvements needed |
| 16-18 | Average | Good foundation, some improvements |
| 19-22 | Good | Minor improvements, code review ready |
| 23-25 | Excellent | Production ready |

### Step 5: Document Findings
Create a report with:
- Overall score and level
- Per-category scores with reasons
- Specific code lines that need attention
- Recommended fixes with examples

## Evaluation Report Template

```markdown
## Code Evaluation Report

**File(s) Reviewed**: `AccountTriggerHandler.cls`, `AccountService.cls`
**Reviewer**: [Name]
**Date**: [Date]

### Overall Score: X/25 (Quality Level)

### Category Scores

| Category | Score | Reason |
|----------|-------|--------|
| Security | X/5 | [Specific findings] |
| Governor Limits | X/5 | [Specific findings] |
| Bulkification | X/5 | [Specific findings] |
| Patterns | X/5 | [Specific findings] |
| Completeness | X/5 | [Specific findings] |

### Issues Found

1. **[Category]** - Line XX: [Description]
   - Current: `[code snippet]`
   - Recommended: `[fixed code]`

2. **[Category]** - Line XX: [Description]
   - Current: `[code snippet]`
   - Recommended: `[fixed code]`

### Summary
[Brief summary of findings and priority fixes]
```

## Common Issues by Experience Level

### Junior Developer Common Issues
1. **SOQL in loops** - Most common governor limit violation
2. **Missing `with sharing`** - Security vulnerability
3. **Logic in trigger body** - Hard to test and maintain
4. **Trigger.new[0]** - Only handles first record
5. **Missing null checks** - NullPointerException in production

### Mid-Level Developer Common Issues
1. **Inconsistent error handling** - Some paths handled, others not
2. **Partial security** - CRUD on read but not write
3. **Mixed concerns** - Services doing too much
4. **Inefficient queries** - SELECT * equivalent, missing filters

### Senior Developer Watch Items
1. **Over-engineering** - Too many abstraction layers
2. **Performance edge cases** - Works at small scale, fails at large
3. **Security in dynamic code** - SOQL injection in advanced patterns
4. **Async chaining limits** - Complex job chains hitting limits

## Quick Reference: Code Smells

| Code Smell | Category | Fix |
|------------|----------|-----|
| `public class` without sharing | Security | Add `with sharing` |
| `[SELECT * FROM...]` (all fields) | Limits | Select only needed fields |
| SOQL inside `for` loop | Limits | Query before loop, use Map |
| DML inside `for` loop | Limits | Collect records, DML after loop |
| `Trigger.new[0]` | Bulkification | Loop through entire list |
| String concatenation in loop | Limits | Use List and String.join() |
| Nested `for` loops over collections | Limits | Use Map-based lookups |
| Hardcoded Id | Security | Use Custom Metadata |
| No try/catch on callouts | Completeness | Add error handling |
| Logic in trigger body | Patterns | Use trigger handler pattern |
