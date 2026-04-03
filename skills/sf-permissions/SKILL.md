---
name: sf-permissions
description: |
  Manage and audit Salesforce permissions: Permission Sets, Profiles, Permission
  Set Groups, object/field-level security (CRUD/FLS), custom permissions, and
  access troubleshooting.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, permissions, fls, crud, security
---

# Salesforce Permission Management

Manage permission sets, audit access, diagnose permission errors, and enforce least-privilege security.

## Permission Model Overview

| Layer | Controls | Scope |
|-------|----------|-------|
| **Profiles** | Login hours, IP ranges, layouts, record types | One per user (required) |
| **Permission Sets** | Object CRUD, FLS, Apex class, VF page, tab access | Many per user (additive) |
| **Permission Set Groups** | Bundle of Permission Sets + optional muting | Many per user (additive) |

**Best Practice: Minimal Profile + Permission Sets.** Assign a stripped-down profile and grant everything through Permission Sets and Groups.

### Why Permission Sets Over Profiles
- A user can have only ONE profile but MANY permission sets
- Permission sets are additive and composable
- Profiles cause merge conflicts in source control
- Permission Set Groups enable role-based bundling with muting for exceptions
- Salesforce is actively deprecating profile-based permissions

## Permission Set XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Order Manager</label>
    <description>Full CRUD on Order__c, read on Account</description>
    <hasActivationRequired>false</hasActivationRequired>
    <license>Salesforce</license>

    <!-- Object Permissions -->
    <objectPermissions>
        <object>Order__c</object>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>

    <!-- Field-Level Security -->
    <fieldPermissions>
        <field>Order__c.Amount__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>
    <fieldPermissions>
        <field>Order__c.Status__c</field>
        <editable>true</editable>
        <readable>true</readable>
    </fieldPermissions>

    <!-- Tab Visibility -->
    <tabSettings>
        <tab>Order__c</tab>
        <visibility>Visible</visibility>
    </tabSettings>

    <!-- Apex Class Access -->
    <classAccesses>
        <apexClass>OrderService</apexClass>
        <enabled>true</enabled>
    </classAccesses>

    <!-- Visualforce Page Access -->
    <pageAccesses>
        <apexPage>OrderEntryPage</apexPage>
        <enabled>true</enabled>
    </pageAccesses>

    <!-- Custom Permissions -->
    <customPermissions>
        <name>Bypass_Validation</name>
        <enabled>true</enabled>
    </customPermissions>

    <!-- User Permissions -->
    <userPermissions>
        <name>RunReports</name>
        <enabled>true</enabled>
    </userPermissions>
</PermissionSet>
```

## Permission Set Group XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSetGroup xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Sales Team</label>
    <description>All permissions for sales reps</description>
    <status>Updated</status>
    <permissionSets>
        <permissionSet>Account_Reader</permissionSet>
        <permissionSet>Opportunity_Manager</permissionSet>
        <permissionSet>Report_Viewer</permissionSet>
    </permissionSets>
    <mutingPermissionSet>Sales_Team_Muting</mutingPermissionSet>
</PermissionSetGroup>
```

### Muting Permission Set

A muting permission set **removes** specific permissions from the group. Only works inside a Permission Set Group.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Sales Team Muting</label>
    <description>Removes delete access from Opportunity_Manager</description>
    <objectPermissions>
        <object>Opportunity</object>
        <allowDelete>true</allowDelete>
        <!-- "true" in muting PS means MUTE this permission -->
    </objectPermissions>
</PermissionSet>
```

## CRUD Permissions Hierarchy

```
Read ─── required for ──→ Edit ─── required for ──→ Delete
 │                          │
 └── viewAllRecords         └── modifyAllRecords
     (bypasses sharing)         (bypasses sharing + ownership)
```

## Field-Level Security (FLS)

Each field has two flags: **Readable** and **Editable** (Editable requires Readable).

FLS applies across:
- Lightning UI
- Reports and dashboards
- List views
- API access

A field hidden by FLS returns `null` in SOQL with `WITH USER_MODE`.

## Custom Permissions

Boolean flags
 control feature access without code changes.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomPermission xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Can Export Data</label>
    <description>Allows user to export data from custom UI</description>
    <isLicensed>false</isLicensed>
</CustomPermission>
```

### Checking Custom Permissions

**Apex (preferred):**
```apex
if (FeatureManagement.checkPermission('Can_Export_Data')) {
    // User has the custom permission
}
```

**LWC:**
```javascript
import hasExportPermission from '@salesforce/customPermission/Can_Export_Data';

if (hasExportPermission) {
    // User has permission
}
```

**Flow:** Use `$Permission.Can_Export_Data` in Decision elements (returns `true`/`false`).

## Access Auditing Queries

### Permission Set Assignments
```sql
-- All users with a permission set
SELECT Assignee.Name, Assignee.Username, Assignee.IsActive
FROM PermissionSetAssignment
WHERE PermissionSet.Name = 'Order_Manager'

-- All permission sets for a user (excluding profile-based)
SELECT PermissionSet.Label, PermissionSet.Name
FROM PermissionSetAssignment
WHERE AssigneeId = '005xx000001234AAA'
AND PermissionSet.IsOwnedByProfile = false
```

### Object Permissions
```sql
-- Who has Delete on an object?
SELECT Parent.Label, PermissionsDelete, PermissionsModifyAllRecords
FROM ObjectPermissions
WHERE SobjectType = 'Account'
AND PermissionsDelete = true

-- Check for over-privileged ModifyAllRecords
SELECT Parent.Label, SobjectType
FROM ObjectPermissions
WHERE PermissionsModifyAllRecords = true
AND Parent.IsOwnedByProfile = false
```

### Field Permissions
```sql
-- Field permissions for a permission set
SELECT SobjectType, Field, PermissionsRead, PermissionsEdit
FROM FieldPermissions
WHERE Parent.Name = 'Order_Manager'

-- Who can edit a sensitive field?
SELECT Parent.Label
FROM FieldPermissions
WHERE Field = 'Contact.SSN__c'
AND PermissionsEdit = true
```

### Apex/VF Class Access
```sql
-- Who has access to an Apex class?
SELECT Parent.Label
FROM SetupEntityAccess
WHERE SetupEntityType = 'ApexClass'
AND SetupEntityId IN (SELECT Id FROM ApexClass WHERE Name = 'OrderService')
```

## Permission Troubleshooting

### INSUFFICIENT_ACCESS_OR_READONLY
User lacks Edit permission on the object or record.

**Check:**
```sql
SELECT Parent.Label FROM ObjectPermissions
WHERE SobjectType = 'TargetObject__c' AND PermissionsEdit = true
AND ParentId IN (
    SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId
)
```

### INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
User lacks access to a **related** record.

**Common causes:**
- Inserting child without Read on parent
- Changing lookup to a record user can't see
- Trigger/flow updating related record user can't access

### "Insufficient Privileges" Error
Generic error for missing:
- Apex class access
- Visualforce page access
- Lightning component access
- Tab visibility
- Connected App access
- Session-based permission set not activated

```bash
# Quick CLI diagnosis
sf data query -q "SELECT PermissionSet.Label, PermissionSet.Name \
  FROM PermissionSetAssignment \
  WHERE Assignee.Username = 'user@example.com' \
  AND PermissionSet.IsOwnedByProfile = false" -o myOrg
```

## Sharing vs Permissions

Permissions (CRUD/FLS) and sharing are **independent layers**:

| Layer | Question | Scope |
|-------|----------|-------|
| **CRUD** | Can user create/read/edit/delete this object type? | Object-wide |
| **FLS** | Can user see/edit this specific field? | Field-wide |
| **Sharing** | Which specific records can user access? | Record-level |

A user needs BOTH the right CRUD/FLS permissions AND sharing access.

### Organization-Wide Defaults (OWD)

| Setting | Effect |
|---------|--------|
| Private | Only owner + role hierarchy above |
| Public Read Only | All users read, only owner edits |
| Public Read/Write | All users read and edit |
| Controlled by Parent | Determined by parent (master-detail) |

### Record Access Order

```
1. Record owner? → Full access
2. Above owner in role hierarchy? → Access per OWD
3. Sharing rules? → Read or Read/Write
4. Apex managed sharing? → Read or Read/Write
5. View All / Modify All on object? → Bypasses sharing
6. View All Data / Modify All Data? → Full access
```

### Key Distinctions

- `viewAllRecords`/`modifyAllRecords` bypasses sharing for that object
- `with sharing` in Apex enforces sharing but NOT CRUD/FLS
- `WITH USER_MODE` in SOQL enforces both sharing AND CRUD/FLS

## Gotchas

| Issue | Detail |
|-------|--------|
| PSG calculation async | Permission Set Group changes may take minutes. Check `Status` for `Updated` vs `Outdated` |
| Profile merge conflicts | Profile XML files reorder non-deterministically. Prefer permission sets |
| FLS not enforced by default | Apex runs in system mode. Use `WITH USER_MODE` or `stripInaccessible()` |
| Custom permissions cached | Assignment changes may not reflect until user re-authenticates |
| Muting only in groups | Muting permission sets assigned directly have no effect |
| Session-based activation | `hasActivationRequired=true` requires Flow/Apex activation |
| viewAllRecords ≠ FLS | User sees record but not FLS-restricted fields (when enforced) |
| IsOwnedByProfile | Filter with `PermissionSet.IsOwnedByProfile = false` in queries |
| Assignment limit | Maximum 1,000 permission set assignments per user |

## Deployment & Assignment

```bash
# Deploy permission sets
sf project deploy start -d force-app/main/default/permissionsets -o myOrg

# Deploy permission set groups
sf project deploy start -d force-app/main/default/permissionsetgroups -o myOrg

# Assign permission set to user
sf org assign permset --name Order_Manager -o myOrg

# Assign permission set group
sf org assign permsetgroup --name Sales_Team -o myOrg

# Audit assignments
sf data query -q "SELECT Assignee.Name, PermissionSet.Label \
  FROM PermissionSetAssignment \
  WHERE PermissionSet.Name = 'Order_Manager'" -o myOrg
```

## Workflow: Setting Up Permissions for a New Feature

### Step 1: Identify Required Access
List everything the feature needs:
- Objects: which objects will be created/read/updated/deleted?
- Fields: which fields need to be visible/editable?
- Apex classes: which classes does the feature call?
- VF pages/LWC: which UI components are used?
- Tabs: which tabs should be visible?
- Custom permissions: any feature flags needed?

### Step 2: Create Permission Set

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Feature Name Access</label>
    <description>Access for Feature Name functionality</description>
    <hasActivationRequired>false</hasActivationRequired>
    <objectPermissions>...</objectPermissions>
    <fieldPermissions>...</fieldPermissions>
    <classAccesses>...</classAccesses>
</PermissionSet>
```

### Step 3: Create Custom Permissions (If Needed)
For feature flags that control behavior in code:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomPermission xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Can Use Feature</label>
    <description>Controls access to new feature</description>
    <isLicensed>false</isLicensed>
</CustomPermission>
```

### Step 4: Add to Permission Set Group (If Applicable)

```xml
<PermissionSetGroup xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Sales Team</label>
    <permissionSets>
        <permissionSet>Feature_Name_Access</permissionSet>
        ...
    </permissionSets>
</PermissionSetGroup>
```

### Step 5: Deploy and Assign

```bash
sf project deploy start -d force-app/main/default/permissionsets -o myOrg
sf project deploy start -d force-app/main/default/permissionsetgroups -o myOrg
sf org assign permset --name Feature_Name_Access -o myOrg
```

### Step 6: Audit

```bash
sf data query -q "SELECT Assignee.Name, PermissionSet.Label \
  FROM PermissionSetAssignment \
  WHERE PermissionSet.Name = 'Feature_Name_Access'" -o myOrg
```

## Workflow: Migrating from Profile to Permission Sets

### Why Migrate?
- Profiles cause merge conflicts in version control
- Users can only have ONE profile but MANY permission sets
- Permission sets are composable and easier to manage
- Salesforce is deprecating profile-based permissions

### Step 1: Audit Current Profile Permissions

```sql
-- Object permissions on profile
SELECT SobjectType, PermissionsCreate, PermissionsRead,
       PermissionsEdit, PermissionsDelete
FROM ObjectPermissions
WHERE Parent.Profile.Name = 'Sales User'
  AND Parent.IsOwnedByProfile = true

-- Field permissions on profile
SELECT SobjectType, Field, PermissionsRead, PermissionsEdit
FROM FieldPermissions
WHERE Parent.Profile.Name = 'Sales User'
  AND Parent.IsOwnedByProfile = true
```

### Step 2: Create Equivalent Permission Sets
Group permissions by functional area:
- `Sales_Account_Access` — Account object permissions
- `Sales_Opportunity_Access` — Opportunity object permissions
- `Sales_Reports` — Report and Dashboard access

### Step 3: Create Permission Set Group

```xml
<PermissionSetGroup xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Sales User Equivalent</label>
    <permissionSets>
        <permissionSet>Sales_Account_Access</permissionSet>
        <permissionSet>Sales_Opportunity_Access</permissionSet>
        <permissionSet>Sales_Reports</permissionSet>
    </permissionSets>
</PermissionSetGroup>
```

### Step 4: Assign Group to Users

```bash
sf org assign permsetgroup --name Sales_User_Equivalent -o myOrg
```

### Step 5: Strip Profile
Remove object and field permissions from profile, keeping only:
- Login hours
- IP restrictions
- Page layout assignments
- Record type defaults
- Default app

### Step 6: Validate
Test with users to ensure no access regressions.

## Tips for Junior Developers

### Common Permission Mistakes

| Mistake | Result | Fix |
|---------|--------|-----|
| Forgetting to assign permission set | User gets "Insufficient Access" | Check `PermissionSetAssignment` |
| Using profiles for object access | Merge conflicts, hard to manage | Use permission sets instead |
| Missing field permissions | Field shows blank or read-only | Add `fieldPermissions` |
| viewAllRecords but missing FLS | User sees record, but sensitive fields missing | Add field permissions too |
| Muting PS assigned directly | No effect (muting only works in groups) | Add muting PS to group |

### Debugging Access Issues

1. **Check permission set assignments:**
   ```bash
   sf data query -q "SELECT PermissionSet.Label FROM PermissionSetAssignment \
     WHERE AssigneeId = '005...' AND PermissionSet.IsOwnedByProfile = false" -o myOrg
   ```

2. **Check object permissions:**
   ```bash
   sf data query -q "SELECT Parent.Label, PermissionsRead, PermissionsEdit \
     FROM ObjectPermissions WHERE SobjectType = 'Account' \
     AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment \
     WHERE AssigneeId = '005...')" -o myOrg
   ```

3. **Check field permissions:**
   ```bash
   sf data query -q "SELECT Parent.Label, Field, PermissionsRead, PermissionsEdit \
     FROM FieldPermissions WHERE Field = 'Account.Revenue__c' \
     AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment \
     WHERE AssigneeId = '005...')" -o myOrg
   ```

4. **Check sharing access:**
   - Is OWD Private?
   - Is user in role hierarchy above owner?
   - Are there sharing rules?
   - Does user have View All Records?