---
applyTo: "**/*.cls"
---

# Apex Development Standards

## Class Structure

```apex
/**
 * @description Brief purpose of the class
 * @author AI generated for Force.com DevOps Platform Team
 * @date YYYY-MM-DD
 */
public with sharing class ClassName {
    // Constants first
    private static final String CONSTANT_NAME = 'value';

    // Instance variables
    private List<SObject> records;

    // Public methods with ApexDoc
    // Private helper methods last
}
```

## Security (CRUD/FLS)

**Before DML operations:**
```apex
// Strip inaccessible fields
records = (List<Account>) Schema.stripInaccessible(
    AccessType.CREATABLE,
    records
).getRecords();

// Then perform DML
insert records;
```

**In SOQL queries:**
```apex
SELECT Id, Name FROM Account WITH USER_MODE
```

## Bulkification

- Methods accept `List<SObject>`, never single records
- Use Maps for lookups: `Map<Id, SObject>`
- Process in batches when approaching limits
- Check limits: `Limits.getQueries()`, `Limits.getDMLStatements()`

## Error Handling

```apex
Database.SaveResult[] results = Database.insert(records, false);
for (Integer i = 0; i < results.size(); i++) {
    if (!results[i].isSuccess()) {
        for (Database.Error err : results[i].getErrors()) {
            System.debug(LoggingLevel.ERROR, err.getMessage());
        }
    }
}
```

## Triggers

One trigger per object, delegate to handler:

```apex
trigger AccountTrigger on Account (after insert, after update) {
    AccountTriggerHandler.handle(Trigger.new, Trigger.oldMap, Trigger.operationType);
}
```

## Testing

- Use `@TestSetup` for shared data
- Wrap DML in `Test.startTest()` / `Test.stopTest()`
- Assert all expected behaviors
- Test bulk scenarios (200+ records)
