---
name: sf-security
description: |
  Implement Salesforce security best practices including CRUD/FLS enforcement,
  secure coding, SOQL injection prevention, sharing model configuration,
  Salesforce Shield (Platform Encryption, Event Monitoring), and AppExchange
  security review preparation.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, security, crud-fls, shield, encryption, appexchange, audit
---

# Salesforce Security Guide

Implement comprehensive security in Salesforce applications. This guide covers CRUD/FLS enforcement, sharing models, secure coding practices, Salesforce Shield, and AppExchange security review preparation.

## Understanding Salesforce Security Model

### Security Layers

```
┌────────────────────────────────────────────────────────────┐
│                    ORG LEVEL                               │
│  Login IP Ranges, Password Policies, Session Settings      │
└────────────────────────────────────────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────────┐
│                   OBJECT LEVEL (CRUD)                      │
│  Profiles & Permission Sets: Create, Read, Update, Delete  │
└────────────────────────────────────────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────────┐
│                   FIELD LEVEL (FLS)                        │
│  Field-Level Security: Visible, Read-Only, Hidden          │
└────────────────────────────────────────────────────────────┘
                              ▼
┌────────────────────────────────────────────────────────────┐
│                   RECORD LEVEL                             │
│  OWD, Sharing Rules, Role Hierarchy, Manual Sharing        │
└────────────────────────────────────────────────────────────┘
```

**💡 Junior Developer Tip:** Apex runs in **system mode** by default, bypassing ALL security. You must explicitly enforce security in your code.

---

## CRUD/FLS Enforcement

### The Problem: System Mode

```apex
// ❌ DANGEROUS - Runs in system mode
List<Account> accounts = [SELECT Id, SSN__c FROM Account];
insert accounts;  // No CRUD check
```

Even if a user lacks permission to see SSN__c, this code returns it anyway.

### Solution 1: WITH USER_MODE (Recommended)

```apex
// ✅ SECURE - Enforces CRUD, FLS, and sharing
List<Account> accounts = [
    SELECT Id, Name, Industry
    FROM Account
    WHERE Type = 'Customer'
    WITH USER_MODE
];
```

**What USER_MODE does:**
- Enforces CRUD (throws if no read access)
- Enforces FLS (strips inaccessible fields silently)
- Enforces sharing rules

### Solution 2: stripInaccessible (For DML)

```apex
// ✅ SECURE - Before INSERT
List<Account> recordsToCreate = new List<Account>{ new Account(Name = 'Test') };
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.CREATABLE,
    recordsToCreate
);
insert decision.getRecords();

// ✅ SECURE - Before UPDATE
decision = Security.stripInaccessible(AccessType.UPDATABLE, recordsToUpdate);
update decision.getRecords();

// ✅ SECURE - Before returning data
decision = Security.stripInaccessible(AccessType.READABLE, queryResults);
return decision.getRecords();
```

### Solution 3: Database Methods with AccessLevel

```apex
// ✅ SECURE - DML with user mode
Database.insert(records, AccessLevel.USER_MODE);
Database.update(records, AccessLevel.USER_MODE);
Database.delete(records, AccessLevel.USER_MODE);
```

### Comparison Table

| Method | CRUD | FLS | Sharing | On Violation |
|--------|------|-----|---------|--------------|
| `WITH USER_MODE` | ✅ | ✅ | ✅ | Strips fields |
| `WITH SECURITY_ENFORCED` | ✅ | ✅ | ❌ | Throws exception |
| `stripInaccessible()` | ✅ | ✅ | ❌ | Strips fields |
| `AccessLevel.USER_MODE` | ✅ | ✅ | ✅ | Strips fields |

**Recommendation:** Use `WITH USER_MODE` for queries and `AccessLevel.USER_MODE` for DML.

---

## Sharing Model

### Organization-Wide Defaults (OWD)

| Setting | Who Can See | Who Can Edit |
|---------|-------------|--------------|
| **Private** | Owner + Role Hierarchy | Owner only |
| **Public Read Only** | All users | Owner only |
| **Public Read/Write** | All users | All users |
| **Controlled by Parent** | Inherits from parent | Inherits from parent |

### Apex Sharing Keywords

```apex
// ✅ Enforces sharing rules (use for user-facing operations)
public with sharing class UserService {
    public List<Account> getMyAccounts() {
        return [SELECT Id, Name FROM Account WITH USER_MODE];
    }
}

// ⚠️ Bypasses sharing (document why!)
public without sharing class SystemService {
    /**
     * @description Calculates org-wide statistics.
     *              Must bypass sharing to aggregate all records.
     *              SECURITY REVIEW: Approved - no user data exposed.
     */
    public Integer countAllAccounts() {
        return [SELECT COUNT() FROM Account];
    }
}

// ✅ Inherits from caller (good for utilities)
public inherited sharing class UtilityService {
    public void processRecords(List<SObject> records) {
        // Inherits sharing context from calling class
    }
}
```

### Sharing Enforcement Table

| Keyword | Record Sharing | CRUD/FLS |
|---------|----------------|----------|
| `with sharing` | ✅ Enforced | ❌ Not enforced |
| `without sharing` | ❌ Bypassed | ❌ Not enforced |
| `inherited sharing` | Inherits | ❌ Not enforced |

**⚠️ Important:** `with sharing` does NOT enforce CRUD/FLS! Always combine with `WITH USER_MODE` or `stripInaccessible()`.

---

## SOQL Injection Prevention

### The Vulnerability

```apex
// ❌ VULNERABLE - Never do this!
String userInput = ApexPages.currentPage().getParameters().get('name');
String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';
List<Account> accounts = Database.query(query);

// Attacker input: ' OR Name LIKE '%
// Resulting query: SELECT Id FROM Account WHERE Name = '' OR Name LIKE '%'
```

### Prevention Methods

**1. Bind Variables (Preferred)**
```apex
// ✅ SECURE - Bind variables
String userInput = ApexPages.currentPage().getParameters().get('name');
List<Account> accounts = [
    SELECT Id FROM Account
    WHERE Name = :userInput
    WITH USER_MODE
];
```

**2. Escape for Dynamic Queries**
```apex
// ✅ SECURE - When dynamic SOQL is required
String safeName = String.escapeSingleQuotes(userInput);
String query = 'SELECT Id FROM Account WHERE Name = \'' + safeName + '\'';
List<Account> accounts = Database.query(query, AccessLevel.USER_MODE);
```

**3. Whitelist for Dynamic Field Names**
```apex
// ✅ SECURE - Validate against allowed fields
Set<String> allowedFields = new Set<String>{'Name', 'Industry', 'Type'};
if (!allowedFields.contains(userProvidedField)) {
    throw new SecurityException('Invalid field: ' + userProvidedField);
}
String query = 'SELECT ' + String.escapeSingleQuotes(userProvidedField) + ' FROM Account';
```

---

## Cross-Site Scripting (XSS) Prevention

### Visualforce

```html
<!-- ❌ VULNERABLE -->
<apex:outputText value="{!userInput}" escape="false"/>

<!-- ✅ SECURE - escape is true by default -->
<apex:outputText value="{!userInput}"/>

<!-- ✅ SECURE - For JavaScript context -->
<script>var data = '{!JSENCODE(userInput)}';</script>

<!-- ✅ SECURE - For HTML context -->
{!HTMLENCODE(userInput)}

<!-- ✅ SECURE - For URL parameters -->
<a href="/page?param={!URLENCODE(userInput)}">Link</a>
```

### LWC

LWC automatically escapes content in templates:
```html
<!-- ✅ SECURE - Automatic escaping -->
<p>{userName}</p>

<!-- ⚠️ WARNING - innerHTML bypasses escaping -->
<div lwc:dom="manual"></div>
```

```javascript
// ⚠️ If you must use innerHTML, sanitize first
import { sanitizeHTML } from 'lightning/sanitizer';
this.template.querySelector('div').innerHTML = sanitizeHTML(userContent);
```

---

## Sensitive Data Protection

### Never Log PII

```apex
// ❌ DANGEROUS - PII in debug logs
System.debug('User SSN: ' + contact.SSN__c);
System.debug('Credit Card: ' + payment.CardNumber__c);
System.debug('Full record: ' + JSON.serialize(user));

// ✅ SECURE - Log only IDs and non-sensitive data
System.debug('Processing contact ID: ' + contact.Id);
System.debug('Payment status: ' + payment.Status__c);
```

### Never Hardcode Credentials

```apex
// ❌ DANGEROUS - Hardcoded secrets
String apiKey = 'sk_live_abc123xyz';
req.setHeader('Authorization', 'Bearer ' + apiKey);

// ✅ SECURE - Use Named Credentials
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:MyExternalService/api/resource');
// Auth header added automatically by Named Credential
```

### Protected Custom Settings/Metadata

```apex
// ✅ SECURE - Use Protected Custom Settings for secrets
API_Secrets__c secrets = API_Secrets__c.getOrgDefaults();
// Mark as Protected = true to hide from package subscribers
```

---

## Salesforce Shield

### Platform Encryption

Platform Encryption encrypts data at rest for sensitive fields.

**Encrypted Field Types:**
- Text, Text Area, Long Text Area, Rich Text
- Email, Phone, URL
- Date, DateTime
- Custom picklists (with limitations)

**Considerations:**
- Encrypted fields cannot be used in:
  - SOQL WHERE clauses (unless deterministic)
  - SOQL ORDER BY
  - Formula field references
- Use deterministic encryption for filterable fields

### Event Monitoring

Event Monitoring tracks user activity for security analysis:

| Event Type | What It Tracks |
|------------|----------------|
| Login | User logins, IP addresses |
| Logout | Session terminations |
| API | API calls and responses |
| Report Export | Report downloads |
| Lightning Page View | Page navigation |
| Apex Execution | Apex performance |

**Querying Event Logs:**
```sql
SELECT Id, EventType, LogFile, LogDate
FROM EventLogFile
WHERE EventType = 'Login'
AND LogDate = LAST_N_DAYS:7
```

### Transaction Security Policies

Create policies to monitor and block suspicious activity:

```apex
// Example: Block data export by specific users
global class BlockExportPolicy implements TxnSecurity.PolicyCondition {
    public boolean evaluate(TxnSecurity.Event e) {
        // Return true to block/alert
        return e.getUserId() == RESTRICTED_USER_ID;
    }
}
```

---

## Custom Permission Checks

### Using Feature Management

```apex
// Check if user has custom permission
if (FeatureManagement.checkPermission('Export_Sensitive_Data')) {
    // User is authorized
    return getSensitiveData();
}
throw new SecurityException('You do not have permission to export this data');

// Common patterns
if (FeatureManagement.checkPermission('Bypass_Validation')) {
    return; // Skip validation for authorized users
}

if (FeatureManagement.checkPermission('Admin_Override')) {
    // Allow admin-level operations
}
```

### Custom Permission Metadata

```xml
<!-- customPermissions/Export_Sensitive_Data.customPermission-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomPermission xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Export Sensitive Data</label>
    <description>Allows export of PII and sensitive records</description>
</CustomPermission>
```

---

## Security Audit Checklist

### Code Review Patterns

| Vulnerability | Search Pattern | Fix |
|--------------|----------------|-----|
| Missing sharing | `public\s+class` without `sharing` | Add `with sharing` |
| System mode SOQL | `\[SELECT.*FROM.*\]` without `USER_MODE` | Add `WITH USER_MODE` |
| Unsafe DML | `insert\|update\|delete` without `stripInaccessible` | Add security check |
| SOQL injection | `'SELECT.*'\s*\+` string concat | Use bind variables |
| Hardcoded credentials | `api[Kk]ey\|password\|secret\|token` | Use Named Credentials |
| PII in logs | `System\.debug.*SSN\|Password\|Secret` | Remove PII |

### AppExchange Security Review Requirements

- [ ] All classes declare `with sharing` (or document `without sharing`)
- [ ] All SOQL uses `WITH USER_MODE`
- [ ] All DML uses `stripInaccessible()` or `AccessLevel.USER_MODE`
- [ ] No string concatenation in dynamic SOQL
- [ ] No hardcoded credentials or record IDs
- [ ] No PII in debug statements
- [ ] All Visualforce output is escaped
- [ ] External callouts use Named Credentials
- [ ] Custom permissions for sensitive features
- [ ] CSRF protection on Visualforce pages
- [ ] Clickjack protection enabled

### Running Security Scanner

```bash
# Full security scan
sf scanner run --target force-app/ \
  --category "Security,Best Practices" \
  --format csv \
  --outfile security-report.csv

# Fail build on security issues
sf scanner run --target force-app/ \
  --violations-cause-error \
  --severity-threshold 2

# Check specific patterns
sf scanner run --target force-app/ \
  --pmd-category Security
```

---

## Common Mistakes & Fixes

### Mistake 1: Assuming with sharing is Enough
```apex
❌ public with sharing class MyService {
     List<Account> accts = [SELECT Id, SSN__c FROM Account];
   }
   // with sharing enforces records but NOT field access!

✅ public with sharing class MyService {
     List<Account> accts = [SELECT Id, SSN__c FROM Account WITH USER_MODE];
   }
```

### Mistake 2: Forgetting stripInaccessible Returns New List
```apex
❌ Security.stripInaccessible(AccessType.CREATABLE, records);
   insert records;  // Original list unchanged!

✅ SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, records);
   insert decision.getRecords();  // Use returned list
```

### Mistake 3: String Concatenation with USER_MODE
```apex
❌ String query = 'SELECT Id FROM Account WHERE Name = \'' + userInput + '\'';
   Database.query(query, AccessLevel.USER_MODE);
   // USER_MODE doesn't prevent injection!

✅ List<Account> accts = [SELECT Id FROM Account WHERE Name = :userInput WITH USER_MODE];
```

### Mistake 4: Debug Logs Exposing Data
```apex
❌ System.debug('Processing: ' + JSON.serialize(creditCard));
   // Debug logs visible to admins!

✅ System.debug('Processing card ending in: ' + creditCard.Last4__c);
```

---

## Workflow Summary

### Security Implementation Workflow

```
1. DESIGN
   └─ Identify sensitive data fields
   └─ Plan sharing model (OWD, rules)
   └─ Define required permissions

2. IMPLEMENT
   └─ Add `with sharing` to all classes
   └─ Add `WITH USER_MODE` to all SOQL
   └─ Add `stripInaccessible` to all DML
   └─ Use Named Credentials for callouts

3. VALIDATE
   └─ Run security scanner
   └─ Test with different user profiles
   └─ Verify no PII in logs

4. REVIEW
   └─ Code review security patterns
   └─ Document `without sharing` usage
   └─ Pre-submission security check

5. MAINTAIN
   └─ Monitor Event Logs
   └─ Review security reports
   └─ Update for new vulnerabilities
```
