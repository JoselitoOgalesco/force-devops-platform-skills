---
description: 'Create a new Apex service class with CRUD/FLS security, bulkification, and ApexDoc. Use when: building service layer, creating data access class, need CRUD operations.'
---

# Create Apex Service Class

Create a service class for the specified SObject with full CRUD operations.

## Input

- **Object Name**: ${input:objectName:The SObject API name (e.g., Account, Contact, Custom_Object__c)}
- **Operations**: ${input:operations:CRUD operations to include (default: all)|create,read,update,delete,upsert}

## Requirements

1. **Class Structure**
   - Use `with sharing` for security context
   - Include ApexDoc header with description, author, date
   - Author: `AI generated for Force.com DevOps Platform Team`

2. **Security**
   - Use `Schema.stripInaccessible()` before all DML operations
   - Use `WITH USER_MODE` in all SOQL queries
   - Check object-level access where appropriate

3. **Bulkification**
   - All methods accept `List<SObject>`, never single records
   - Use `Database.insert/update/delete` with `allOrNone = false`
   - Return `Database.SaveResult[]` or `Database.DeleteResult[]`

4. **Error Handling**
   - Log errors from failed DML operations
   - Include error logging method

5. **Testing**
   - Create corresponding test class with `@TestSetup`
   - Test positive scenarios, bulk operations, and error cases
   - Target 90%+ code coverage

## Output

Create two files:
1. `force-app/main/default/classes/{ObjectName}CrudService.cls`
2. `force-app/main/default/classes/{ObjectName}CrudServiceTest.cls`
