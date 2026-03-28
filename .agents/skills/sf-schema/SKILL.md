---
name: sf-schema
description: |
  Design and implement Salesforce data models with proper object design,
  field types, relationships, validation rules, and indexing. Covers
  naming conventions, relationship patterns, metadata structure, limits,
  and performance considerations.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, schema, data-model, objects, fields, relationships
---

# Salesforce Schema Design Guide

Design scalable, maintainable data models following Salesforce best practices. This guide covers object design, field types, relationships, validation rules, and performance optimization.

## Understanding Salesforce Data Model

### Platform Limits

| Limit | Value | Impact |
|-------|-------|--------|
| Custom Objects | 200 (Enterprise) | Plan object consolidation |
| Custom Fields per Object | 800 | Includes formula, roll-up fields |
| Custom Relationships | 40 lookups + 2 master-detail | Per object |
| Custom Indexes | 20 per object | For query performance |
| Picklist Values | 1,000 per field | Control picklist growth |
| Text Field Length | 255 (Text) / 131,072 (Long Text) | Choose appropriate type |

**💡 Junior Developer Tip:** Hit a limit? Consider using Custom Metadata Types for configuration data or Junction objects for many-to-many relationships.

### Data Model Design Process

```
1. REQUIREMENTS
   └─ What data needs to be stored?
   └─ Who needs access?
   └─ What relationships exist?

2. ENTITY DESIGN
   └─ Standard vs Custom objects
   └─ Naming conventions
   └─ Record ownership model

3. FIELD DESIGN
   └─ Field types (choose carefully)
   └─ Required vs optional
   └─ Default values

4. RELATIONSHIPS
   └─ Lookup vs Master-Detail decision
   └─ Relationship direction
   └─ Cascade delete behavior

5. SECURITY
   └─ OWD (Organization-Wide Defaults)
   └─ Sharing rules
   └─ Field-level security
```

---

## Naming Conventions

### Required Standards

| Component | Convention | Example | Notes |
|-----------|------------|---------|-------|
| Custom Object | `PascalCase__c` | `Invoice__c` | Singular noun |
| Custom Field | `PascalCase__c` | `Total_Amount__c` | Descriptive |
| Relationship (API) | `PascalCase__r` | `Account__r.Name` | Used in SOQL |
| Relationship (Label) | Human readable | "Parent Account" | User-friendly |
| External ID | `*_External_Id__c` | `ERP_External_Id__c` | Suffix convention |
| Record Type | `PascalCase` | `EnterpriseAccount` | No spaces |

### Anti-Patterns to Avoid

| Don't | Do Instead |
|-------|------------|
| `acct__c` | `Account_Details__c` |
| `x1__c`, `field2__c` | Meaningful names |
| `My_New_Field_v2__c` | Plan field naming upfront |
| Underscores for spaces | Use underscores sparingly |

---

## Custom Object Definition

### Complete Object Template

```xml
<!-- force-app/main/default/objects/Invoice__c/Invoice__c.object-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <!-- Basic Settings -->
    <label>Invoice</label>
    <pluralLabel>Invoices</pluralLabel>
    <description>Financial invoice records for billing</description>

    <!-- Name Field Configuration -->
    <nameField>
        <label>Invoice Number</label>
        <type>AutoNumber</type>
        <displayFormat>INV-{YYYY}-{000000}</displayFormat>
        <startingNumber>1</startingNumber>
    </nameField>

    <!-- Deployment & Sharing -->
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>Private</sharingModel>

    <!-- Features -->
    <enableActivities>true</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableChangeDataCapture>true</enableChangeDataCapture>
    <enableHistory>true</enableHistory>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>

    <!-- Record Types (if needed) -->
    <recordTypes>
        <fullName>Standard</fullName>
        <active>true</active>
        <label>Standard Invoice</label>
    </recordTypes>
</CustomObject>
```

### Name Field Types

| Type | Use Case | Example |
|------|----------|---------|
| `Text` | User-entered name | Contact Name |
| `AutoNumber` | System-generated ID | INV-2024-000001 |

**AutoNumber Format Patterns:**
- `{0}` — Simple sequence: 1, 2, 3
- `{000000}` — Zero-padded: 000001
- `{YYYY}-{000000}` — Year prefix: 2024-000001
- `{MM}{DD}-{0000}` — Date-based: 0315-0001

### Sharing Model Options

| OWD Setting | Meaning | Use When |
|-------------|---------|----------|
| `Private` | Only owner sees | Sensitive data |
| `Read` | Everyone can read | Reference data |
| `ReadWrite` | Everyone can edit | Collaborative data |
| `ControlledByParent` | Inherits from parent | Master-Detail child |

---

## Field Types Reference

### Text Fields

```xml
<!-- Short Text (1-255 characters) -->
<fields>
    <fullName>Product_Code__c</fullName>
    <label>Product Code</label>
    <type>Text</type>
    <length>20</length>
    <required>false</required>
    <unique>true</unique>
    <caseSensitive>false</caseSensitive>
    <externalId>false</externalId>
</fields>

<!-- Long Text Area (up to 131,072 characters) -->
<fields>
    <fullName>Description__c</fullName>
    <label>Description</label>
    <type>LongTextArea</type>
    <length>32768</length>
    <visibleLines>5</visibleLines>
</fields>

<!-- Rich Text Area (with formatting) -->
<fields>
    <fullName>Notes__c</fullName>
    <label>Notes</label>
    <type>Html</type>
    <length>32768</length>
    <visibleLines>10</visibleLines>
</fields>

<!-- Email -->
<fields>
    <fullName>Billing_Email__c</fullName>
    <label>Billing Email</label>
    <type>Email</type>
    <unique>false</unique>
</fields>

<!-- Phone -->
<fields>
    <fullName>Support_Phone__c</fullName>
    <label>Support Phone</label>
    <type>Phone</type>
</fields>

<!-- URL -->
<fields>
    <fullName>Website__c</fullName>
    <label>Website</label>
    <type>Url</type>
</fields>
```

### Number Fields

```xml
<!-- Number -->
<fields>
    <fullName>Quantity__c</fullName>
    <label>Quantity</label>
    <type>Number</type>
    <precision>18</precision>  <!-- Total digits -->
    <scale>0</scale>           <!-- Decimal places -->
    <required>true</required>
    <defaultValue>1</defaultValue>
</fields>

<!-- Currency -->
<fields>
    <fullName>Unit_Price__c</fullName>
    <label>Unit Price</label>
    <type>Currency</type>
    <precision>18</precision>
    <scale>2</scale>
</fields>

<!-- Percent -->
<fields>
    <fullName>Discount_Percent__c</fullName>
    <label>Discount %</label>
    <type>Percent</type>
    <precision>5</precision>
    <scale>2</scale>
</fields>
```

**Number Precision Guide:**
- `precision` = Total digits (including decimal)
- `scale` = Decimal places
- Max useful precision: 18 (larger numbers lose precision)

### Date/DateTime Fields

```xml
<!-- Date only -->
<fields>
    <fullName>Invoice_Date__c</fullName>
    <label>Invoice Date</label>
    <type>Date</type>
    <required>true</required>
</fields>

<!-- Date and Time -->
<fields>
    <fullName>Submitted_DateTime__c</fullName>
    <label>Submitted Date/Time</label>
    <type>DateTime</type>
</fields>
```

### Checkbox

```xml
<fields>
    <fullName>Is_Active__c</fullName>
    <label>Active</label>
    <type>Checkbox</type>
    <defaultValue>true</defaultValue>
</fields>
```

### Picklist Fields

```xml
<!-- Standard Picklist -->
<fields>
    <fullName>Status__c</fullName>
    <label>Status</label>
    <type>Picklist</type>
    <valueSet>
        <restricted>true</restricted>  <!-- Prevents API from adding values -->
        <valueSetDefinition>
            <sorted>false</sorted>
            <value>
                <fullName>Draft</fullName>
                <default>true</default>
                <label>Draft</label>
            </value>
            <value>
                <fullName>Pending</fullName>
                <default>false</default>
                <label>Pending Approval</label>
            </value>
            <value>
                <fullName>Approved</fullName>
                <default>false</default>
                <label>Approved</label>
            </value>
            <value>
                <fullName>Rejected</fullName>
                <default>false</default>
                <label>Rejected</label>
                <isActive>false</isActive>  <!-- Deprecated value -->
            </value>
        </valueSetDefinition>
    </valueSet>
</fields>

<!-- Multi-Select Picklist -->
<fields>
    <fullName>Product_Features__c</fullName>
    <label>Product Features</label>
    <type>MultiselectPicklist</type>
    <visibleLines>5</visibleLines>
    <valueSet>
        <restricted>true</restricted>
        <valueSetDefinition>
            <sorted>true</sorted>
            <value><fullName>Feature_A</fullName><label>Feature A</label></value>
            <value><fullName>Feature_B</fullName><label>Feature B</label></value>
        </valueSetDefinition>
    </valueSet>
</fields>
```

### Global Value Sets (Shared Picklists)

```xml
<!-- globalValueSets/Industry.globalValueSet-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<GlobalValueSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Industry</masterLabel>
    <sorted>true</sorted>
    <customValue>
        <fullName>Technology</fullName>
        <default>false</default>
        <label>Technology</label>
    </customValue>
    <customValue>
        <fullName>Healthcare</fullName>
        <default>false</default>
        <label>Healthcare</label>
    </customValue>
</GlobalValueSet>

<!-- Field referencing global value set -->
<fields>
    <fullName>Industry__c</fullName>
    <label>Industry</label>
    <type>Picklist</type>
    <valueSet>
        <valueSetName>Industry</valueSetName>
    </valueSet>
</fields>
```

---

## Relationships

### Lookup vs Master-Detail Decision

| Feature | Lookup | Master-Detail |
|---------|--------|---------------|
| Required relationship | ❌ Optional | ✅ Required |
| Parent record delete | Child stays | Child deleted (cascade) |
| Roll-up summary | ❌ (use Flow/Apex) | ✅ Built-in |
| Sharing inheritance | ❌ | ✅ |
| Reparenting | ✅ Always | ⚠️ Configurable |
| Existing records | ✅ Can add | ❌ Must create child with parent |

### Lookup Field

```xml
<fields>
    <fullName>Account__c</fullName>
    <label>Account</label>
    <type>Lookup</type>
    <referenceTo>Account</referenceTo>
    <relationshipLabel>Related Invoices</relationshipLabel>
    <relationshipName>Invoices</relationshipName>
    <required>false</required>
    <deleteConstraint>SetNull</deleteConstraint>  <!-- or Restrict -->
</fields>
```

**Delete Constraint Options:**
- `SetNull` — Child stays, field becomes blank
- `Restrict` — Cannot delete parent if children exist

### Master-Detail Field

```xml
<fields>
    <fullName>Invoice__c</fullName>
    <label>Invoice</label>
    <type>MasterDetail</type>
    <referenceTo>Invoice__c</referenceTo>
    <relationshipLabel>Line Items</relationshipLabel>
    <relationshipName>Line_Items</relationshipName>
    <reparentableMasterDetail>false</reparentableMasterDetail>
    <writeRequiresMasterRead>false</writeRequiresMasterRead>
</fields>
```

### Self-Relationship (Hierarchical)

```xml
<!-- Account to Parent Account -->
<fields>
    <fullName>Parent_Account__c</fullName>
    <label>Parent Account</label>
    <type>Lookup</type>
    <referenceTo>Account</referenceTo>
    <relationshipLabel>Child Accounts</relationshipLabel>
    <relationshipName>Child_Accounts</relationshipName>
</fields>
```

### Junction Object (Many-to-Many)

For many-to-many relationships, create a junction object with two Master-Detail fields:

```
Object A ◄──── Junction Object ────► Object B
              (M-D to both)
```

```xml
<!-- Junction object: AccountContactRole__c -->
<CustomObject>
    <fields>
        <fullName>Account__c</fullName>
        <type>MasterDetail</type>
        <referenceTo>Account</referenceTo>
        <relationshipOrder>0</relationshipOrder>  <!-- Primary parent -->
    </fields>
    <fields>
        <fullName>Contact__c</fullName>
        <type>MasterDetail</type>
        <referenceTo>Contact</referenceTo>
        <relationshipOrder>1</relationshipOrder>  <!-- Secondary parent -->
    </fields>
</CustomObject>
```

---

## Formula Fields

### Formula Field Template

```xml
<fields>
    <fullName>Full_Address__c</fullName>
    <label>Full Address</label>
    <type>Text</type>
    <formula>
        BillingStreet &amp; BR() &amp;
        BillingCity &amp; ', ' &amp; BillingState &amp; ' ' &amp; BillingPostalCode
    </formula>
</fields>
```

### Common Formula Patterns

```
<!-- Calculated total -->
Quantity__c * Unit_Price__c * (1 - Discount_Percent__c)

<!-- Days since creation -->
TODAY() - DATEVALUE(CreatedDate)

<!-- Status indicator -->
IF(Is_Active__c, "✅ Active", "❌ Inactive")

<!-- Cross-object reference -->
Account__r.Owner.Email

<!-- Null handling -->
IF(ISBLANK(Phone), Mobile__c, Phone)

<!-- Text case conversion -->
UPPER(LEFT(Name, 1)) & LOWER(MID(Name, 2, LEN(Name)))
```

### Roll-Up Summary Fields

Only available on Master-Detail parent objects:

```xml
<fields>
    <fullName>Total_Amount__c</fullName>
    <label>Total Amount</label>
    <type>Summary</type>
    <summarizedField>Line_Item__c.Extended_Price__c</summarizedField>
    <summaryForeignKey>Line_Item__c.Invoice__c</summaryForeignKey>
    <summaryOperation>sum</summaryOperation>
</fields>
```

**Summary Operations:**
- `count` — Number of child records
- `sum` — Sum of numeric field
- `min` — Minimum value
- `max` — Maximum value

---

## Validation Rules

### Validation Rule Template

```xml
<!-- validationRules/Amount_Must_Be_Positive.validationRule-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<ValidationRule xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Amount_Must_Be_Positive</fullName>
    <active>true</active>
    <description>Ensures amount is greater than zero</description>
    <errorConditionFormula>Amount__c &lt;= 0</errorConditionFormula>
    <errorDisplayField>Amount__c</errorDisplayField>
    <errorMessage>Amount must be greater than zero.</errorMessage>
</ValidationRule>
```

### Common Validation Patterns

```
<!-- Required based on status -->
AND(
    ISPICKVAL(Status__c, 'Approved'),
    ISBLANK(Approved_By__c)
)
Error: Approved By is required when Status is Approved

<!-- Date range validation -->
Close_Date__c < Start_Date__c
Error: Close Date cannot be before Start Date

<!-- Cross-object validation -->
AND(
    ISPICKVAL(Type__c, 'Enterprise'),
    Account__r.AnnualRevenue < 1000000
)
Error: Enterprise type requires Account revenue over $1M

<!-- Email format -->
NOT(REGEX(Email__c, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"))
Error: Please enter a valid email address

<!-- Bypass for admins -->
AND(
    Amount__c > 100000,
    NOT($Permission.Bypass_Validation)
)
Error: Amounts over $100,000 require manager approval
```

---

## Custom Metadata Types

For configuration data that can be deployed:

```xml
<!-- objects/Config_Setting__mdt/Config_Setting__mdt.object-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Config Setting</label>
    <pluralLabel>Config Settings</pluralLabel>
</CustomObject>

<!-- customMetadata/Config_Setting.API_Endpoint.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>API Endpoint</label>
    <protected>false</protected>
    <values>
        <field>Value__c</field>
        <value xsi:type="xsd:string">https://api.example.com/v1</value>
    </values>
</CustomMetadata>
```

**When to Use Custom Metadata vs Custom Settings:**

| Feature | Custom Metadata | Custom Settings |
|---------|-----------------|-----------------|
| Deployable | ✅ | ⚠️ (Hierarchy only) |
| Packageable | ✅ | ❌ |
| SOQL queryable | ✅ | ✅ |
| User-specific values | ❌ | ✅ (Hierarchy) |
| Per-record configuration | ✅ | ✅ (List) |

---

## Indexing for Performance

### When to Add Custom Indexes

Request custom indexes when:
- Field used in WHERE clause frequently
- Query returns < 30% of total records
- Field has high selectivity (many unique values)

### Selectivity Guidelines

| Field Type | Threshold for Selective |
|------------|------------------------|
| Standard Index | < 30% of records |
| Custom Index | < 10% of records or < 333K records |
| External ID | Auto-indexed, always selective |

### Requesting Custom Index

1. Identify slow queries in Debug Logs
2. Check Query Plan with `/services/data/v62.0/query?explain=...`
3. Open support case requesting index
4. Provide SOQL query and object record count

---

## Common Mistakes & Fixes

### Mistake 1: Wrong Relationship Type
```
❌ Problem: Need roll-up summary but used Lookup
✅ Fix: Cannot convert Lookup to Master-Detail with data
   Workaround: Use Flow or Apex for calculations
```

### Mistake 2: Non-Selective Query Fields
```
❌ Problem: Query filters on non-indexed field, times out
✅ Fix: Add custom index or External ID to frequently queried fields
```

### Mistake 3: Hardcoded IDs in Validation Rules
```
❌ Problem: ISPICKVAL(RecordTypeId, '012...')
✅ Fix: ISCHANGED(RecordType.DeveloperName) = 'Enterprise'
```

### Mistake 4: Overusing Formula Fields
```
❌ Problem: 800 field limit hit, mostly formulas
✅ Fix: Use Apex/Flow for complex calculations, cache results
```

### Mistake 5: API Names With Special Characters
```
❌ Problem: Field_Name-New__c (hyphen not allowed)
✅ Fix: Field_Name_New__c (underscores only)
```

---

## Deployment Commands

```bash
# Deploy all objects
sf project deploy start -d force-app/main/default/objects/ --target-org myOrg

# Deploy specific object
sf project deploy start -m CustomObject:Invoice__c --target-org myOrg

# Deploy specific field
sf project deploy start -m CustomField:Invoice__c.Amount__c --target-org myOrg

# Deploy validation rules
sf project deploy start -m ValidationRule:Invoice__c.Amount_Positive --target-org myOrg
```

---

## Workflow Summary

### New Object Workflow

1. **Design**
   - Define purpose and relationships
   - Choose name field type (Text/AutoNumber)
   - Plan fields and relationships

2. **Create Object Metadata**
   - Create `objects/ObjectName__c/ObjectName__c.object-meta.xml`
   - Set sharing model
   - Enable required features

3. **Create Fields**
   - Create field metadata files
   - Add validation rules
   - Define formulas

4. **Create Relationships**
   - Deploy parent objects first
   - Create lookup/master-detail fields
   - Verify cascade delete behavior

5. **Deploy & Test**
   - Deploy to sandbox
   - Create test records
   - Verify relationships and validation
