---
name: sf-flow
description: |
  Build production-ready Salesforce Flows with proper architecture, governor limit
  awareness, error handling, and testing. Covers Screen Flows, Record-Triggered Flows,
  Scheduled Flows, Platform Event Flows, and Orchestrations. Includes Process Builder
  migration patterns and performance optimization.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, flow, automation, record-triggered, screen-flow, orchestration
---

# Salesforce Flow Development Guide

Build robust, scalable Flows that follow Salesforce best practices. This guide covers architecture patterns, governor limits, error handling, testing, and common pitfalls.

## Understanding Flow Architecture

### Why Flows Matter
Flows are Salesforce's primary automation tool. They replace:
- **Workflow Rules** (retired)
- **Process Builder** (retired)
- **Visual Workflow** (legacy)

**💡 Junior Developer Tip:** Think of Flows as visual programming. Each element is like a line of code, and the connectors show the order of execution.

### Flow Types Reference

| Type | When It Runs | User Context | Best For |
|------|--------------|--------------|----------|
| **Record-Triggered (Before Save)** | Before record commits to database | Running user | Field defaulting, validation, same-record updates |
| **Record-Triggered (After Save)** | After record commits | Running user | Related record updates, callouts, notifications |
| **Screen Flow** | User clicks button/link | Running user | Wizards, guided processes, data entry |
| **Autolaunched Flow** | Called by Apex, API, other flow | Configurable | Reusable logic, integrations |
| **Scheduled Flow** | Cron schedule | System | Batch processing, cleanup jobs |
| **Platform Event-Triggered** | Event published | System | Event-driven integrations |
| **Orchestration** | Multi-step processes | System | Long-running approvals, multi-day processes |

### Order of Execution Context

Flows run within Salesforce's Order of Execution:

```
1. System validation (required fields, field formats)
2. Before-save flows (Record-Triggered)
3. Before triggers (Apex)
4. System validation + duplicate rules
5. Record saved to database (in memory)
6. After triggers (Apex)
7. Assignment/auto-response rules
8. After-save flows (Record-Triggered)
9. Entitlement rules
10. Roll-up summary calculations
11. Cross-object workflow (if field update)
12. Post-commit logic (outbound messages, async Apex)
```

**⚠️ Critical:** Before-save flows run BEFORE Apex triggers. After-save flows run AFTER Apex triggers. Plan accordingly.

---

## Governor Limits for Flows

Flows are subject to ALL Salesforce governor limits because they compile to Apex:

| Limit | Value | Impact on Flows |
|-------|-------|-----------------|
| SOQL Queries | 100/transaction | Each "Get Records" = 1 query |
| DML Statements | 150/transaction | Each "Create/Update/Delete Records" = 1 DML |
| DML Rows | 10,000/transaction | Total records across all DML operations |
| CPU Time | 10,000 ms | Complex formulas and loops consume CPU |
| Heap Size | 6 MB | Collections and text variables use heap |
| Flow Interviews | 250,000/24 hours | Scheduled flows count toward this |
| Callouts | 100/transaction | HTTP callouts from flow actions |

### Bulkification in Flows

**CRITICAL CONCEPT:** Flows MUST be bulkified just like Apex triggers.

**❌ WRONG - DML in Loop:**
```
Loop over Contact collection
  └─ Update Records (updates 1 contact per iteration)
     └─ This causes 200 DML statements for 200 records!
```

**✅ CORRECT - Collect, Then DML:**
```
Loop over Contact collection
  └─ Assignment: Add modified contact to output collection
After Loop:
  └─ Update Records (updates entire collection in 1 DML)
```

**💡 Junior Developer Tip:** Never put "Get Records", "Create Records", "Update Records", or "Delete Records" INSIDE a loop. Always collect items in the loop and perform DML AFTER the loop.

---

## Flow Architecture Patterns

### One Flow Per Object Per Trigger Point

**Best Practice:** Maximum 3 record-triggered flows per object:
1. Before-Save Flow
2. After-Save Flow
3. Before-Delete Flow (if needed)

**Why?** Multiple flows on the same trigger point:
- Execute in unpredictable order
- Make debugging difficult
- Can cause recursive issues

### Bypass Pattern (Required)

Every record-triggered flow MUST check for automation bypass:

```
┌─────────────────────────┐
│   Flow Start            │
└───────────┬─────────────┘
            ▼
┌─────────────────────────┐
│  Decision:              │
│  Is Bypass Enabled?     │
│                         │
│  $Permission.Bypass_    │
│  Automation = true?     │
└───────────┬─────────────┘
     Yes    │     No
      ▼     │      ▼
   [End]    │  [Main Logic]
```

**Custom Permission Setup:**
```xml
<!-- force-app/main/default/customPermissions/Bypass_Automation.customPermission-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomPermission xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Bypass Automation</label>
    <description>Allows users to bypass triggers and flows for data migrations</description>
</CustomPermission>
```

**Why bypass matters:**
- Data migrations need to load records without triggering automation
- Prevents infinite loops during complex integrations
- Allows admins to fix data without side effects

### Subflow Pattern for Reusability

Extract common logic into Autolaunched Flows (subflows):

```
┌──────────────────────┐    ┌──────────────────────┐
│ Account After Save   │    │ Contact After Save   │
│        Flow          │    │        Flow          │
└──────────┬───────────┘    └──────────┬───────────┘
           │                           │
           └─────────┬─────────────────┘
                     ▼
           ┌──────────────────────┐
           │  Subflow: Send       │
           │  Notification to     │
           │  Account Team        │
           └──────────────────────┘
```

**Subflow Best Practices:**
- Use clear input/output variables
- Document expected data types
- Handle null inputs gracefully
- Name with prefix: `Sub_` or `Subflow_`

---

## Error Handling

### Fault Path Pattern (Required)

Every element that can fail (DML, callouts, subflows) MUST have a fault connector:

```
┌───────────────────────┐
│  Update Records       │
│  (Update Contacts)    │
└──────────┬────────────┘
           │
    ┌──────┴──────┐
Success      Fault
    │             │
    ▼             ▼
[Continue]   ┌─────────────────────┐
             │  Create Error Log   │
             │  Record             │
             │                     │
             │  Store:             │
             │  - $Flow.FaultMsg   │
             │  - $Flow.InterviewGuid│
             │  - Record context   │
             └─────────────────────┘
```

### Error Log Object Design

Create a custom object to capture flow errors:

```xml
<!-- Flow_Error_Log__c -->
<CustomObject>
    <label>Flow Error Log</label>
    <fields>
        <fullName>Flow_Name__c</fullName>
        <type>Text</type>
        <length>255</length>
    </fields>
    <fields>
        <fullName>Error_Message__c</fullName>
        <type>LongTextArea</type>
        <length>32768</length>
    </fields>
    <fields>
        <fullName>Interview_GUID__c</fullName>
        <type>Text</type>
        <length>36</length>
    </fields>
    <fields>
        <fullName>Record_Id__c</fullName>
        <type>Text</type>
        <length>18</length>
    </fields>
    <fields>
        <fullName>Running_User__c</fullName>
        <type>Lookup</type>
        <referenceTo>User</referenceTo>
    </fields>
</CustomObject>
```

**Fault Variables:**
| Variable | Description |
|----------|-------------|
| `$Flow.FaultMessage` | Error message text |
| `$Flow.InterviewGuid` | Unique ID for this flow interview |
| `$Flow.CurrentDateTime` | When error occurred |

---

## Record-Triggered Flow Deep Dive

### Before-Save vs After-Save Decision Matrix

| Requirement | Use Before-Save | Use After-Save |
|-------------|-----------------|----------------|
| Update fields on same record | ✅ | ❌ (causes extra DML) |
| Field defaulting | ✅ | ❌ |
| Validation (with fault) | ✅ | ❌ |
| Update related records | ❌ | ✅ |
| Create child records | ❌ | ✅ |
| Send emails | ❌ | ✅ |
| Make callouts | ❌ | ✅ |
| Post to Chatter | ❌ | ✅ |

### Entry Conditions (Critical for Performance)

**Always** add entry conditions to prevent unnecessary flow execution:

```
Entry Conditions:
  ISCHANGED({!$Record.Status__c}) = true
  AND
  {!$Record.Status__c} = "Closed"
```

**Why?** Without entry conditions:
- Flow runs on EVERY record update
- Wastes CPU time evaluating decisions
- Can hit limits faster

### Scheduled Paths

Replace workflow time-based actions with scheduled paths:

```
Configuration:
  - Time Source: Record field (e.g., Due_Date__c)
  - Offset: 3 Days Before or 1 Hour After
  - Batch Size: Default (configurable)
```

**Scheduled Path Considerations:**
- Records must meet criteria at scheduled time (re-evaluated)
- Runs in system context
- Subject to 250,000/day interview limit
- Cannot be scheduled more than 2 years out

---

## Screen Flow Best Practices

### Performance Optimization

| Element | Performance Cost | Alternative |
|---------|------------------|-------------|
| Get Records with 50K rows | Very High | Add filter conditions |
| Dependent picklists | Medium | Limit choices to 100 |
| Multiple screens | Medium | Combine when logical |
| Rich Text Display | Low | Use sparingly |

### Conditional Visibility

Show/hide components based on conditions:
```
Component Visibility Condition:
  {!varSelectedProduct} != null
  AND
  {!varSelectedProduct.Family} = "Hardware"
```

### Input Validation

Add validation rules to screen components:
```
Validation Formula:
  REGEX({!inputEmail}, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")

Error Message:
  "Please enter a valid email address"
```

### Multi-Screen Wizard Pattern

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Screen 1:  │──▶│  Screen 2:  │──▶│  Screen 3:  │
│  Basic Info │   │  Details    │   │  Confirm    │
└─────────────┘   └─────────────┘   └─────────────┘
      │                 │                 │
      ▼                 ▼                 ▼
   [varStep=1]     [varStep=2]      [varStep=3]
                                          │
                                          ▼
                                   ┌───────────────┐
                                   │ Create Record │
                                   └───────────────┘
```

Use a Progress Indicator component with Stages.

---

## Process Builder Migration Guide

### Migration Decision Tree

```
Existing Process Builder
        │
        ▼
┌─────────────────────────────────────┐
│ Does it update ONLY the triggering  │
│ record?                             │
└────────────────┬────────────────────┘
       Yes       │       No
        │        │        │
        ▼        │        ▼
   Before-Save   │   After-Save
      Flow       │      Flow
```

### Common Translations

| Process Builder Action | Flow Equivalent | Notes |
|------------------------|-----------------|-------|
| Update same record | Before-Save Assignment | No explicit DML needed |
| Update related records | After-Save: Get + Update | Requires 2 elements |
| Create child record | After-Save: Create Records | |
| Email Alert | After-Save: Action (Email Alert) | Reference existing alert |
| Apex (immediate) | After-Save: Action (Apex) | Must be @InvocableMethod |
| Schedule action | After-Save Scheduled Path | Replaces time-dependent workflow |

### Migration Checklist

- [ ] Identify all Process Builders on the object
- [ ] Group actions by trigger point (immediate vs scheduled)
- [ ] Combine multiple PBs into single flow per trigger type
- [ ] Add bypass check decision
- [ ] Add fault paths to all DML actions
- [ ] Create flow tests
- [ ] Deploy flow as Inactive
- [ ] Test thoroughly in sandbox
- [ ] Deactivate Process Builders
- [ ] Activate new Flow
- [ ] Monitor for issues (Setup → Debug Logs)

---

## Flow Testing

### Test Coverage Requirements

Starting API v61.0, record-triggered flows have coverage tracking:

```sql
SELECT
    FlowVersionId,
    FlowDefinition.DeveloperName,
    NumElementsCovered,
    NumElementsNotCovered,
    (NumElementsCovered / (NumElementsCovered + NumElementsNotCovered)) * 100 AS CoveragePercent
FROM FlowTestCoverage
WHERE FlowDefinition.DeveloperName = 'Account_Before_Save'
```

### Creating Flow Tests

1. **Setup → Flow Tests → New Flow Test**
2. Set initial record state
3. Set triggering action (insert/update/delete)
4. Set expected outcomes
5. Run test

**Test Scenarios to Cover:**
- [ ] Happy path (all conditions met)
- [ ] Each decision branch
- [ ] Null value handling
- [ ] Bulk (200 records)
- [ ] Bypass enabled scenario

---

## Global Variables Reference

| Variable | Description | Available In |
|----------|-------------|--------------|
| `$Record` | Current record (all fields) | Record-Triggered |
| `$Record__Prior` | Previous values (before update) | Record-Triggered |
| `$User` | Current running user | All |
| `$Profile` | User's profile | All |
| `$Permission` | Custom permission check | All |
| `$Organization` | Org info (name, ID, type) | All |
| `$Api` | Session info | All |
| `$Flow.FaultMessage` | Error message in fault paths | All |
| `$Flow.InterviewGuid` | Unique interview ID | All |
| `$Setup` | Custom Metadata Type records | All |
| `$Label` | Custom Labels | All |
| `$System.OriginDateTime` | Interview start time | All |

### Using $Record__Prior (Important!)

Check if a field changed:
```
Formula: {!$Record.Status__c} != {!$Record__Prior.Status__c}
```

**⚠️ Warning:** `$Record__Prior` is NULL on insert. Always check:
```
Decision: Is Update?
  Condition: ISBLANK({!$Record__Prior}) = false
```

---

## Common Mistakes & Fixes

### Mistake 1: DML Inside Loop
```
❌ Problem: Update Records element inside Loop
✅ Fix: Collect records in loop, one Update after loop
```

### Mistake 2: Missing Null Checks
```
❌ Problem: Get Records returns 0 records, then use {!varAccount.Name}
✅ Fix: Add Decision to check ISBLANK({!varAccount})
```

### Mistake 3: Assuming Formula Fields Update Immediately
```
❌ Problem: Update field, then read formula based on that field
✅ Fix: Formula fields recalculate AFTER transaction commits
```

### Mistake 4: No Entry Conditions
```
❌ Problem: Flow runs on every Account update
✅ Fix: Add entry condition: ISCHANGED({!$Record.Status__c})
```

### Mistake 5: Hardcoded IDs
```
❌ Problem: Record Type ID hardcoded: "012000000000001"
✅ Fix: Use Get Records to find Record Type by DeveloperName
```

### Mistake 6: Forgetting Fault Paths
```
❌ Problem: Update fails, flow ends, no error visibility
✅ Fix: Add fault connector → Create error log record
```

---

## Performance Optimization

### Query Optimization
- **Filter conditions**: Always filter Get Records to minimum needed
- **Selective fields**: Only retrieve fields you'll use
- **Limit records**: Set a reasonable limit (default is 2000)

### Before-Save Advantages
- **No DML cost**: Updating `$Record` fields doesn't count as DML
- **Faster execution**: Runs before record commits
- **Less governor impact**: More efficient for same-record updates

### Batch Processing Patterns
For after-save bulk operations, consider:
1. Platform Events (decouple processing)
2. Queueable Apex (invoke from flow action)
3. Scheduled flows (process overnight)

---

## Debugging Flows

### Debug Mode
1. Open Flow in Flow Builder
2. Click "Debug" button
3. Select trigger context (Insert/Update/Delete)
4. Provide sample data
5. Step through execution

### Debug Log Analysis
Enable Workflow category at FINER level:
```
FLOW_CREATE_INTERVIEW
FLOW_START_INTERVIEW : Interview GUID
FLOW_ELEMENT_BEGIN : Element_Name (type)
FLOW_VALUE_ASSIGNMENT : Variable = Value
FLOW_ELEMENT_END : Element_Name
FLOW_INTERVIEW_FINISHED
```

### Common Debug Scenarios

| Symptom | Likely Cause | How to Debug |
|---------|--------------|--------------|
| Flow doesn't fire | Entry conditions not met | Check Condition Logic |
| Null reference error | Get Records returned 0 | Add null check decision |
| Too many SOQL | Get Records in loop | Refactor to collect/query pattern |
| Records not updating | Before-save using DML | Use Assignment, not Update Records |
| Infinite loop | Flow updates record that re-triggers | Add recursion guard or bypass |

---

## Workflow Summary

### Building a New Record-Triggered Flow

1. **Define requirements**
   - Which object?
   - Before-save or after-save?
   - What conditions trigger?

2. **Set entry conditions** (filter to minimum records)

3. **Add bypass check** (Custom Permission decision)

4. **Build main logic**
   - Before-save: Use Assignments for field updates
   - After-save: Use DML elements for related records

5. **Add fault paths** to all DML/callout elements

6. **Test thoroughly**
   - Single record
   - 200 records (bulk)
   - Edge cases

7. **Deploy as Inactive** → Test in sandbox → Activate

### Migration Workflow

1. **Inventory**: List all Process Builders on object
2. **Analyze**: Document all criteria and actions
3. **Design**: Plan consolidated flow structure
4. **Build**: Create flow with bypass, decisions, fault paths
5. **Test**: Unit test all branches
6. **Deploy**: Flow inactive, test in sandbox
7. **Cutover**: Deactivate PBs, activate Flow
8. **Monitor**: Debug logs for first few days
