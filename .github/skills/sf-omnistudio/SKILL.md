---
name: sf-omnistudio
description: |
  Build OmniStudio/Salesforce Industries solutions including OmniScripts, FlexCards,
  Integration Procedures, and Data Mappers. Covers namespace detection, dependency
  mapping, LWC OmniScripts, performance optimization, troubleshooting, and deployment.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, omnistudio, omniscript, flexcard, integration-procedure, industries
---

# OmniStudio Development Guide

Build, review, and troubleshoot OmniStudio components. This guide covers OmniScripts, FlexCards, Integration Procedures, and Data Mappers with best practices for performance and maintainability.

## Understanding OmniStudio

### What is OmniStudio?

OmniStudio is Salesforce Industries' declarative framework for building guided digital experiences without code. It's used heavily in:
- Communications & Media
- Insurance & Health
- Financial Services
- Energy & Utilities

**💡 Junior Developer Tip:** Think of OmniStudio as a low-code toolkit for building complex multi-step forms and data orchestrations that would otherwise require extensive Apex and LWC development.

### Component Reference

| Component | Purpose | Standard Equivalent |
|-----------|---------|---------------------|
| **OmniScript** | Multi-step guided wizard | Screen Flow |
| **FlexCard** | Data display card | Lightning Component |
| **Integration Procedure** | Server-side orchestration | Apex Service Layer |
| **Data Mapper** | Data extraction/transformation | SOQL + DML abstraction |

### Architecture Overview

```
                    ┌─────────────────┐
                    │    FlexCard     │  ← Display Layer
                    │  (UI Component) │
                    └────────┬────────┘
                             │ launches
                    ┌────────▼────────┐
                    │   OmniScript    │  ← Interaction Layer
                    │  (Guided Flow)  │
                    └────────┬────────┘
                             │ calls
                    ┌────────▼────────┐
                    │   Integration   │  ← Orchestration Layer
                    │    Procedure    │
                    └────────┬────────┘
                             │ uses
                    ┌────────▼────────┐
                    │   Data Mapper   │  ← Data Layer
                    │ (Extract/Load)  │
                    └────────┬────────┘
                             │ queries/updates
                    ┌────────▼────────┐
                    │   Salesforce    │
                    │     Objects     │
                    └─────────────────┘
```

**Build Order:** Data Mappers → Integration Procedures → OmniScripts → FlexCards

---

## Namespace Detection (Critical First Step)

OmniStudio exists in different namespace variants. **Always detect namespace before any development.**

### Namespace Variants

| Namespace | Package | Industries |
|-----------|---------|------------|
| Core (no prefix) | OmniStudio package | All (Spring '22+) |
| `vlocity_cmt` | Vlocity CMT | Communications, Media, Energy |
| `vlocity_ins` | Vlocity INS | Insurance, Health |

### Detection Queries

Run these in order until one succeeds:

```sql
-- Try Core namespace first (modern)
SELECT Id FROM OmniProcess LIMIT 1

-- If Core fails, try Vlocity CMT
SELECT Id FROM vlocity_cmt__OmniScript__c LIMIT 1

-- If CMT fails, try Vlocity INS
SELECT Id FROM vlocity_ins__OmniScript__c LIMIT 1
```

An `INVALID_TYPE` error means that namespace isn't installed.

### Object Name Mapping

| Concept | Core | vlocity_cmt | vlocity_ins |
|---------|------|-------------|-------------|
| OmniScript/IP | `OmniProcess` | `vlocity_cmt__OmniScript__c` | `vlocity_ins__OmniScript__c` |
| Elements | `OmniProcessElement` | `vlocity_cmt__Element__c` | `vlocity_ins__Element__c` |
| FlexCard | `OmniUiCard` | `vlocity_cmt__VlocityUITemplate__c` | `vlocity_ins__VlocityUITemplate__c` |
| Data Mapper | `OmniDataTransform` | `vlocity_cmt__DRBundle__c` | `vlocity_ins__DRBundle__c` |

---

## Data Mappers (DataRaptors)

Data Mappers are the foundation of OmniStudio data operations.

### Data Mapper Types

| Type | Purpose | Example Use Case |
|------|---------|-----------------|
| **Extract** | Query Salesforce records | Get account with contacts |
| **Turbo Extract** | High-performance queries | Large record sets (10x faster) |
| **Transform** | Reshape JSON data | Map external API response |
| **Load** | Insert/Update/Upsert/Delete | Save form data |

### Creating an Extract Data Mapper

**Step 1: Configure Input**
```json
{
  "AccountId": "001xx000003ABC"
}
```

**Step 2: Define Extract**
```
Object: Account
Fields: Id, Name, Industry, BillingCity
Filter: Id = :AccountId
```

**Step 3: Configure Output Mapping**
```json
{
  "account": {
    "id": "Id",
    "name": "Name",
    "industry": "Industry",
    "city": "BillingCity"
  }
}
```

### Turbo Extract Limitations

Turbo Extract does NOT support:
- [ ] Formula fields
- [ ] Related lists (child queries)
- [ ] Aggregate functions
- [ ] Polymorphic fields
- [ ] SOSL

**Use standard Extract when these are needed.**

### Load Data Mapper Operations

| Operation | Use When |
|-----------|----------|
| Insert | Always creating new records |
| Update | Always updating existing records |
| Upsert | May create or update (uses External ID) |
| Delete | Removing records |

### Data Mapper Naming Convention

```
DR_[Type]_[Object]_[Purpose]

Examples:
DR_Extract_Account_WithContacts
DR_Load_Case_CreateNew
DR_Transform_ExternalAPI_Response
DR_TurboExtract_Opportunity_List
```

### Data Mapper Best Practices

| Do | Don't |
|----|-------|
| ✅ Add LIMIT to all Extracts | ❌ Query all records |
| ✅ Filter to needed records | ❌ Filter in Integration Procedure |
| ✅ Select only needed fields | ❌ Select all fields |
| ✅ Use External IDs for upsert | ❌ Rely on Salesforce IDs |
| ✅ Test with bulk data | ❌ Assume single record |
| ✅ Activate after deployment | ❌ Leave inactive |

---

## Integration Procedures

Integration Procedures orchestrate Data Mappers, Apex, and HTTP calls.

### Identification

Every IP has a **Type / SubType** pair:
```
AccountOnboarding / Standard
CaseManagement / CreateCase
CustomerSearch / ByEmail
```

### Element Types

| Element | Purpose | Key Configuration |
|---------|---------|-------------------|
| **DataRaptor Extract** | Query data | `bundle` (DM name) |
| **DataRaptor Load** | Write data | `bundle` |
| **DataRaptor Transform** | Reshape data | `bundle` |
| **Remote Action** | Call Apex | `remoteClass`, `remoteMethod` |
| **IP Action** | Call nested IP | `ipMethod` |
| **HTTP Action** | External API | `path`, `method` |
| **Set Values** | Assign variables | Key-value pairs |
| **Conditional Block** | Branching | Condition expression |
| **Loop Block** | Iteration | Loop source path |
| **Response Action** | Return data | Output mapping |

### Element Execution Flow

```
┌─────────────────────────────────────────────┐
│  Integration Procedure: Case_CreateNew      │
├─────────────────────────────────────────────┤
│  1. Set Values (prepare input)              │
│         │                                   │
│         ▼                                   │
│  2. DR Extract (validate account)           │
│         │                                   │
│         ▼                                   │
│  3. Conditional (account exists?)           │
│         │ Yes              │ No             │
│         ▼                  ▼                │
│  4a. DR Load (create case) 4b. Response     │
│         │                  (error)          │
│         ▼                                   │
│  5. Response (success)                      │
└─────────────────────────────────────────────┘
```

### Referencing Element Outputs

Each element's output is namespaced under its element name:

```
Element "GetAccount" returns: { "Name": "ACME" }

Reference in next element: %GetAccount:Name%
```

### Parallel Execution

Enable parallel execution for independent elements:
```
┌──────────────────────────────────────────┐
│  Parallel Block                          │
│  ┌────────────────┐  ┌────────────────┐ │
│  │ Get Account    │  │ Get Products   │ │
│  │ (Extract)      │  │ (Extract)      │ │
│  └────────────────┘  └────────────────┘ │
└──────────────────────────────────────────┘
```

### Caching Integration Procedures

Enable caching for read-heavy IPs:
- Set `cacheType`: `session` or `org`
- Set `cacheTTL`: Time in seconds

**⚠️ Warning:** NEVER cache IPs that perform DML. Cached results bypass actual operations!

### IP Best Practices

| Do | Don't |
|----|-------|
| ✅ Set LIMIT on all Extracts | ❌ Unbounded queries |
| ✅ Handle errors gracefully | ❌ Let failures bubble up |
| ✅ Use Named Credentials | ❌ Hardcode credentials |
| ✅ Log for debugging | ❌ Silent failures |
| ✅ Use parallel execution | ❌ Sequential independent calls |

---

## OmniScripts

OmniScripts create multi-step guided experiences.

### Identification

OmniScripts use a **Type / SubType / Language** triplet:
```
ServiceRequest / NewCase / English
CustomerOnboarding / Individual / Spanish
```

### Element Structure

| Concept | Description |
|---------|-------------|
| **Step** | Page in the wizard (Level 0) |
| **Element** | Input/display within step (Level 1+) |
| **Level** | Nesting depth (0 = Step) |
| **Order** | Sequence within level |

### Common Element Types

**Input Elements:**
- Text, Text Area, Number, Currency
- Date, DateTime, Time
- Checkbox, Radio, Select, Multi-select
- File Upload, Signature
- Type Ahead (autocomplete)

**Display Elements:**
- Text Block, Headline
- Image, Chart
- Aggregate (summary)

**Action Elements:**
- Integration Procedure Action
- DataRaptor Extract/Load Action
- Navigate Action
- Set Values

### Data Flow

OmniScripts maintain a JSON data object passed through all steps:

```json
{
  "Step1": {
    "CustomerName": "John Doe",
    "Email": "john@example.com"
  },
  "Step2": {
    "ProductSelection": "Premium"
  },
  "AccountId": "001xx000003ABC"
}
```

Reference values using merge syntax: `%CustomerName%`, `%Step1:Email%`

### LWC-Enabled OmniScripts

Modern OmniScripts use LWC rendering:

| Feature | Aura OmniScript | LWC OmniScript |
|---------|-----------------|----------------|
| Performance | Slower | Faster |
| CSS | Custom classes | SLDS tokens |
| Embedding | Aura components | LWC only |
| Base component | `omniscript` | `omnistudio-omniscript` |

### Conditional Visibility

Show/hide elements based on conditions:
```
Show when: %ProductType% = "Enterprise"
```

### Validation

Add validation formulas to inputs:
```
Formula: REGEX(%Email%, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
Message: "Please enter a valid email address"
```

### OmniScript Best Practices

| Do | Don't |
|----|-------|
| ✅ 7-10 inputs per step max | ❌ Overwhelming single step |
| ✅ Load data on step entry | ❌ Load everything upfront |
| ✅ Use conditional visibility | ❌ Show everything always |
| ✅ Add validation on required fields | ❌ Accept invalid data |
| ✅ Configure error handling | ❌ Silent failures |
| ✅ Use reusable subcomponents | ❌ Duplicate logic |

---

## FlexCards

FlexCards display data in configurable UI cards.

### Data Sources

| Type | Use Case | Configuration |
|------|----------|---------------|
| Integration Procedure | Live data | `dataSource.value.ipMethod` |
| SOQL | Direct queries | `dataSource.value.query` |
| Apex Remote | Custom logic | `dataSource.value.className` |
| REST | External APIs | `dataSource.value.path` |

### Layout Types

| Layout | Description |
|--------|-------------|
| **Single Card** | One card with data |
| **Card List** | Multiple cards from array |
| **Tabbed Card** | Multiple views as tabs |
| **Flyout Card** | Expandable detail panel |

### FlexCard Actions

| Action | Purpose |
|--------|---------|
| OmniScript Launch | Open OmniScript |
| Navigate | Go to record/page |
| CustomRemote | Call Apex |
| Integration Procedure | Execute IP |

### Context Variables

| Variable | Value |
|----------|-------|
| `{recordId}` | Current record ID |
| `{userId}` | Current user ID |
| `{accountId}` | Account context |

### FlexCard Best Practices

| Do | Don't |
|----|-------|
| ✅ Configure empty state | ❌ Show blank cards |
| ✅ Use SLDS design tokens | ❌ Hardcode colors |
| ✅ Add aria-labels | ❌ Ignore accessibility |
| ✅ Limit nesting to 2 levels | ❌ Deep card hierarchies |

---

## Dependency Mapping

### Finding Dependencies

| Component | Where to Look |
|-----------|--------------|
| OmniScript | `PropertySetConfig` → `bundle`, `ipMethod` |
| Integration Procedure | `PropertySetConfig` → `bundle`, `remoteClass` |
| FlexCard | `DataSourceConfig` → `dataSource.value.*` |
| Data Mapper | `OmniDataTransformItem` → Object names |

### Impact Analysis Queries

```sql
-- Find OmniScripts using a Data Mapper
SELECT Id, Name, Type, SubType
FROM OmniProcess
WHERE PropertySetConfig LIKE '%DR_Extract_Account%'
  AND IsIntegrationProcedure = false

-- Find IPs using a Data Mapper
SELECT Id, Name, Type, SubType
FROM OmniProcess
WHERE PropertySetConfig LIKE '%DR_Extract_Account%'
  AND IsIntegrationProcedure = true

-- Find FlexCards using an IP
SELECT Id, Name
FROM OmniUiCard
WHERE DataSourceConfig LIKE '%Case_GetDetails%'
```

---

## Debugging & Troubleshooting

### Common Issues

| Symptom | Likely Cause | Solution |
|---------|--------------|----------|
| "Bundle not found" | Data Mapper not active | Activate the Data Mapper |
| "IP not found" | Wrong Type_SubType format | Check exact naming |
| Empty results | Missing input parameters | Verify context passing |
| Slow performance | Unbounded queries | Add LIMIT and filters |
| LWC render errors | Aura components in LWC OS | Use LWC-compatible elements |

### Console Logging

Enable OmniScript debug mode:
1. Add `?debug=true` to URL
2. Open browser console
3. Filter for `OmniScript`

### Execution Tracing

```sql
-- Check last execution times
SELECT Id, Name, LastModifiedDate
FROM OmniProcess
WHERE Type = 'MyType'
ORDER BY LastModifiedDate DESC
```

---

## Deployment

### Deployment Order (Critical)

```
1. Data Mappers (no dependencies)
2. Integration Procedures (depend on Data Mappers)
3. OmniScripts (depend on IPs)
4. FlexCards (depend on OmniScripts/IPs)
```

### Activation After Deployment

Components deploy inactive by default. Activate after deployment:

```sql
-- Check activation status
SELECT Id, Name, Type, SubType, IsActive
FROM OmniProcess
WHERE Type = 'MyType'
```

### Migration Between Orgs

1. Export components using IDX Workbench or VS Code
2. Resolve namespace differences
3. Deploy in dependency order
4. Activate components
5. Test all dependent components

---

## Common Mistakes & Fixes

### Mistake 1: Circular Dependencies
```
❌ Problem: IP A calls IP B, IP B calls IP A
✅ Fix: Refactor to shared subprocedure
```

### Mistake 2: Caching DML Operations
```
❌ Problem: Cached IP with Load Data Mapper
✅ Fix: Only cache read-only IPs
```

### Mistake 3: Hardcoded Record IDs
```
❌ Problem: Record ID from sandbox in production
✅ Fix: Query by External ID or Name
```

### Mistake 4: Missing Error Handling
```
❌ Problem: Failed IP shows no error to user
✅ Fix: Add Response Action with error mapping
```

### Mistake 5: Wrong Namespace
```
❌ Problem: Query fails with INVALID_TYPE
✅ Fix: Run namespace detection first
```