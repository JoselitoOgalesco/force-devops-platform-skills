---
name: sf-debug
description: |
  Debug and troubleshoot Salesforce applications using debug logs, governor limit
  monitoring, error diagnosis, and performance profiling. Use when analyzing debug
  logs, diagnosing governor limit violations, interpreting stack traces, resolving
  common Salesforce errors, or profiling Apex performance.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, debug, troubleshooting, governor-limits, error-diagnosis, performance
---

# Salesforce Debug & Troubleshooting Guide

This guide helps you diagnose issues from debug logs, governor limit violations, exceptions, and performance bottlenecks. Written for developers who need to understand what's happening inside Salesforce when things go wrong.

## Understanding Salesforce Debugging

**Why debugging in Salesforce is different:**
- Salesforce is a multi-tenant platform with strict resource limits (governor limits)
- You can't attach a traditional debugger — you rely on debug logs
- Transactions can involve triggers, flows, validation rules, and workflows firing in a specific order
- Understanding the order of execution is critical to finding root causes

## 1. Debug Log Analysis

### What Are Debug Logs?

Debug logs are text files that record everything that happens during a Salesforce transaction. They capture:
- Apex code execution (your classes, triggers, and methods)
- SOQL queries and their results
- DML operations (insert, update, delete)
- System events and errors
- Governor limit consumption

### Log Levels (from most to least verbose)

| Level | Use Case | When to Use |
|-------|----------|-------------|
| FINEST | Full trace — variable values, internal framework calls | Hunting elusive bugs, understanding framework behavior |
| FINER | Detailed flow — method entries/exits with parameters | Following method calls through your code |
| FINE | Key decision points and loop iterations | Most debugging scenarios |
| DEBUG | General diagnostic information | Normal development |
| INFO | High-level transaction milestones | Production monitoring |
| WARN | Recoverable issues that may indicate problems | Identifying potential problems |
| ERROR | Failures requiring immediate attention | Critical error tracking |

**💡 Junior Developer Tip:** Start with DEBUG level. Only increase to FINE/FINER if you need more detail. FINEST generates huge logs that are hard to read.

### Log Categories

Each category controls what gets captured:

| Category | What It Captures | When to Increase |
|----------|-----------------|------------------|
| `Apex_code` | Apex execution, System.debug() output, variable assignments | Debugging Apex logic |
| `Apex_profiling` | Cumulative resource usage — SOQL, DML, CPU, heap | Performance issues, limit violations |
| `Database` | SOQL queries, DML operations, query plans, row counts | Query performance, data issues |
| `System` | System methods, platform events, formula evaluations | System behavior investigation |
| `Validation` | Validation rules, workflow field updates | Why records fail to save |
| `Workflow` | Workflow rules, process builder, flow executions | Automation debugging |
| `Callout` | HTTP callouts, SOAP calls, external service responses | Integration issues |
| `Visualforce` | VF page rendering, view state, controller actions | Visualforce page issues |
| `NBA` | Next Best Action strategy execution | Einstein NBA debugging |

### Reading Debug Logs — Key Line Prefixes

When reading a debug log, look for these prefixes:

```
EXECUTION_STARTED / EXECUTION_FINISHED  — Transaction start/end (the outer boundary)
CODE_UNIT_STARTED / CODE_UNIT_FINISHED  — Trigger, class, or method execution
SOQL_EXECUTE_BEGIN / SOQL_EXECUTE_END   — Query with row count
DML_BEGIN / DML_END                      — DML operation with row count
EXCEPTION_THROWN                         — Exception type and message
FATAL_ERROR                              — Unrecoverable error with stack trace
HEAP_ALLOCATE                            — Heap memory allocation
LIMIT_USAGE_FOR_NS                       — Governor limit summary per namespace
CUMULATIVE_LIMIT_USAGE                   — End-of-transaction limit summary
USER_DEBUG                               — Your System.debug() output
VARIABLE_SCOPE_BEGIN / VARIABLE_ASSIGNMENT — Variable tracking (FINEST only)
METHOD_ENTRY / METHOD_EXIT               — Method call tracking (FINER+)
FLOW_START_INTERVIEWS                    — Flow/process builder execution
VALIDATION_RULE                          — Validation rule evaluation
CALLOUT_REQUEST / CALLOUT_RESPONSE       — External HTTP calls
```

**💡 Quick Tip:** Search for `EXCEPTION_THROWN` or `FATAL_ERROR` first — these show where things went wrong.

### Understanding Log Structure

A debug log follows this execution sequence:

```
1. EXECUTION_STARTED              — Transaction begins
2. CODE_UNIT_STARTED              — Trigger or entry point fires
3. Before-trigger logic           — Field validation, default values
4. VALIDATION_RULE                — Validation rules execute
5. DML execution                  — Record actually saved
6. After-trigger logic            — After triggers fire
7. FLOW_START_INTERVIEWS          — Workflow rules, flows execute
8. (Re-evaluation of triggers)    — If workflow causes field updates
9. Commit or rollback
10. CUMULATIVE_LIMIT_USAGE        — Final governor limit summary
11. EXECUTION_FINISHED            — Transaction ends
```

**Why this matters:** If your after-trigger fails, it might be because a workflow changed a field, causing your trigger to run again. Understanding this order helps you find root causes.

## 2. Debug Log CLI Commands

### Tail Logs in Real Time

```bash
# Stream logs as they are generated (colored output)
# This is the most useful command for debugging — watch logs as you test
sf apex tail log --target-org myOrg --color

# Tail with specific log level
sf apex tail log --target-org myOrg --debug-level MyDebugLevel
```

### List and Retrieve Logs

```bash
# List recent debug logs
sf apex log list --target-org myOrg --json

# Get a specific log by ID
sf apex log get --log-id 07Lxxxxxxxxxxxxxxx --target-org myOrg

# Get the most recent log
sf apex log get --number 1 --target-org myOrg

# Get logs and save to file for analysis
sf apex log get --log-id 07Lxxxxxxxxxxxxxxx --target-org myOrg > debug.log
```

### Run Apex with Debug Output

```bash
# Execute anonymous Apex and capture output
sf apex run --target-org myOrg --file scripts/debug-script.apex

# Run inline Apex for quick debugging
echo "System.debug(Limits.getQueries());" | sf apex run --target-org myOrg
```

### Delete Old Logs

```bash
# Clean up old logs to free storage
sf apex log list --target-org myOrg --json | \
  sf data delete bulk --sobject ApexLog --file -
```

## 3. Governor Limit Monitoring

### What Are Governor Limits?

Governor limits prevent any single tenant from monopolizing shared resources. They're enforced per transaction. Understanding these limits is essential for Salesforce development.

### Limits Class Methods — Check Before Hitting Walls

```apex
// SOQL queries — Check if you're approaching 100
System.debug('SOQL queries: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());

// DML statements — Check if you're approaching 150
System.debug('DML statements: ' + Limits.getDmlStatements() + ' / ' + Limits.getLimitDmlStatements());

// DML rows — Check if you're approaching 10,000
System.debug('DML rows: ' + Limits.getDmlRows() + ' / ' + Limits.getLimitDmlRows());

// CPU time — Check if you're approaching 10,000ms (sync)
System.debug('CPU time (ms): ' + Limits.getCpuTime() + ' / ' + Limits.getLimitCpuTime());

// Heap size — Check if you're approaching 6MB
System.debug('Heap size (bytes): ' + Limits.getHeapSize() + ' / ' + Limits.getLimitHeapSize());

// Query rows — Check if you're approaching 50,000
System.debug('Query rows: ' + Limits.getQueryRows() + ' / ' + Limits.getLimitQueryRows());

// Callouts — Check if you're approaching 100
System.debug('Callouts: ' + Limits.getCallouts() + ' / ' + Limits.getLimitCallouts());

// Future calls — Check if you're approaching 50
System.debug('Future calls: ' + Limits.getFutureCalls() + ' / ' + Limits.getLimitFutureCalls());

// Queueable jobs — Check if you're approaching 50
System.debug('Queueable jobs: ' + Limits.getQueueableJobs() + ' / ' + Limits.getLimitQueueableJobs());
```

### When to Check Limits

✅ **Do check limits:**
- **Before expensive operations** — query or DML in a loop you cannot refactor immediately
- **After processing batches** — at the end of each batch in `Database.Batchable.execute()`
- **In utility/service classes** — log limits at entry and exit for profiling
- **In catch blocks** — when a LimitException might be approaching

❌ **Don't check limits:**
- **In tight loops** — `Limits.*()` calls themselves consume CPU

### Sync vs Async Limits

| Resource | Synchronous | Asynchronous | Notes |
|----------|-------------|--------------|-------|
| SOQL queries | 100 | 200 | Double for async |
| DML statements | 150 | 150 | Same for both |
| CPU time | 10,000 ms | 60,000 ms | 6x for async |
| Heap size | 6 MB | 12 MB | Double for async |
| Query rows | 50,000 | 50,000 | Same for both |
| Callouts | 100 | 100 | Same for both |
| DML rows | 10,000 | 10,000 | Same for both |

**💡 Why async has higher limits:** Async jobs run in the background when the platform has spare capacity, so it can afford to give them more resources.

## 4. Common Error Diagnosis

### Error Reference Table

| Error | Likely Cause | How to Fix | Example Fix |
|-------|-------------|------------|-------------|
| `UNABLE_TO_LOCK_ROW` | Concurrent updates on same record or parent record in master-detail | Retry with `FOR UPDATE`, reduce batch scope, use async processing | Use Queueable for processing |
| `ENTITY_IS_DELETED` | DML on a record deleted earlier in transaction or by another user | Check `isDeleted` before DML, handle concurrency with try/catch | `if(!record.isDeleted) { update record; }` |
| `FIELD_CUSTOM_VALIDATION_EXCEPTION` | Validation rule failure | Check validation rules on the object, use `Database.insert(records, false)` for partial success | Review validation rule criteria |
| `INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY` | Missing access to a related record (lookup/master-detail parent, owner, queue) | Verify sharing rules, check OWD, ensure running user has access | Review sharing settings |
| `MIXED_DML_OPERATION` | DML on setup object (User, Group) and non-setup object in same transaction | Move one DML to `@future`, use `System.runAs()` in tests | See code example below |
| `System.LimitException: Too many SOQL queries` | More than 100 SOQL queries in synchronous transaction | Move queries out of loops, use collections and Maps for lookups | See bulkification patterns |
| `System.LimitException: Too many DML statements` | More than 150 DML statements in transaction | Collect records into Lists, perform bulk DML outside loops | See bulkification patterns |
| `System.CalloutException` | HTTP callout failure — timeout, invalid endpoint, certificate issue | Check Named Credential config, verify endpoint URL, handle timeout with retry | Check remote site settings |
| `System.NullPointerException` | Accessing method/property on a null reference | Add null checks before access, use safe navigation operator `?.` | `account?.Name` |
| `System.QueryException: List has no rows` | Query assigned to single variable returned no rows | Use `List<SObject>` and check `.isEmpty()`, or wrap in try/catch | `List<Account> accts = [SELECT...]; if(!accts.isEmpty())...` |
| `System.QueryException: List has more than 1 row` | Query assigned to single variable returned multiple rows | Add `LIMIT 1` or use `List<SObject>`, investigate data for duplicates | `Account acc = [SELECT... LIMIT 1];` |
| `CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY` | Trigger recursion or cascading trigger failure | Implement static recursion guard, check trigger handler framework | See recursion guard pattern below |
| `System.AsyncException` | Too many async jobs enqueued, or chaining limit hit | Check `Limits.getQueueableJobs()`, use `Finalizer` for batch chaining, limit enqueue to 1 per Queueable | Use Finalizer pattern |
| `System.SerializationException` | Unserializable object in Queueable or Platform Event | Remove transient references, avoid SObject types with relationship fields in serialized state | Pass IDs instead of records |
| `STRING_TOO_LONG` | Field value exceeds maximum length | Validate or truncate with `.abbreviate(maxLength)` before DML | `myString.abbreviate(255)` |

### MIXED_DML_OPERATION Fix

```apex
// ❌ WRONG: This causes MIXED_DML_OPERATION
Account acc = new Account(Name = 'Test');
insert acc;
User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
u.FirstName = 'Updated';
update u;  // ERROR: Can't DML setup object after non-setup object

// ✅ FIX: Use @future for setup object DML
public class UserUpdateHelper {
    @future
    public static void updateUserFirstName(Id userId, String firstName) {
        User u = [SELECT Id, FirstName FROM User WHERE Id = :userId];
        u.FirstName = firstName;
        update u;
    }
}
// Then call: UserUpdateHelper.updateUserFirstName(UserInfo.getUserId(), 'Updated');
```

### Recursion Guard Pattern

```apex
// Create a utility class to prevent trigger recursion
public class TriggerRecursionGuard {
    private static Set<Id> processedIds = new Set<Id>();

    public static Boolean hasProcessed(Id recordId) {
        return processedIds.contains(recordId);
    }

    public static void markProcessed(Id recordId) {
        processedIds.add(recordId);
    }

    public static void reset() {
        processedIds.clear();
    }
}

// In your trigger handler:
public void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
    List<Account> toProcess = new List<Account>();
    for (Account acc : newAccounts) {
        if (!TriggerRecursionGuard.hasProcessed(acc.Id)) {
            toProcess.add(acc);
            TriggerRecursionGuard.markProcessed(acc.Id);
        }
    }
    // Process only non-recursed records
    if (!toProcess.isEmpty()) {
        processAccounts(toProcess);
    }
}
```

### Error Diagnosis Workflow

Follow this step-by-step process:

1. **Read the full error message** — Salesforce errors follow `STATUS_CODE: message` format
2. **Find the originating line** — Look for `Class.MethodName: line X, column Y` in stack trace
3. **Identify the trigger context** — Is this before/after insert/update? Check `CODE_UNIT_STARTED` in logs
4. **Check for cascading failures** — One trigger failure can cause `CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY` in a parent trigger
5. **Reproduce with minimal data** — Use Execute Anonymous or a focused test method
6. **Check governor limits** — Look at `CUMULATIVE_LIMIT_USAGE` at end of log

## 5. Checkpoints & Developer Console Debugging

### Execute Anonymous Debugging

Use Execute Anonymous for targeted investigation:

```apex
// Reproduce an issue with specific data
Account testAcc = [SELECT Id, Name, Industry FROM Account WHERE Id = '001xxxxxxxxxxxx'];
System.debug('Account state: ' + JSON.serializePretty(testAcc));

// Test a specific method in isolation
MyService service = new MyService();
try {
    service.processRecord(testAcc);
    System.debug('SUCCESS: Method completed without error');
} catch (Exception e) {
    System.debug('FAILED: ' + e.getTypeName() + ' - ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// Check governor limits after operation
System.debug('Post-execution SOQL: ' + Limits.getQueries());
System.debug('Post-execution DML: ' + Limits.getDmlStatements());
System.debug('Post-execution CPU: ' + Limits.getCpuTime() + 'ms');
```

### Checkpoints (Developer Console)

Checkpoints capture the state of memory at a specific line of code:

- Set checkpoints on specific lines in Developer Console
- Maximum **5 checkpoints** active at a time
- Checkpoints expire after **30 minutes**
- Results appear in the **Checkpoint Inspector** tab
- Use checkpoints when `System.debug()` is insufficient — they capture the full object graph

**How to use checkpoints:**
1. Open Developer Console
2. Open your class file
3. Click in the margin next to a line number to set a checkpoint (red dot appears)
4. Execute your code (run test, trigger action, etc.)
5. Go to Checkpoint Inspector tab to see variable values at that moment

### Quick Debug Scripts

```apex
// Check current user's permissions
System.debug('Profile: ' + UserInfo.getProfileId());
System.debug('User: ' + UserInfo.getUserId());
System.debug('User Name: ' + UserInfo.getName());

// Check object accessibility
Schema.DescribeSObjectResult describe = Account.SObjectType.getDescribe();
System.debug('Object Accessible: ' + describe.isAccessible());
System.debug('Object Createable: ' + describe.isCreateable());
System.debug('Object Updateable: ' + describe.isUpdateable());
System.debug('Object Deleteable: ' + describe.isDeletable());

// Check field accessibility
Schema.DescribeFieldResult fieldDescribe = Account.Industry.getDescribe();
System.debug('Field readable: ' + fieldDescribe.isAccessible());
System.debug('Field writable: ' + fieldDescribe.isUpdateable());
System.debug('Field createable: ' + fieldDescribe.isCreateable());

// Check all fields on an object
Map<String, Schema.SObjectField> fields = Account.SObjectType.getDescribe().fields.getMap();
for (String fieldName : fields.keySet()) {
    Schema.DescribeFieldResult f = fields.get(fieldName).getDescribe();
    System.debug(fieldName + ': readable=' + f.isAccessible() + ', writable=' + f.isUpdateable());
}
```

## 6. Performance Profiling

### Identifying CPU Bottlenecks

Look for these patterns in debug logs:
- `METHOD_ENTRY` / `METHOD_EXIT` — calculate time between pairs
- High `CUMULATIVE_LIMIT_USAGE` CPU time relative to the operation size
- `HEAP_ALLOCATE` in large amounts inside loops

### Common Performance Anti-Patterns

| Anti-Pattern | Log Signal | Fix | Example |
|-------------|-----------|-----|---------|
| SOQL in loop | Repeated `SOQL_EXECUTE_BEGIN` in same code unit | Query before loop, use Map for lookups | See bulkification section |
| DML in loop | Repeated `DML_BEGIN` in same code unit | Collect into List, DML once after loop | See bulkification section |
| Large heap allocation | `HEAP_ALLOCATE` with large byte counts in loops | Use SOQL for-loop, process in batches | `for (Account a : [SELECT...]) {...}` |
| Expensive describe calls | Repeated `Schema.getGlobalDescribe()` | Cache in static variable | See below |
| String concatenation in loop | Rising heap, CPU time | Use `String.join()` or `List<String>` | See below |
| Unfiltered SOQL | `SOQL_EXECUTE_END` with high row count | Add WHERE filters, use selective indexed fields | Add filters |
| Nested loops over collections | High CPU, no SOQL/DML signal | Use Map-based lookups, reduce O(n²) to O(n) | See below |

### Fixing Performance Anti-Patterns

**Cache expensive describe calls:**
```apex
// ❌ WRONG: Called inside loop
for (Account acc : accounts) {
    Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get('Account').getDescribe().fields.getMap();
    // process...
}

// ✅ FIX: Cache outside loop
private static Map<String, Schema.SObjectField> accountFieldsCache;
public static Map<String, Schema.SObjectField> getAccountFields() {
    if (accountFieldsCache == null) {
        accountFieldsCache = Schema.SObjectType.Account.fields.getMap();
    }
    return accountFieldsCache;
}
```

**String concatenation fix:**
```apex
// ❌ WRONG: String concatenation in loop creates many heap allocations
String result = '';
for (Account acc : accounts) {
    result += acc.Name + ', ';  // Each += creates new String object
}

// ✅ FIX: Use List and join
List<String> names = new List<String>();
for (Account acc : accounts) {
    names.add(acc.Name);
}
String result = String.join(names, ', ');
```

**Nested loops fix:**
```apex
// ❌ WRONG: O(n²) nested loop — 200 accounts × 200 contacts = 40,000 iterations!
for (Account acc : accounts) {
    for (Contact con : contacts) {
        if (con.AccountId == acc.Id) {
            // process...
        }
    }
}

// ✅ FIX: Use Map for O(n) lookup
Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
for (Contact con : contacts) {
    if (!contactsByAccountId.containsKey(con.AccountId)) {
        contactsByAccountId.put(con.AccountId, new List<Contact>());
    }
    contactsByAccountId.get(con.AccountId).add(con);
}
for (Account acc : accounts) {
    List<Contact> accContacts = contactsByAccountId.get(acc.Id);
    if (accContacts != null) {
        // process — directly access contacts for this account
    }
}
```

### CPU Time Profiling Pattern

```apex
Long startCpu = Limits.getCpuTime();
// ... operation under test ...
Long endCpu = Limits.getCpuTime();
System.debug('CPU consumed: ' + (endCpu - startCpu) + 'ms for operation X');
```

### Heap Profiling Pattern

```apex
Integer heapBefore = Limits.getHeapSize();
// ... operation under test ...
Integer heapAfter = Limits.getHeapSize();
System.debug('Heap delta: ' + (heapAfter - heapBefore) + ' bytes for operation X');
```

## 7. Trace Flags

### What Are Trace Flags?

Trace flags tell Salesforce to capture debug logs for specific users, classes, or triggers. Without an active trace flag, no logs are captured.

### Setting Up Trace Flags via CLI

```bash
# Step 1: Create a debug level first
sf data create record --sobject DebugLevel --target-org myOrg \
  --values "DeveloperName='DetailedDebug' MasterLabel='Detailed Debug' \
  ApexCode='FINE' ApexProfiling='FINEST' Database='FINE' System='DEBUG' \
  Validation='INFO' Workflow='INFO' Callout='INFO' Visualforce='INFO'"

# Step 2: Query the debug level ID
sf data query --query "SELECT Id FROM DebugLevel WHERE DeveloperName='DetailedDebug'" \
  --target-org myOrg --json

# Step 3: Create a trace flag for a specific user (lasts up to 24 hours)
sf data create record --sobject TraceFlag --target-org myOrg \
  --values "TracedEntityId='005xxxxxxxxxxxx' DebugLevelId='7dlxxxxxxxxxxxx' \
  LogType='USER_DEBUG' StartDate='2026-03-28T00:00:00.000Z' \
  ExpirationDate='2026-03-28T23:59:59.000Z'"
```

### Trace Flag Types

| LogType | What It Traces |
|---------|----------------|
| `USER_DEBUG` | All transactions by a specific user |
| `CLASS_TRACING` | Executions involving a specific Apex class |
| `DEVELOPER_LOG` | Current Developer Console session |

### Setting Up Trace Flags via UI

1. Go to **Setup > Debug Logs > New**
2. Select traced entity (User, Apex Class, or Apex Trigger)
3. Set start/end time (max 24 hours)
4. Select debug level
5. Save — logs will be captured until expiration or 20 logs generated (whichever first)

## 8. Debugging Workflow (Step-by-Step)

### Process for Diagnosing Any Issue

1. **Reproduce the issue**
   - Identify the exact user action, API call, or automated process that fails
   - Note the timestamp window and the user experiencing the issue

2. **Set up trace flags**
   ```bash
   # Ensure trace flag is active for the user
   sf apex tail log --target-org myOrg --color
   ```

3. **Trigger the issue and capture the log**
   - Reproduce via UI, API, or Execute Anonymous
   - Save the log immediately: `sf apex log get --number 1 --target-org myOrg > issue.log`

4. **Scan for errors first**
   - Search for `EXCEPTION_THROWN`, `FATAL_ERROR`, and `LIMIT_USAGE` in the log
   - If truncated, focus on `CUMULATIVE_LIMIT_USAGE` at the end

5. **Trace the execution path**
   - Find `CODE_UNIT_STARTED` to identify which triggers/classes executed
   - Track the order: before triggers, DML, after triggers, workflows, process builder, flows

6. **Check governor limits**
   - Look at `LIMIT_USAGE_FOR_NS` — are any limits above 70%?
   - Cross-reference SOQL count with the number of `SOQL_EXECUTE_BEGIN` events

7. **Identify the root cause**
   - Is it a **data issue**? (missing record, null field)
   - Is it a **logic issue**? (wrong condition, missing bulkification)
   - Is it a **limits issue**? (SOQL in loop, DML in loop)
   - Is it a **concurrency issue**? (record locking, race condition)
   - Is it a **configuration issue**? (validation rule, sharing rule, permission)

8. **Fix and verify**
   - Apply the smallest correct fix
   - Re-run with trace flag active to confirm the issue is resolved
   - Check that governor limits improved (not just that the error went away)

### Quick Diagnosis Commands (Terminal)

```bash
# Search for errors in a saved log
grep -E "EXCEPTION_THROWN|FATAL_ERROR|LIMIT_USAGE" debug.log

# Count SOQL queries in log (look for loops causing many queries)
grep -c "SOQL_EXECUTE_BEGIN" debug.log

# Count DML operations in log
grep -c "DML_BEGIN" debug.log

# Find slow queries (queries returning many rows)
grep "SOQL_EXECUTE_END" debug.log | grep -E "Rows:[0-9]{3,}"

# Find your System.debug statements
grep "USER_DEBUG" debug.log

# Find all exceptions
grep -A2 "EXCEPTION_THROWN" debug.log
```

## 9. Gotchas and Common Mistakes

### Debug Log Truncation
- Debug logs are truncated at **20 MB** — large transactions will lose the beginning of the log
- The log shows `*** Skipped N bytes of detailed log` when truncated
- **To avoid:** Reduce log levels on categories you don't need, set non-essential categories to NONE or ERROR
- Truncated logs still include `CUMULATIVE_LIMIT_USAGE` at the end

### Log Retention
- Debug logs are retained for only **24 hours** (or until 20 logs accumulate per trace flag)
- **Download critical logs immediately** for post-mortem analysis
- Use `sf apex log get` to save logs to local files before they expire

### Trace Flag Expiry
- Trace flags have a maximum duration of **24 hours**
- They silently stop capturing logs after expiration — no warning
- Re-create trace flags before reproducing intermittent issues
- Maximum 250 MB of debug logs per org (oldest are purged first)

### Performance Impact of Debugging
- `System.debug()` statements consume CPU time even in production
- Writing to the debug log adds overhead — high log levels slow execution
- Log levels at FINEST can **double** CPU time for complex transactions
- **Remove or guard debug statements before deploying to production:**

```apex
// Use a custom setting or custom metadata to gate debug output
if (DebugSettings__c.getInstance().EnableDetailedLogging__c) {
    System.debug(LoggingLevel.FINE, 'Detailed: ' + JSON.serialize(records));
}
```

### System.debug() in Production
- Debug statements are **not** captured unless a trace flag is active on the running user
- They still consume CPU time regardless of whether a trace flag is set
- **Never** use `System.debug()` with sensitive data (PII, credentials, tokens)
- Prefer custom logging frameworks (Platform Events + Big Objects) for production observability

### Other Common Traps
- `System.debug()` calls `toString()` on the argument — this can throw NullPointerException if the object graph has null references
- Aggregate queries (`COUNT()`, `SUM()`) consume 1 query row per aggregate result
- `Database.setSavepoint()` and `Database.rollback()` count as DML statements
- Trigger.new is **read-only** in after triggers — modifying it throws a runtime error
- Tests with `@isTest(SeeAllData=true)` can pass in dev but fail in CI due to data differences
- Governor limits reset per **transaction**, not per trigger — multiple triggers in one transaction share limits

## 10. Quick Reference Cheat Sheet

### Must-Know Limits (Synchronous)
| Limit | Value | Typical Trigger |
|-------|-------|-----------------|
| SOQL queries | 100 | Query inside for-loop |
| DML statements | 150 | Insert/update inside for-loop |
| DML rows | 10,000 | Processing too many records at once |
| CPU time | 10,000 ms | Complex logic, nested loops, string concatenation |
| Heap size | 6 MB | Storing too many records in memory |
| Query rows | 50,000 | Unfiltered SOQL queries |
| Callouts | 100 | Many external API calls |

### Debugging Checklist
- [ ] Trace flag active for the user?
- [ ] Correct log level set (FINE for most cases)?
- [ ] Reproduced the issue and captured the log?
- [ ] Searched for EXCEPTION_THROWN and FATAL_ERROR?
- [ ] Checked CUMULATIVE_LIMIT_USAGE at log end?
- [ ] Identified which CODE_UNIT executed?
- [ ] Fixed the root cause, not just the symptom?

### When to Use Async

| Scenario | Use This |
|----------|----------|
| Heavy processing after save | `@future` or Queueable |
| Processing > 10K records | Batch Apex |
| Scheduled jobs | Schedulable |
| Event-driven processing | Platform Events + Trigger |
| Chaining async jobs | Queueable with Finalizer |
