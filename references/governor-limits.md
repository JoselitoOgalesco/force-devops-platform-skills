# Salesforce Governor Limits Reference (API v62.0)

Salesforce enforces strict per-transaction limits. Violating these causes runtime exceptions that cannot be caught.

## Per-Transaction Limits (Synchronous)

| Limit | Value | Notes |
|-------|-------|-------|
| SOQL queries | 100 | Includes queries in all Apex code for the transaction |
| SOQL query rows returned | 50,000 | Total across all queries |
| SOQL relationship queries (child subqueries) | 20 | Per parent query |
| Subquery rows per parent | 2,000 | Limits child rows per parent record |
| DML statements | 150 | insert, update, delete, upsert, merge, undelete |
| DML rows | 10,000 | Total records across all DML operations |
| Heap size | 6 MB | Memory for objects, strings, collections |
| CPU time | 10,000 ms | Execution time (not wall clock) |
| Callouts (HTTP/SOAP) | 100 | Includes all external requests |
| Single callout timeout | 120 seconds | Per callout |
| Total callout timeout | 120 seconds | All callouts combined |
| Future calls | 50 | `@future` method invocations |
| Queueable jobs | 50 | `System.enqueueJob()` calls |
| Email invocations | 10 | `Messaging.sendEmail()` calls |
| Push notifications | 10 | Mobile push notifications |
| Event publish (immediate) | 150 | `EventBus.publish()` calls |
| SOSL queries | 20 | Search queries |

## Per-Transaction Limits (Asynchronous)

Asynchronous contexts (Batch, Future, Queueable) get higher limits:

| Limit | Value | Notes |
|-------|-------|-------|
| SOQL queries | 200 | 2x synchronous limit |
| SOQL query rows | 50,000 | Same as sync |
| DML statements | 150 | Same as sync |
| DML rows | 10,000 | Same as sync |
| Heap size | 12 MB | 2x synchronous limit |
| CPU time | 60,000 ms | 6x synchronous limit |
| Callouts | 100 | Same as sync |

## Batch Apex Limits

| Limit | Value | Notes |
|-------|-------|-------|
| Batch size (default) | 200 | Records per `execute()` call |
| Batch size (max) | 2,000 | Set via `Database.executeBatch(job, size)` |
| Active batch jobs | 5 | Concurrent executing batches per org |
| Flex queue | 100 | Jobs waiting to execute |
| QueryLocator rows | 50,000,000 | Total records for batch processing |

## SOQL Limits

| Limit | Value | Notes |
|-------|-------|-------|
| WHERE clause length | 4,000 chars | Maximum characters |
| OFFSET max | 2,000 | Maximum offset value |
| SOQL for loops batch | 200 | Records per iteration |
| Long text fields | Not searchable | Cannot query LongTextArea content |

## Platform Event Limits

| Limit | Value | Notes |
|-------|-------|-------|
| Standard event publish | 50,000/hour | Per org |
| High-volume event publish | 150,000/hour | Per org |
| Event delivery | At-least-once | Not exactly-once |
| Replay window (standard) | 24 hours | Event retention |
| Replay window (high-volume) | 72 hours | Event retention |

## Scheduled Apex Limits

| Limit | Value | Notes |
|-------|-------|-------|
| Scheduled jobs | 100 | Per org |
| Scheduled Apex jobs | 100 | Using `System.schedule()` |
| Minimum interval | 1 minute | Between scheduled executions |

## Daily Limits

| Limit | Value | Notes |
|-------|-------|-------|
| Email (single) | 5,000 | Per org per day |
| Email (mass) | Varies by edition | Check Setup > Email Settings |
| API calls | Based on license count | Check Setup > System Overview |
| Async Apex executions | 250,000 or (license count × 200) | Whichever is greater |
| Bulk API batches | 15,000 | Per 24-hour rolling period |
| Bulk API records | 150,000,000 | Per 24-hour rolling period |

## Monitoring Limits in Code

```apex
// Check SOQL usage
System.debug('SOQL queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());

// Check DML usage
System.debug('DML statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
System.debug('DML rows: ' + Limits.getDmlRows() + '/' + Limits.getLimitDmlRows());

// Check CPU time
System.debug('CPU time (ms): ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());

// Check heap size
System.debug('Heap size (bytes): ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());

// Check query rows
System.debug('Query rows: ' + Limits.getQueryRows() + '/' + Limits.getLimitQueryRows());

// Check callouts
System.debug('Callouts: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts());

// Check future calls
System.debug('Future calls: ' + Limits.getFutureCalls() + '/' + Limits.getLimitFutureCalls());

// Check queueable jobs
System.debug('Queueable jobs: ' + Limits.getQueueableJobs() + '/' + Limits.getLimitQueueableJobs());
```

## Common Limit Violations and Solutions

### SOQL Queries (100 limit)

**Problem:** Query inside a loop

```apex
// BAD — SOQL inside loop
for (Account acc : accounts) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}
```

**Solution:** Collect IDs, query once

```apex
// GOOD — Bulkified query
Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
Map<Id, List<Contact>> contactsByAccount = new Map<Id, List<Contact>>();
for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    if (!contactsByAccount.containsKey(c.AccountId)) {
        contactsByAccount.put(c.AccountId, new List<Contact>());
    }
    contactsByAccount.get(c.AccountId).add(c);
}
```

### DML Statements (150 limit)

**Problem:** DML inside a loop

```apex
// BAD — DML inside loop
for (Account acc : accounts) {
    acc.Status__c = 'Processed';
    update acc;
}
```

**Solution:** Collect records, single DML

```apex
// GOOD — Bulkified DML
for (Account acc : accounts) {
    acc.Status__c = 'Processed';
}
update accounts;
```

### Heap Size (6 MB limit)

**Problem:** Large collections or strings in memory

**Solutions:**
- Use `Database.QueryLocator` for large datasets in Batch
- Process data in smaller chunks
- Avoid string concatenation in loops (use StringBuilder pattern)
- Clear collections when no longer needed

### CPU Time (10,000 ms limit)

**Problem:** Complex processing or inefficient algorithms

**Solutions:**
- Move complex processing to async (Batch/Queueable gets 60,000 ms)
- Optimize algorithms (avoid nested loops, use Maps)
- Cache expensive calculations
- Use SOQL aggregate functions instead of Apex loops

### Query Rows (50,000 limit)

**Problem:** Querying too many records

**Solutions:**
- Add selective WHERE clauses
- Use LIMIT clause
- Use Batch Apex for large dataset processing
- Consider narrowing query scope

## When to Use Async Processing

| Use Case | Async Type | Why |
|----------|-----------|-----|
| > 50,000 records | Batch | QueryLocator handles 50M records |
| Complex callouts | @future/Queueable | Separate from UI transaction |
| Chained processing | Queueable | Supports job chaining |
| Scheduled processing | Schedulable | Time-based execution |
| Near real-time processing | Platform Events | Decoupled execution |

## Important Notes

1. **Limits are per transaction, not per class** — all code in a trigger execution shares limits
2. **Test methods have same limits** — but `Test.startTest()/stopTest()` resets context
3. **Async jobs have separate limits** — each gets its own transaction
4. **Mixed DML requires separation** — setup objects (User, Group) separate from regular objects
5. **Trigger recursion shares limits** — re-entry doesn't reset limits
6. **Platform Events run in new transaction** — subscribers get fresh limits