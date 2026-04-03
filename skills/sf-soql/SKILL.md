---
name: sf-soql
description: Build and optimize SOQL/SOSL queries with security and performance best practices.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, soql, sosl, queries, optimization
---

# SOQL Query Builder & Optimizer

Build optimized, secure SOQL queries.

## Security First
**ALWAYS** use `WITH USER_MODE` to enforce CRUD/FLS.
**NEVER** use string concatenation for dynamic SOQL — use bind variables.

```apex
// GOOD — secure pattern
List<Account> accounts = [
    SELECT Id, Name, Industry
    FROM Account
    WHERE Industry = :industryFilter
    WITH USER_MODE
    LIMIT 200
];

// BAD — injection risk!
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';
```

## Query Patterns

### Parent-to-Child (Subquery)
```sql
SELECT Id, Name,
    (SELECT Id, FirstName, LastName FROM Contacts)
FROM Account
WHERE Industry = 'Technology'
WITH USER_MODE
```

### Child-to-Parent (Dot Notation)
```sql
SELECT Id, FirstName, Account.Name, Account.Industry
FROM Contact
WHERE Account.Industry = 'Technology'
WITH USER_MODE
```

### Aggregate Queries
```sql
SELECT Industry, COUNT(Id) cnt, SUM(AnnualRevenue) totalRevenue
FROM Account
WHERE Industry != null
WITH USER_MODE
GROUP BY Industry
HAVING COUNT(Id) > 5
ORDER BY COUNT(Id) DESC
```

### Polymorphic (TYPEOF)
```sql
SELECT Id, Subject,
    TYPEOF What
        WHEN Account THEN Name, Industry
        WHEN Opportunity THEN Name, StageName, Amount
    END
FROM Task
WITH USER_MODE
```

### Semi-Joins and Anti-Joins
```sql
-- Semi-join: Accounts WITH contacts
SELECT Id, Name FROM Account
WHERE Id IN (SELECT AccountId FROM Contact)
WITH USER_MODE

-- Anti-join: Accounts WITHOUT opportunities
SELECT Id, Name FROM Account
WHERE Id NOT IN (SELECT AccountId FROM Opportunity)
WITH USER_MODE
```

## SOSL (Search Language)
Use SOSL for full-text search across multiple objects:
```sql
FIND {SearchTerm} IN ALL FIELDS
RETURNING Account(Id, Name WHERE Industry = 'Tech'),
          Contact(Id, FirstName, LastName)
LIMIT 20
```

| Use SOSL When | Use SOQL When |
|---------------|---------------|
| Searching text across objects | Exact matches |
| Fuzzy matching | Relationship queries |
| Partial words | Aggregates |
| | DML-related queries |

Governor limit: 20 SOSL queries per transaction.

## Date Literals

| Literal | Meaning |
|---------|---------|
| `TODAY`, `YESTERDAY`, `TOMORROW` | Calendar day |
| `THIS_WEEK`, `LAST_WEEK`, `NEXT_WEEK` | Sun-Sat week |
| `THIS_MONTH`, `LAST_MONTH`, `NEXT_MONTH` | Calendar month |
| `THIS_QUARTER`, `LAST_QUARTER` | Calendar quarter |
| `THIS_YEAR`, `LAST_YEAR`, `NEXT_YEAR` | Calendar year |
| `LAST_N_DAYS:n` | Past n days (includes today) |
| `NEXT_N_DAYS:n` | Next n days (includes today) |
| `LAST_90_DAYS` | Past 90 days |
| `THIS_FISCAL_QUARTER`, `THIS_FISCAL_YEAR` | Fiscal periods |
| `N_DAYS_AGO:n` | Exactly n days ago |

## FIELDS() Functions
```sql
SELECT FIELDS(ALL) FROM Account LIMIT 200    -- All fields (LIMIT required!)
SELECT FIELDS(STANDARD) FROM Account          -- Standard fields only
SELECT FIELDS(CUSTOM) FROM Account            -- Custom fields only
```

## Dynamic SOQL
```apex
String query = 'SELECT Id, Name FROM Account WHERE Industry = :industry';
List<Account> results = Database.query(query, AccessLevel.USER_MODE);
```

- Always use `AccessLevel.USER_MODE` with `Database.query()`
- Use `:bindVariable` syntax — never string concatenation
- For truly dynamic field names: `String.escapeSingleQuotes()`

## Utility Functions

| Function | Purpose |
|----------|---------|
| `toLabel(PicklistField)` | Returns translated picklist label |
| `FORMAT(NumberField)` | Locale-formatted number/date |
| `convertCurrency(Amount)` | Converts to user's currency (multi-currency orgs) |

## Record Locking
```sql
SELECT Id, Name FROM Account WHERE Id = :accountId FOR UPDATE
```
Pessimistic lock — blocks other transactions from updating until commit/rollback.

## ALL ROWS (Including Deleted)
```sql
SELECT Id, Name FROM Account WHERE IsDeleted = true ALL ROWS
```
Use in Apex tests to query deleted records or for data recovery.

## Performance Tips

| Tip | Why |
|-----|-----|
| Index fields used in WHERE/ORDER BY | Faster query execution |
| Avoid leading wildcards in LIKE | `%value` can't use index |
| Use selective filters (< 30% of records) | Index optimization |
| Prefer relationship queries | Fewer SOQL calls |
| Max 20 child subqueries | Hard limit |
| Use `LIMIT` on large result sets | Prevent heap issues |
| Use SOQL for-loops for large datasets | Chunked processing |

## SOQL For-Loops (Large Datasets)
```apex
// Process in chunks of 200 automatically
for (List<Account> accounts : [SELECT Id, Name FROM Account]) {
    // accounts contains up to 200 records per iteration
    // avoids heap size limits
}
```

## Geolocation Queries

```sql
SELECT Id, Name,
       DISTANCE(Location__c, GEOLOCATION(37.7749, -122.4194), 'mi') dist
FROM Store__c
WHERE DISTANCE(Location__c, GEOLOCATION(37.7749, -122.4194), 'mi') < 50
ORDER BY DISTANCE(Location__c, GEOLOCATION(37.7749, -122.4194), 'mi')
WITH USER_MODE
```

**Units:** `'mi'` (miles) or `'km'` (kilometers)

## Security Enforcement Options

| Feature | SECURITY_ENFORCED | USER_MODE |
|---------|-------------------|-----------|
| FLS enforcement | SELECT/FROM only | SELECT/FROM/WHERE/subqueries |
| On violation | Throws exception | Silently strips inaccessible fields |
| Restriction rules | Not supported | Supported |
| Recommendation | Legacy — migrate away | **Preferred** |

**💡 Junior Developer Rule:** Always use `WITH USER_MODE` for new development.

## Query Plan Analysis

Check if your query is selective (uses indexes):

```bash
# Get query explain plan
sf data query -q "SELECT Id FROM Account WHERE Name = 'Test'" --explain --target-org myOrg
```

**What makes a query selective?**
- Indexed fields: `Id`, `Name`, `OwnerId`, `CreatedDate`, `SystemModstamp`
- Any lookup/master-detail field
- Fields marked as `External ID`
- Custom indexes (request from Salesforce support)

## Governor Limits Quick Reference

| Limit | Synchronous | Asynchronous |
|-------|-------------|--------------|
| SOQL queries | 100 | 200 |
| Rows returned | 50,000 | 50,000 |
| SOSL queries | 20 | 20 |
| Subquery rows | 2,000 | 2,000 |
| Relationship queries per parent | 20 | 20 |

## Gotchas

| Issue | What Happens | Fix |
|-------|--------------|-----|
| `FIELDS(ALL)` without LIMIT | Query fails | Add `LIMIT 200` or less |
| Subquery > 200 rows | Silently truncated | Query children separately |
| Non-aggregated field in GROUP BY | Query error | Add to GROUP BY or remove |
| `FOR UPDATE` with aggregate | Query error | Remove FOR UPDATE |
| Bind variable in IN > 4000 IDs | Query fails | Chunk into smaller queries |
| `FIELDS(ALL)` in Apex | Throws exception | Only works in REST API/Dev Console |
| `TYPEOF` on non-polymorphic field | Query error | Only use on WhoId, WhatId, etc. |
| Leading wildcard `%value` | Full table scan | Use trailing wildcard `value%` |
| Negative operators (`!=`, `NOT IN`) | Non-selective | Combine with selective filter |
| `ALL ROWS` with `FOR UPDATE` | Query error | Can't combine |
| Date literals include boundary | Off-by-one errors | `LAST_N_DAYS:7` includes today |
| `COUNT()` vs `COUNT(field)` | Different results | `COUNT()` includes nulls |

## Common Mistakes (Junior Developer Guide)

### Mistake 1: Query in Loop
```apex
// ❌ BAD — hits limit with 100+ accounts
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}

// ✅ GOOD — single query, use Map
Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    if (!contactsByAccount.containsKey(c.AccountId)) {
        contactsByAccount.put(c.AccountId, new List<Contact>());
    }
    contactsByAccount.get(c.AccountId).add(c);
}
```

### Mistake 2: Missing WHERE Clause
```apex
// ❌ BAD — returns ALL accounts (could be millions)
List<Account> accounts = [SELECT Id, Name FROM Account];

// ✅ GOOD — filtered and limited
List<Account> accounts = [SELECT Id, Name FROM Account WHERE Industry = :industry LIMIT 200];
```

### Mistake 3: String Concatenation (SQL Injection)
```apex
// ❌ BAD — vulnerable to injection
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';

// ✅ GOOD — bind variable
String query = 'SELECT Id FROM Account WHERE Name = :userInput';
List<Account> result = Database.query(query, AccessLevel.USER_MODE);
```

### Mistake 4: Missing Security Enforcement
```apex
// ❌ BAD — no CRUD/FLS enforcement
List<Account> accounts = [SELECT Id, Name, SSN__c FROM Account];

// ✅ GOOD — enforces user's access
List<Account> accounts = [SELECT Id, Name, SSN__c FROM Account WITH USER_MODE];
```
