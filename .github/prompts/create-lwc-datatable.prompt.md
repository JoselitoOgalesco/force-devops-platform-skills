---
description: 'Create an LWC datatable component with Apex controller, search, pagination, and row actions. Use when: displaying records in table, building list view, need CRUD datatable.'
---

# Create LWC Datatable Component

Create a Lightning Web Component with a datatable for displaying and managing records.

## Input

- **Component Name**: ${input:componentName:The LWC name in camelCase (e.g., contactList, orderItems)}
- **Object Name**: ${input:objectName:The SObject API name (e.g., Contact, Order_Item__c)}
- **Fields**: ${input:fields:Comma-separated field API names to display}
- **Features**: ${input:features:Features to include|search,pagination,rowActions,inlineEdit}

## Requirements

### LWC Component

1. **Meta Configuration**
   - API Version: 62.0
   - Targets: `lightning__AppPage`, `lightning__RecordPage`, `lightning__Tab`
   - Include `masterLabel` and `description`

2. **Features**
   - Lightning datatable with sortable columns
   - Search input with debounce (300ms)
   - Row actions: View, Edit, Delete
   - Loading spinner during data fetch
   - Empty state message
   - Error handling with toast notifications

3. **JavaScript**
   - Use `@wire` for data binding
   - Use `@track` for reactive properties
   - Extend `NavigationMixin` for record navigation
   - Use `refreshApex` after mutations

### Apex Controller

1. **Methods**
   - `@AuraEnabled(cacheable=true)` for read operations
   - `@AuraEnabled` for mutations
   - Wrap service class methods

2. **Security**
   - Use existing service class or create one
   - Apply CRUD/FLS checks

## Output

Create these files:
1. `force-app/main/default/lwc/{componentName}/{componentName}.html`
2. `force-app/main/default/lwc/{componentName}/{componentName}.js`
3. `force-app/main/default/lwc/{componentName}/{componentName}.css`
4. `force-app/main/default/lwc/{componentName}/{componentName}.js-meta.xml`
5. `force-app/main/default/classes/{ObjectName}Controller.cls` (if not exists)
6. `force-app/main/default/classes/{ObjectName}Controller.cls-meta.xml`
