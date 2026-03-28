---
applyTo: "**/*.flow-meta.xml"
---

# Flow Development Standards

## Flow Types

| Type | When to Use |
|------|-------------|
| Record-Triggered | Automate on record create/update/delete |
| Screen Flow | User-facing forms and processes |
| Autolaunched | Called from Apex, other flows, or processes |
| Scheduled | Time-based batch processing |

## Naming Convention

```
{Object}_{Action}_{Purpose}
```

Examples:
- `Account_Update_Logging`
- `Case_Create_Assignment`
- `Order_Submit_Approval`

## Record-Triggered Flow Structure

```xml
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <processType>AutoLaunchedFlow</processType>
    <start>
        <object>Account</object>
        <recordTriggerType>Update</recordTriggerType>
        <triggerType>RecordAfterSave</triggerType>
    </start>
    <status>Active</status>
</Flow>
```

## Best Practices

### Entry Conditions
- Always filter with entry conditions to avoid unnecessary runs
- Use `$Record.Id IsNull false` as minimum filter

### Formulas
- Use TEXT() only for non-text fields (picklists, numbers)
- String fields reference directly: `{!$Record.Name}`
- Currency/Number fields: `TEXT({!$Record.AnnualRevenue})`

### DML Operations
- Use `recordCreates` (not `recordUpdates`) for new records
- `storeOutputAutomatically` only valid in `recordCreates`
- Batch related changes in single transaction

### Before vs After Save
- **Before Save**: Field updates on triggering record (no DML credit)
- **After Save**: Create/update related records, call Apex

## Logging Pattern

For audit logging, create `DevOps_ObjectLogs__c` records:

```xml
<recordCreates>
    <name>Create_Log_Record</name>
    <inputAssignments>
        <field>Object_Name__c</field>
        <value><stringValue>Account</stringValue></value>
    </inputAssignments>
    <inputAssignments>
        <field>Operation_Type__c</field>
        <value><stringValue>Update</stringValue></value>
    </inputAssignments>
    <object>DevOps_ObjectLogs__c</object>
</recordCreates>
```

## Governor Limits

- Max 2,000 elements per flow interview
- Max 100 SOQL queries per transaction (shared with Apex)
- Max 150 DML statements per transaction (shared with Apex)

See [force-platform-skills/references/governor-limits.md](../force-platform-skills/references/governor-limits.md) for full limits.
