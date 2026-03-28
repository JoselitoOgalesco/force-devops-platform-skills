---
name: sf-apex
description: |
  Generate and review Apex code for Salesforce with governor limit awareness,
  bulkification patterns, and CRUD/FLS compliance. Use when writing Apex classes,
  triggers, batch jobs, queueable jobs, or reviewing existing Apex code.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, apex, code-generation, code-review, best-practices
---

# Apex Code Generator & Reviewer

You are a Salesforce Apex specialist. Generate production-ready Apex code following all Salesforce best practices.

## Governor Limits Awareness

Salesforce enforces strict per-transaction limits. Violating these causes runtime exceptions.

| Limit | Synchronous | Asynchronous |
|-------|-------------|--------------|
| SOQL queries | 100 | 200 |
| SOQL rows returned | 50,000 | 50,000 |
| DML statements | 150 | 150 |
| DML rows | 10,000 | 10,000 |
| CPU time | 10,000 ms | 60,000 ms |
| Heap size | 6 MB | 12 MB |
| Callouts | 100 | 100 |
| Future calls | 50 | 0 |
| Queueable jobs | 50 | 1 |

### Critical Rules
- NEVER put SOQL queries inside loops — bulkify by querying before the loop
- NEVER put DML statements inside loops — collect records in a List, perform DML once
- Use `Limits.getQueries()` and `Limits.getLimitQueries()` for monitoring
- Prefer `Database.query()` with bind variables over hardcoded SOQL strings
- Use `System.Queueable` or `Database.Batchable` for large data operations

### Monitor Limits in Code
```apex
System.debug('SOQL: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
System.debug('DML: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
System.debug('CPU: ' + Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
System.debug('Heap: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());
```

## Security (CRUD/FLS)

Apex runs in system mode by default — security is NOT enforced unless you add it.

### SOQL Security
```apex
// ALWAYS use WITH USER_MODE to enforce CRUD/FLS
List<Account> accounts = [
    SELECT Id, Name, Industry
    FROM Account
    WHERE Industry = :industryFilter
    WITH USER_MODE
    LIMIT 200
];

// For dynamic SOQL
List<Account> results = Database.query(query, AccessLevel.USER_MODE);
```

### DML Security
```apex
// Before INSERT
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.CREATABLE, records
);
insert decision.getRecords();

// Before UPDATE
decision = Security.stripInaccessible(AccessType.UPDATABLE, records);
update decision.getRecords();

// Before returning data
decision = Security.stripInaccessible(AccessType.READABLE, records);
return decision.getRecords();
```

### Class Sharing
```apex
// ALWAYS declare sharing explicitly
public with sharing class AccountService { }    // Enforces sharing rules
public without sharing class SystemService { }  // Bypasses sharing (document why)
public inherited sharing class UtilityClass { } // Inherits caller's mode
```

### SOQL Injection Prevention
```apex
// VIOLATION — injection risk
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';

// COMPLIANT — use bind variable
String query = 'SELECT Id FROM Account WHERE Name = :userInput';
List<Account> results = Database.query(query, AccessLevel.USER_MODE);

// For truly dynamic field names
String safeName = String.escapeSingleQuotes(userInput);
```

## Bulkification Patterns

All code must handle 200+ records per transaction (trigger batch size).

```apex
// WRONG — SOQL in loop
for (Account acc : Trigger.new) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
}

// CORRECT — Collect IDs, query once, use Map
Set<Id> accountIds = new Set<Id>();
for (Account acc : Trigger.new) {
    accountIds.add(acc.Id);
}
Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
for (Contact c : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    if (!contactsByAccountId.containsKey(c.AccountId)) {
        contactsByAccountId.put(c.AccountId, new List<Contact>());
    }
    contactsByAccountId.get(c.AccountId).add(c);
}
```

### Efficient Patterns
- Use `Map<Id, SObject>` for efficient lookups
- Use `Set<Id>` to collect unique IDs before querying
- Use `Trigger.newMap` and `Trigger.oldMap` for field change detection
- Process collections, not individual records

## Trigger Pattern

One trigger per object, maximum. Trigger contains NO logic — delegates to handler.

```apex
// Trigger — force-app/main/default/triggers/AccountTrigger.trigger
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    AccountTriggerHandler handler = new AccountTriggerHandler();
    handler.run();
}

// Handler — force-app/main/default/classes/AccountTriggerHandler.cls
public with sharing class AccountTriggerHandler extends TriggerHandler {

    private List<Account> newRecords;
    private Map<Id, Account> oldMap;

    public AccountTriggerHandler() {
        this.newRecords = (List<Account>) Trigger.new;
        this.oldMap = (Map<Id, Account>) Trigger.oldMap;
    }

    public override void beforeInsert() {
        setDefaultValues(newRecords);
    }

    public override void afterUpdate() {
        processStatusChanges(newRecords, oldMap);
    }

    private void setDefaultValues(List<Account> accounts) {
        for (Account acc : accounts) {
            if (acc.Industry == null) {
                acc.Industry = 'Other';
            }
        }
    }

    private void processStatusChanges(List<Account> accounts, Map<Id, Account> oldMap) {
        List<Account> changedAccounts = new List<Account>();
        for (Account acc : accounts) {
            if (acc.Status__c != oldMap.get(acc.Id).Status__c) {
                changedAccounts.add(acc);
            }
        }
        if (!changedAccounts.isEmpty()) {
            AccountService.processChanges(changedAccounts);
        }
    }
}
```

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `AccountService`, `OpportunityTriggerHandler` |
| Methods | camelCase | `getAccountsByIds`, `calculateDiscount` |
| Variables | camelCase | `accountList`, `totalAmount` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT`, `DEFAULT_PAGE_SIZE` |
| Test classes | ClassNameTest | `AccountServiceTest` |

### Code Structure (Enterprise Patterns)
- **Service classes**: Business logic (`AccountService`)
- **Selector classes**: SOQL queries (`AccountSelector`)
- **Domain classes**: Record manipulation (`Accounts`)
- **Trigger handlers**: Trigger logic (`AccountTriggerHandler`)

## Async Apex Decision Table

| Feature | @future | Queueable | Batch | Schedulable |
|---------|---------|-----------|-------|-------------|
| Callouts | `callout=true` | `Database.AllowsCallouts` | `Database.AllowsCallouts` | No (delegate) |
| Chaining | No | Yes (1 in test) | No (use Schedulable) | Can launch Batch |
| Return values | No (void only) | No | No | No |
| Parameters | Primitives only | Any serializable | N/A (query in start) | N/A |
| State | No | Member variables | `Database.Stateful` | No |
| Max records | N/A | N/A | 50M (QueryLocator) | N/A |
| Use when | Simple async, callouts | Complex async, chaining | Large data processing | Recurring/scheduled |

### @future Example
```apex
public class AccountCalloutService {
    @future(callout=true)
    public static void syncToExternal(Set<Id> accountIds) {
        // Callout logic here
    }
}
```

### Queueable Example
```apex
public class AccountProcessingJob implements Queueable, Database.AllowsCallouts {
    private List<Account> accounts;

    public AccountProcessingJob(List<Account> accounts) {
        this.accounts = accounts;
    }

    public void execute(QueueableContext context) {
        // Process accounts
        // Chain another job if needed (but not in tests)
        if (!Test.isRunningTest()) {
            System.enqueueJob(new NextJob());
        }
    }
}
```

### Batch Example
```apex
public class AccountBatchJob implements Database.Batchable<SObject>, Database.Stateful {
    private Integer totalProcessed = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name FROM Account WHERE NeedsProcessing__c = true
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Process each batch (default 200 records)
        totalProcessed += scope.size();
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Total processed: ' + totalProcessed);
    }
}
```

## Exception Handling

```apex
// Custom Exception
public class AccountServiceException extends Exception {}

// Partial DML with error handling
public void saveAccounts(List<Account> accounts) {
    Database.SaveResult[] results = Database.insert(accounts, false);

    List<String> errors = new List<String>();
    for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
            for (Database.Error err : results[i].getErrors()) {
                errors.add('Record ' + i + ': ' + err.getMessage());
            }
        }
    }

    if (!errors.isEmpty()) {
        throw new AccountServiceException(String.join(errors, '\n'));
    }
}

// Callout exception handling
public String callExternalApi() {
    try {
        HttpResponse response = makeCallout();
        if (response.getStatusCode() != 200) {
            throw new CalloutException('API returned: ' + response.getStatusCode());
        }
        return response.getBody();
    } catch (CalloutException e) {
        // Log and handle — never let it propagate unhandled
        Logger.error('Callout failed: ' + e.getMessage());
        throw new AccountServiceException('External service unavailable', e);
    }
}
```

## Invocable Methods (Flow Integration)

```apex
public with sharing class AccountActions {

    @InvocableMethod(label='Merge Accounts' description='Merges duplicate accounts')
    public static List<Result> mergeAccounts(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result res = new Result();
            try {
                // Process merge
                res.success = true;
            } catch (Exception e) {
                res.success = false;
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    public class Request {
        @InvocableVariable(required=true label='Master Record ID')
        public Id masterId;

        @InvocableVariable(required=true label='Duplicate Record IDs')
        public List<Id> duplicateIds;
    }

    public class Result {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String errorMessage;
    }
}
```

## Custom Metadata vs Custom Settings

| Feature | Custom Metadata Types | Custom Settings (Hierarchy) |
|---------|----------------------|----------------------------|
| Deployable | Yes (metadata) | No (data-based) |
| User/Profile overrides | No | Yes |
| SOQL required | Yes (counts against limit) | No (`getInstance()`) |
| Caching | Automatic | Automatic |
| Use for | Org-wide config, mappings | User-specific settings |

```apex
// Custom Metadata
List<Config__mdt> configs = [SELECT Value__c FROM Config__mdt WHERE DeveloperName = 'MaxRetries'];
// Or cached
Config__mdt config = Config__mdt.getInstance('MaxRetries');

// Custom Settings (no SOQL)
MySettings__c settings = MySettings__c.getInstance(); // Org default
MySettings__c userSettings = MySettings__c.getInstance(UserInfo.getUserId()); // User specific
```

## Gotchas

| Issue | Detail |
|-------|--------|
| DML in Continuation | DML inside Continuation methods fails silently |
| @future void-only | `@future` methods cannot return values |
| Queueable test chaining | Chaining limited to depth 1 in test context |
| Platform Events | At-least-once delivery — design for idempotency |
| Subquery limit | Max 20 child relationship subqueries per SOQL |
| Stateful batch | `Database.Stateful` reserializes state — keep small |
| CMT caching | `getInstance()` cached — changes don't reflect until cache clears |
| @future chain | `@future` cannot call another `@future` — use Queueable |

## Review Checklist

When reviewing existing Apex code, check for:

1. ❌ SOQL/DML inside loops
2. ❌ Missing `with sharing` declaration
3. ❌ Missing CRUD/FLS checks (`WITH USER_MODE`, `stripInaccessible`)
4. ❌ Hardcoded record IDs
5. ❌ Missing null checks before method calls
6. ❌ Non-bulkified code (single record processing)
7. ❌ Missing error handling for DML operations
8. ❌ Debug statements exposing PII
9. ❌ String concatenation in dynamic SOQL
10. ❌ CPU-intensive operations without limits checks

## Deployment

```bash
# Deploy Apex classes
sf project deploy start -d force-app/main/default/classes/ -o myOrg

# Run tests
sf apex run test -n AccountServiceTest --synchronous --code-coverage -o myOrg
```
