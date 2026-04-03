---
name: sf-data
description: |
  Execute data migrations, bulk operations, sandbox seeding, and data transformations
  in Salesforce. Covers Bulk API 2.0, SFDX data commands, Data Loader patterns,
  External ID strategies, relationship handling, error recovery, and performance
  optimization for large datasets.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, data, migration, bulk-api, etl, sandbox-seeding
---

# Salesforce Data Operations Guide

Execute data operations safely, efficiently, and at scale. This guide covers everything from simple queries to complex multi-object migrations with proper error handling and governor limit awareness.

## Understanding Salesforce Data APIs

### API Comparison Matrix

| API | Best For | Records/Call | Speed | Use Case |
|-----|----------|--------------|-------|----------|
| **REST API** | Single record operations | 1 | Fast | Real-time integrations |
| **Composite API** | Related records | 25 subrequests | Fast | Creating parent-child in one call |
| **Bulk API 2.0** | Large datasets | Millions | Slower startup, fast throughput | Migrations, nightly syncs |
| **SOAP API** | Legacy integrations | 200 | Medium | Enterprise systems |
| **Streaming API** | Change Data Capture | N/A | Real-time | Event-driven sync |

### Governor Limits for Data Operations

| Limit | Value | Impact |
|-------|-------|--------|
| API Requests/24hr | 1,000,000 (Enterprise) | Each DML counts |
| Bulk API Jobs/24hr | 15,000 | Each import/export job |
| Bulk API Batches/24hr | 15,000 | Batches within jobs |
| Records per 24hr (Bulk) | 150,000,000 | Across all bulk jobs |
| Max file size (Bulk) | 150 MB | Per CSV file |
| Records per composite | 200 | In SObject Collection |

**💡 Junior Developer Tip:** Always check your org's remaining API limits before large operations:
```bash
sf org display --target-org myOrg | grep -i "api"
```

---

## SFDX Data Commands Reference

### Query Operations

```bash
# Basic query to JSON (default)
sf data query -q "SELECT Id, Name, Industry FROM Account WHERE Industry = 'Technology'" \
  --target-org myOrg

# Query to CSV (for spreadsheets/Data Loader)
sf data query -q "SELECT Id, Name, Email FROM Contact LIMIT 1000" \
  --target-org myOrg --result-format csv > contacts.csv

# Bulk query (for large datasets - uses Bulk API)
sf data query -q "SELECT Id, Name FROM Account" \
  --target-org myOrg --bulk --wait 10

# Query with relationship (parent fields)
sf data query -q "SELECT Id, Name, Account.Name FROM Contact" \
  --target-org myOrg

# Query all (includes deleted/archived)
sf data query -q "SELECT Id, Name FROM Account" \
  --target-org myOrg --all-rows
```

### Insert Operations

```bash
# Single record insert
sf data create record -s Account -v "Name='ACME Corp' Industry='Technology'" \
  --target-org myOrg

# Insert from JSON file
sf data import tree -f data/accounts.json --target-org myOrg

# Insert with relationship plan
sf data import tree -p data/migration-plan.json --target-org myOrg
```

### Update Operations

```bash
# Update single record
sf data update record -s Account -i 001xx00000ABC123 \
  -v "Industry='Healthcare'" --target-org myOrg

# Bulk update (with external ID)
sf data upsert bulk -s Account -f accounts.csv -i External_Id__c \
  --target-org myOrg --wait 15
```

### Delete Operations

```bash
# Delete single record
sf data delete record -s Account -i 001xx00000ABC123 --target-org myOrg

# Bulk delete from CSV (must have Id column)
sf data delete bulk -s Account -f delete-accounts.csv \
  --target-org myOrg --wait 10

# Hard delete (bypass Recycle Bin) - requires permission
sf data delete bulk -s Account -f delete-accounts.csv \
  --target-org myOrg --hard-delete
```

---

## Bulk API 2.0 Deep Dive

### When to Use Bulk API

| Scenario | Use Bulk API? |
|----------|---------------|
| < 200 records | ❌ Use REST/SOAP |
| 200 - 10,000 records | ⚠️ Consider Bulk API |
| > 10,000 records | ✅ Always use Bulk API |
| Need real-time response | ❌ Use REST |
| Nightly sync jobs | ✅ Bulk API |

### Bulk API Job Lifecycle

```
┌──────────────────┐
│   Create Job     │  POST /jobs/ingest
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Upload Data     │  PUT /jobs/ingest/{jobId}/batches
│  (CSV chunks)    │  (can upload multiple batches)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Close Job       │  PATCH /jobs/ingest/{jobId}
│  (Start Process) │  state: UploadComplete
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Poll Status     │  GET /jobs/ingest/{jobId}
│  (until done)    │  state: JobComplete | Failed
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Get Results     │  GET /jobs/ingest/{jobId}/successfulResults
│  (success/fail)  │  GET /jobs/ingest/{jobId}/failedResults
└──────────────────┘
```

### Bulk API Best Practices

1. **Optimal file size:** 50-100 MB (not max 150 MB)
2. **Records per file:** ~10 million max recommended
3. **Parallel jobs:** Max 5 concurrent jobs recommended
4. **Timeout handling:** Jobs timeout after 10 min (ingest) / 15 min (query)

### Bulk API Error Handling

```bash
# Get job status
sf data bulk status -i <jobId> --target-org myOrg

# Get failed records
sf data bulk results -i <jobId> --target-org myOrg

# Save failed records for retry
sf data bulk results -i <jobId> --target-org myOrg --result-format csv > failed.csv
```

**Common Bulk API Errors:**

| Error | Cause | Fix |
|-------|-------|-----|
| `INVALID_FIELD` | Field doesn't exist | Check API name spelling |
| `REQUIRED_FIELD_MISSING` | Null in required field | Populate required fields |
| `DUPLICATE_VALUE` | Unique constraint violation | Fix duplicate or use upsert |
| `ENTITY_IS_DELETED` | Record in Recycle Bin | Undelete or skip record |
| `MALFORMED_ID` | Invalid Salesforce ID | Verify 15/18 char ID format |

---

## External ID Strategy (Critical for Migrations)

### What is an External ID?

An External ID is a field that:
- Uniquely identifies records from external systems
- Enables upsert operations (insert or update based on match)
- Preserves relationships during migration without knowing Salesforce IDs

### External ID Field Setup

```xml
<!-- force-app/main/default/objects/Account/fields/External_Id__c.field-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>External_Id__c</fullName>
    <label>External ID</label>
    <type>Text</type>
    <length>50</length>
    <externalId>true</externalId>
    <unique>true</unique>
    <caseSensitive>false</caseSensitive>
</CustomField>
```

**💡 Junior Developer Tip:** Always mark External IDs as both `externalId=true` AND `unique=true` to prevent duplicates and enable upsert.

### External ID Strategies by Source

| Source System | Recommended External ID Format |
|---------------|-------------------------------|
| ERP (SAP, Oracle) | System record ID (e.g., `SAP_12345`) |
| Legacy Salesforce | `OrgId_RecordId` composite |
| Database | Primary key or natural key |
| File Import | Row hash or sequence number |
| API Integration | UUID or API resource ID |

### Using External IDs in CSV

```csv
External_Id__c,Name,Industry,Parent_External_Id__c
ERP001,ACME Corp,Technology,
ERP002,ACME West,Technology,ERP001
ERP003,ACME East,Technology,ERP001
```

Note: `Parent_External_Id__c` references the parent's External ID, not Salesforce ID.

### Upsert vs Insert Decision

```
Has External ID field?
    │
    ├─ YES → Use Upsert (idempotent, safer)
    │
    └─ NO → Use Insert (will create duplicates if re-run!)
```

**Always prefer Upsert for:**
- Recurring data syncs
- Migration with multiple test runs
- Incremental loads

---

## Complex Migration Patterns

### Loading Order (Critical!)

Salesforce enforces referential integrity. Load in this order:

```
1. Setup Objects (Users, Record Types, etc.)
            │
            ▼
2. Independent Objects (no required lookups)
   Examples: Account, Product2, Pricebook2
            │
            ▼
3. Parent Objects (referenced by children)
   Examples: Account before Contact
            │
            ▼
4. Child Objects with Lookups
   Examples: Contact, Opportunity
            │
            ▼
5. Junction Objects
   Examples: OpportunityContactRole, AccountContactRelation
            │
            ▼
6. Attachments/Files
   Examples: ContentVersion, Attachment
```

### Master-Detail Relationship Loading

**⚠️ Critical:** Master-Detail parent MUST exist before child insert. No orphan children allowed.

```
Parent (Account): Insert FIRST
    ├── External_Id__c: ACME001
    └── Name: ACME Corporation

Child (Contact): Insert SECOND
    ├── External_Id__c: CONT001
    ├── Account.External_Id__c: ACME001  ← References parent's External ID
    └── LastName: Smith
```

### Self-Referential Records (Two-Pass)

Objects with self-references (e.g., Account.ParentId) need two passes:

**Pass 1: Insert without self-reference**
```csv
External_Id__c,Name
ACME001,ACME Corporation
ACME002,ACME West Division
ACME003,ACME East Division
```

**Pass 2: Update with self-reference**
```csv
External_Id__c,Parent.External_Id__c
ACME002,ACME001
ACME003,ACME001
```

### Data Plan for Relationships

```json
[
    {
        "sobject": "Account",
        "saveRefs": true,
        "resolveRefs": false,
        "files": ["data/Account.json"]
    },
    {
        "sobject": "Contact",
        "saveRefs": true,
        "resolveRefs": true,
        "files": ["data/Contact.json"]
    },
    {
        "sobject": "Opportunity",
        "saveRefs": false,
        "resolveRefs": true,
        "files": ["data/Opportunity.json"]
    }
]
```

| Property | Meaning |
|----------|---------|
| `saveRefs: true` | Store record IDs for later reference |
| `resolveRefs: true` | Look up referenced records' IDs |

---

## Sandbox Seeding Strategies

### Strategy 1: JSON Seed Files

**Structure:**
```
data/
├── seed/
│   ├── plan.json
│   ├── Account.json
│   ├── Contact.json
│   └── Opportunity.json
└── README.md
```

**Account.json:**
```json
{
    "records": [
        {
            "attributes": {"type": "Account", "referenceId": "AcctRef1"},
            "Name": "Test Account 1",
            "Industry": "Technology",
            "External_Id__c": "SEED001"
        },
        {
            "attributes": {"type": "Account", "referenceId": "AcctRef2"},
            "Name": "Test Account 2",
            "Industry": "Healthcare",
            "External_Id__c": "SEED002"
        }
    ]
}
```

**Contact.json (with relationship):**
```json
{
    "records": [
        {
            "attributes": {"type": "Contact"},
            "FirstName": "John",
            "LastName": "Doe",
            "Email": "john.doe@test.com",
            "AccountId": "@AcctRef1"
        }
    ]
}
```

### Strategy 2: Anonymous Apex for Bulk Data

```apex
// scripts/seed-data.apex
// Generate 500 Accounts with Contacts

List<Account> accounts = new List<Account>();
for (Integer i = 1; i <= 500; i++) {
    accounts.add(new Account(
        Name = 'Test Account ' + i,
        Industry = Math.mod(i, 2) == 0 ? 'Technology' : 'Healthcare',
        BillingState = 'CA',
        External_Id__c = 'SEED' + String.valueOf(i).leftPad(6, '0')
    ));
}
insert accounts;

List<Contact> contacts = new List<Contact>();
for (Account acct : accounts) {
    contacts.add(new Contact(
        FirstName = 'Contact',
        LastName = acct.Name,
        Email = 'contact@' + acct.Name.replace(' ', '').toLowerCase() + '.test',
        AccountId = acct.Id
    ));
}
insert contacts;

System.debug('Created ' + accounts.size() + ' Accounts and ' + contacts.size() + ' Contacts');
```

**Run:**
```bash
sf apex run -f scripts/seed-data.apex --target-org sandbox
```

### Strategy 3: Production Data Sampling

```bash
# Export sample from prod
sf data query -q "SELECT Id, Name, Industry FROM Account WHERE Industry = 'Technology' LIMIT 100" \
  --target-org prod --result-format csv > accounts-sample.csv

# Import to sandbox (after masking PII!)
sf data upsert bulk -s Account -f accounts-sample.csv -i Id --target-org sandbox
```

**⚠️ Warning:** Never move real PII to sandboxes. Use Data Mask or anonymize first.

---

## Data Quality & Validation

### Pre-Load Validation Checklist

- [ ] External IDs are unique (no duplicates in source)
- [ ] Required fields are populated
- [ ] Picklist values exist in target org
- [ ] Lookup target records exist
- [ ] Date format is ISO 8601 (YYYY-MM-DD)
- [ ] DateTime format includes timezone (YYYY-MM-DDTHH:MM:SSZ)
- [ ] IDs are valid 15 or 18 character format
- [ ] No circular references

### CSV Formatting Rules

| Field Type | Format | Example |
|------------|--------|---------|
| Text | Plain string | `ACME Corp` |
| Date | YYYY-MM-DD | `2024-03-15` |
| DateTime | ISO 8601 | `2024-03-15T14:30:00Z` |
| Boolean | true/false | `true` |
| Number | No formatting | `1234.56` |
| Currency | No $ symbol | `99.99` |
| Lookup (ID) | 15 or 18 char | `001xx000003ABC` |
| Lookup (Ext ID) | Prefix with object | `Account.External_Id__c` |
| Null | Empty cell | (leave blank) |

### Post-Load Validation Queries

```sql
-- Count records by load date
SELECT COUNT(Id), DAY_ONLY(CreatedDate)
FROM Account
WHERE External_Id__c != null
GROUP BY DAY_ONLY(CreatedDate)

-- Find orphan records (missing parent)
SELECT Id, Name FROM Contact WHERE AccountId = null

-- Find duplicates
SELECT External_Id__c, COUNT(Id)
FROM Account
GROUP BY External_Id__c
HAVING COUNT(Id) > 1
```

---

## Error Recovery Patterns

### Retry Failed Records

```bash
# 1. Get failed records from bulk job
sf data bulk results -i <jobId> --target-org myOrg > results.csv

# 2. Filter to failed records, fix issues in CSV

# 3. Retry failed records
sf data upsert bulk -s Account -f fixed-records.csv -i External_Id__c \
  --target-org myOrg
```

### Rollback Strategy

**Before migration:**
1. Export current data as backup
2. Record count before operation
3. Document External IDs being inserted

**Rollback:**
```bash
# Query records created in migration
sf data query -q "SELECT Id FROM Account WHERE External_Id__c LIKE 'MIG%'" \
  --target-org myOrg --result-format csv > to-delete.csv

# Delete migrated records
sf data delete bulk -s Account -f to-delete.csv --target-org myOrg
```

---

## ContentVersion (Files) Migration

### Understanding Salesforce Files

```
ContentDocument (container)
    └── ContentVersion (actual file - may have multiple versions)
            └── ContentDocumentLink (links file to records)
```

### Loading Files via API

```csv
Title,PathOnClient,VersionData
Q1 Report,/path/Q1Report.pdf,[Base64 encoded content]
Contract,/path/Contract.docx,[Base64 encoded content]
```

**Required fields:**
- `Title` - Display name
- `PathOnClient` - Original filename
- `VersionData` - Base64 encoded file content

### Script to Upload Files

```apex
// Apex: Upload file and link to Account
ContentVersion cv = new ContentVersion();
cv.Title = 'Contract';
cv.PathOnClient = 'Contract.pdf';
cv.VersionData = Blob.valueOf('...base64 content...');
cv.FirstPublishLocationId = accountId; // Links to Account
insert cv;
```

---

## Performance Optimization

### Batch Size Recommendations

| Object Complexity | Recommended Batch | Notes |
|-------------------|-------------------|-------|
| Simple (few fields) | 10,000 | Standard insert |
| Medium (triggers) | 2,000 | Allows trigger processing |
| Complex (flows, validations) | 200 | Heavy automation |
| Files (ContentVersion) | 100 | Large binary payloads |

### Disable Features During Load

```xml
<!-- Create Custom Permission to bypass automation -->
<CustomPermission>
    <label>Bypass Automation</label>
    <description>Disables triggers and flows during data load</description>
</CustomPermission>
```

**Check in triggers:**
```apex
if (FeatureManagement.checkPermission('Bypass_Automation')) {
    return; // Skip trigger logic
}
```

### Parallel Loading (Careful!)

- **Same object:** Max 1-2 parallel jobs (lock contention)
- **Different objects:** Can run in parallel
- **Shared parents:** Load parents first, wait for completion

---

## Common Mistakes & Fixes

### Mistake 1: Ignoring Bulk Job Results
```
❌ Problem: Bulk job returns "success" but records failed
✅ Fix: Always check successfulResults AND failedResults
```

### Mistake 2: Wrong Date Format
```
❌ Problem: Date field "03/15/2024" fails to load
✅ Fix: Use ISO format "2024-03-15"
```

### Mistake 3: Loading Children Before Parents
```
❌ Problem: Contact insert fails - no matching Account
✅ Fix: Insert Accounts first, then Contacts with AccountId
```

### Mistake 4: Hardcoded Salesforce IDs
```
❌ Problem: Migration fails in sandbox (IDs don't exist)
✅ Fix: Use External IDs for relationships
```

### Mistake 5: No Backup Before Delete
```
❌ Problem: Accidentally deleted production data
✅ Fix: Always export before destructive operations
```

### Mistake 6: PII in Sandbox
```
❌ Problem: Real customer data in sandbox
✅ Fix: Use Data Mask or anonymize before loading
```

---

## Workflow Summaries

### Simple Import Workflow

```
1. Export data to CSV
2. Verify field mappings
3. Check for duplicates (External ID)
4. Test with LIMIT 10 records
5. Run full import
6. Verify record counts
7. Validate sample records
```

### Complex Migration Workflow

```
1. ANALYZE
   └─ Document object dependencies
   └─ Map source to target fields
   └─ Design External ID strategy

2. PREPARE
   └─ Create External ID fields
   └─ Export backup of target org
   └─ Set up bypass mechanism

3. TEST (in Sandbox)
   └─ Load small dataset (~100 records)
   └─ Verify relationships
   └─ Test rollback procedure

4. EXECUTE
   └─ Enable bypass permissions
   └─ Load parent objects first
   └─ Load child objects
   └─ Check for failed records, retry

5. VALIDATE
   └─ Record count verification
   └─ Relationship integrity check
   └─ Sample record spot-check

6. CLEANUP
   └─ Remove bypass permissions
   └─ Document migration for audit
```
