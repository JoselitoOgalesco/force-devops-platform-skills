---
applyTo: "**/*Test.cls"
---

# Apex Test Class Standards

## Class Structure

```apex
/**
 * @description Test class for {ClassName}
 * @author AI generated for Force.com DevOps Platform Team
 * @date YYYY-MM-DD
 */
@IsTest
private class ClassNameTest {

    @TestSetup
    static void setupTestData() {
        // Create shared test data
    }

    @IsTest
    static void testMethodNamePositive() {
        // Arrange
        // Act
        Test.startTest();
        // ... invoke method
        Test.stopTest();
        // Assert
    }
}
```

## Test Method Naming

Use descriptive names without underscores:
- ✅ `testCreateAccountsSuccess`
- ✅ `testCreateAccountsWithNullInput`
- ✅ `testBulkInsertExceedsLimit`
- ❌ `test_Create_Accounts_Success`
- ❌ `testMethod1`

## @TestSetup Pattern

```apex
@TestSetup
static void setupTestData() {
    // Create parent records first
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    // Create child records
    List<Contact> contacts = new List<Contact>();
    for (Integer i = 0; i < 5; i++) {
        contacts.add(new Contact(
            FirstName = 'Test',
            LastName = 'Contact ' + i,
            AccountId = testAccount.Id
        ));
    }
    insert contacts;
}
```

## Governor Limit Isolation

Always wrap the code under test:

```apex
@IsTest
static void testBulkOperation() {
    List<Account> accounts = [SELECT Id FROM Account];

    Test.startTest();
    // This resets governor limits
    MyService.processAccounts(accounts);
    Test.stopTest();

    // Assert after stopTest to ensure async operations complete
    System.assertEquals(expected, actual, 'Description of what failed');
}
```

## Bulk Testing

Test with 200+ records to catch bulkification issues:

```apex
@IsTest
static void testBulkInsert() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 200; i++) {
        accounts.add(new Account(Name = 'Bulk Test ' + i));
    }

    Test.startTest();
    Database.SaveResult[] results = MyService.createAccounts(accounts);
    Test.stopTest();

    Integer successCount = 0;
    for (Database.SaveResult sr : results) {
        if (sr.isSuccess()) successCount++;
    }
    System.assertEquals(200, successCount, 'All records should succeed');
}
```

## Assertions

Use `System.assertEquals` with descriptive messages:

```apex
// Good - includes failure description
System.assertEquals(expectedValue, actualValue, 'Account Name should match input');
System.assertNotEquals(null, result, 'Result should not be null');
System.assert(results.size() > 0, 'Should return at least one record');

// Bad - no context on failure
System.assertEquals(expectedValue, actualValue);
```

## Testing Exceptions

```apex
@IsTest
static void testInvalidInputThrowsException() {
    Boolean exceptionThrown = false;

    Test.startTest();
    try {
        MyService.processAccounts(null);
    } catch (IllegalArgumentException e) {
        exceptionThrown = true;
        System.assert(e.getMessage().contains('cannot be null'),
            'Exception message should indicate null input');
    }
    Test.stopTest();

    System.assert(exceptionThrown, 'Should throw exception for null input');
}
```

## Testing Private Methods

Use `@TestVisible`:

```apex
// In the class under test
@TestVisible
private static Boolean validateInput(List<Account> accounts) {
    // ...
}

// In test class
@IsTest
static void testValidateInput() {
    Boolean result = MyService.validateInput(new List<Account>());
    System.assertEquals(false, result, 'Empty list should fail validation');
}
```

## Mocking HTTP Callouts

```apex
@IsTest
static void testExternalCallout() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponse());

    Test.startTest();
    String result = MyService.callExternalApi();
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return response');
}

private class MockHttpResponse implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"success": true}');
        res.setStatusCode(200);
        return res;
    }
}
```

## Coverage Target

- Minimum: 75% (deployment requirement)
- Target: 90%+ (best practice)
- Focus on: Meaningful assertions, not just line coverage
