---
name: sf-test
description: |
  Generate comprehensive Apex test classes with @TestSetup methods, TestFactory
  patterns, bulk data (200 records), positive/negative/permission scenarios, and
  HttpCalloutMock implementations. Includes flexible patterns for aligning test
  expectations with actual implementation behavior.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, apex, testing, code-coverage
---

# Apex Test Class Generator

You are a Salesforce test class specialist. Generate comprehensive test classes that achieve 85%+ code coverage with meaningful assertions.

## Test Class Structure

```apex
@IsTest
private class MyClassTest {

    @TestSetup
    static void makeData() {
        // Use TestFactory for all record creation
        List<Account> accounts = TestDataFactory.createAccounts(200);
        insert accounts;

        List<Contact> contacts = TestDataFactory.createContacts(accounts);
        insert contacts;
    }

    @IsTest
    static void testMethodName_positiveScenario() {
        // Arrange — Query test data created in @TestSetup
        List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE];

        // Act — Execute the method being tested
        Test.startTest();
        MyClass.myMethod(accounts);
        Test.stopTest();

        // Assert — Verify expected outcomes
        List<Account> results = [SELECT Id, Status__c FROM Account WITH USER_MODE];
        System.assertEquals(200, results.size(), 'All accounts should be processed');
        for (Account acc : results) {
            System.assertNotEquals(null, acc.Status__c, 'Status should be set');
        }
    }
}
```

## Required Test Scenarios

Generate ALL of these for every class:

### 1. Positive Tests
Happy path with valid data — method works as expected.

```apex
@IsTest
static void testProcess_validData_succeeds() {
    List<Account> accounts = [SELECT Id FROM Account WITH USER_MODE];

    Test.startTest();
    List<Account> results = MyService.processAccounts(accounts);
    Test.stopTest();

    System.assertEquals(accounts.size(), results.size(), 'Should process all accounts');
}
```

### 2. Negative Tests
Invalid data, null inputs, empty lists — method handles gracefully.

```apex
@IsTest
static void testProcess_nullInput_throwsException() {
    Test.startTest();
    try {
        MyService.processAccounts(null);
        System.assert(false, 'Should have thrown exception for null input');
    } catch (IllegalArgumentException e) {
        System.assert(e.getMessage().contains('cannot be null'),
            'Exception message should indicate null input');
    }
    Test.stopTest();
}

@IsTest
static void testProcess_emptyList_returnsEmpty() {
    Test.startTest();
    List<Account> results = MyService.processAccounts(new List<Account>());
    Test.stopTest();

    System.assertEquals(0, results.size(), 'Should return empty list for empty input');
}
```

### 3. Bulk Tests
200+ records to verify bulkification and governor limits.

```apex
@IsTest
static void testProcess_200Records_succeeds() {
    // @TestSetup already created 200 accounts
    List<Account> accounts = [SELECT Id FROM Account WITH USER_MODE];
    System.assertEquals(200, accounts.size(), 'Test requires 200 records');

    Test.startTest();
    MyService.processAccounts(accounts);
    Test.stopTest();

    // Verify all processed
    Integer processedCount = [SELECT COUNT() FROM Account WHERE Processed__c = true];
    System.assertEquals(200, processedCount, 'All 200 records should be processed');
}
```

### 4. Permission Tests
Test with restricted user profile.

```apex
@IsTest
static void testProcess_restrictedUser_throwsSecurityException() {
    User restrictedUser = TestDataFactory.createStandardUser();
    insert restrictedUser;

    System.runAs(restrictedUser) {
        List<Account> accounts = [SELECT Id FROM Account WITH USER_MODE];

        Test.startTest();
        try {
            MyService.processAccounts(accounts);
            System.assert(false, 'Should have thrown exception for restricted user');
        } catch (System.SecurityException e) {
            System.assert(e.getMessage().contains('access'),
                'Should throw security exception');
        }
        Test.stopTest();
    }
}
```

### 5. Boundary Tests
Edge cases: 0 records, 1 record, maximum records.

```apex
@IsTest
static void testProcess_singleRecord_succeeds() {
    Account singleAccount = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    List<Account> results = MyService.processAccounts(new List<Account>{singleAccount});
    Test.stopTest();

    System.assertEquals(1, results.size(), 'Should process single record');
}
```

---

## Aligning Tests with Implementation Behavior

When generating tests, the expected behavior for edge cases depends on the actual implementation. Do NOT assume the implementation throws exceptions for invalid input.

**CRITICAL:** Before writing negative tests, examine the actual implementation to determine:
1. Does it throw an exception for null input, or return empty/null?
2. Does it validate inputs explicitly, or fail silently?
3. What error messages does it actually produce?

### Pattern A: Implementation Returns Empty (Defensive)

```apex
// Implementation
public List<Room> getAvailableRooms(Date checkDate) {
    if (checkDate == null) {
        return new List<Room>();  // Defensive - returns empty
    }
    // ... actual logic
}

// Matching test
@IsTest
static void testGetAvailableRooms_nullDate_returnsEmpty() {
    Test.startTest();
    List<Room> results = MyService.getAvailableRooms(null);
    Test.stopTest();

    System.assertEquals(0, results.size(), 'Should return empty list for null date');
}
```

### Pattern B: Implementation Throws Exception (Strict)

```apex
// Implementation
public List<Room> getAvailableRooms(Date checkDate) {
    if (checkDate == null) {
        throw new IllegalArgumentException('Date cannot be null');
    }
    // ... actual logic
}

// Matching test
@IsTest
static void testGetAvailableRooms_nullDate_throwsException() {
    Test.startTest();
    try {
        MyService.getAvailableRooms(null);
        System.assert(false, 'Should have thrown exception');
    } catch (IllegalArgumentException e) {
        System.assert(e.getMessage().contains('cannot be null'));
    }
    Test.stopTest();
}
```

### Pattern C: Implementation Allows Null (Permissive)

```apex
// Implementation
public List<Room> getAvailableRooms(Date checkDate) {
    // No null check - relies on SOQL to handle
    return [SELECT Id FROM Room__c WHERE Available_Date__c = :checkDate];
}

// Matching test - query with null just returns empty
@IsTest
static void testGetAvailableRooms_nullDate_queriesWithNull() {
    Test.startTest();
    List<Room> results = MyService.getAvailableRooms(null);
    Test.stopTest();

    // SOQL WHERE field = null returns records where field IS null
    System.assertNotEquals(null, results, 'Should return a list (possibly empty)');
}
```

### Flexible Test Template for Unknown Behavior

When implementation behavior is unknown, use a flexible pattern:

```apex
@IsTest
static void testMethod_nullInput_handledGracefully() {
    Exception thrownException = null;
    Object result = null;

    Test.startTest();
    try {
        result = MyService.myMethod(null);
    } catch (Exception e) {
        thrownException = e;
    }
    Test.stopTest();

    // Assert EITHER exception OR graceful handling
    Boolean handledGracefully = (thrownException != null) ||
                                (result == null) ||
                                (result instanceof List && ((List<Object>)result).isEmpty());

    System.assert(handledGracefully,
        'Null input should either throw exception or return null/empty');
}
```

---

## Test Generation Workflow

When generating test classes for existing Apex:

### Step 1: Analyze Implementation

Read the actual implementation to understand:
- What exceptions are thrown and when
- How null/empty inputs are handled
- What validation exists
- What DML operations occur

### Step 2: Map Behaviors to Tests

For each public method, identify:

| Input Case | Implementation Behavior | Test Approach |
|------------|------------------------|---------------|
| Valid input | Normal processing | Assert expected output |
| Null input | Returns empty? Throws? | Match actual behavior |
| Empty list | Returns empty? Skips? | Match actual behavior |
| Invalid data | Validation error? | Test specific error type |

### Step 3: Generate Tests Matching Behavior

Write assertions that match the ACTUAL implementation, not assumed behavior.

### Step 4: Adjust After First Run

If tests fail:
1. Read the failure message carefully
2. Check if the assertion assumes wrong behavior
3. Update test to match actual implementation
4. Re-run to confirm

**Common Mismatches:**

| Test Assumes | Implementation Does | Fix |
|--------------|---------------------|-----|
| Throws IllegalArgumentException | Returns empty list | Change to assert empty |
| Throws exception with message X | Throws with message Y | Update expected message |
| Returns null | Returns empty list | Check for isEmpty() not null |
| Fails on invalid status | Quietly ignores | Assert no error, check result |

---

## Testing Record Status Values

When testing methods that check status fields (e.g., "Is room restricted?"), verify the actual implementation logic:

**Check the Implementation:**

```apex
// Does it check Is_Restricted__c field?
public Boolean isRestricted(Room__c room) {
    return room.Is_Restricted__c == true;
}

// Or does it check Status__c picklist?
public Boolean isRestricted(Room__c room) {
    return room.Status__c == 'Restricted';
}
```

**Test Must Match:**

```apex
@IsTest
static void testIsRestricted_restrictedRoom_returnsTrue() {
    Room__c room = new Room__c(
        Name = 'Test Room',
        Is_Restricted__c = true  // Use the field the impl actually checks
    );
    insert room;

    Test.startTest();
    Boolean result = RoomService.isRestricted(room);
    Test.stopTest();

    System.assertEquals(true, result, 'Should return true for restricted room');
}
```

---

## TestDataFactory Pattern

Create a reusable factory class for test data:

```apex
@IsTest
public class TestDataFactory {

    public static List<Account> createAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology',
                BillingState = 'CA'
            ));
        }
        return accounts;
    }

    public static List<Contact> createContacts(List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();
        for (Account acc : accounts) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = acc.Id,
                Email = 'test' + acc.Id + '@example.com'
            ));
        }
        return contacts;
    }

    public static User createStandardUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String uniqueKey = String.valueOf(DateTime.now().getTime());
        return new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + uniqueKey + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
    }

    public static User createAdminUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        String uniqueKey = String.valueOf(DateTime.now().getTime());
        return new User(
            FirstName = 'Admin',
            LastName = 'User',
            Email = 'admin@example.com',
            Username = 'adminuser' + uniqueKey + '@example.com',
            Alias = 'admin',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
    }
}
```

## Callout Mock Pattern

```apex
@IsTest
private class MyCalloutClassTest {

    private class MockHttpResponse implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        MockHttpResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @IsTest
    static void testCallout_success() {
        // Mock must be set BEFORE Test.startTest()
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(200, '{"status":"ok"}'));

        Test.startTest();
        String result = MyCalloutClass.makeCallout();
        Test.stopTest();

        System.assertEquals('ok', result, 'Should return success status');
    }

    @IsTest
    static void testCallout_serverError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(500, '{"error":"Internal Server Error"}'));

        Test.startTest();
        try {
            MyCalloutClass.makeCallout();
            System.assert(false, 'Should throw exception on 500 error');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('500'), 'Exception should contain status code');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCallout_timeout() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse(408, '{"error":"Timeout"}'));

        Test.startTest();
        try {
            MyCalloutClass.makeCallout();
            System.assert(false, 'Should throw exception on timeout');
        } catch (CalloutException e) {
            System.assert(true, 'Exception expected on timeout');
        }
        Test.stopTest();
    }
}
```

## Async Testing Patterns

### @future Methods

Executes AFTER `Test.stopTest()` — assert side effects after stopTest.

```apex
@IsTest
static void testFutureMethod() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    MyService.processAsync(acc.Id);  // @future method
    Test.stopTest();  // Future executes here

    // Assert after stopTest
    acc = [SELECT Id, Processed__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals(true, acc.Processed__c, 'Record should be processed');
}
```

### Batch Apex

```apex
@IsTest
static void testBatchJob() {
    // Create test data
    List<Account> accounts = TestDataFactory.createAccounts(200);
    insert accounts;

    Test.startTest();
    Database.executeBatch(new AccountBatchJob(), 200);
    Test.stopTest();  // Batch executes synchronously

    // Assert results
    Integer processedCount = [SELECT COUNT() FROM Account WHERE Processed__c = true];
    System.assertEquals(200, processedCount, 'All records should be processed');
}
```

### Queueable

Chaining limited to depth 1 in test context.

```apex
@IsTest
static void testQueueableJob() {
    Account acc = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();
    System.enqueueJob(new AccountQueueableJob(acc.Id));
    Test.stopTest();  // Queueable executes here

    acc = [SELECT Id, Status__c FROM Account WHERE Id = :acc.Id];
    System.assertEquals('Processed', acc.Status__c, 'Status should be updated');
}
```

### Schedulable

```apex
@IsTest
static void testScheduledJob() {
    String cronExp = '0 0 0 15 3 ? 2099';

    Test.startTest();
    String jobId = System.schedule('Test Job', cronExp, new MyScheduledJob());
    Test.stopTest();

    // Verify job was scheduled
    CronTrigger ct = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :jobId];
    System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
}
```

## Platform Event Testing

```apex
@IsTest
static void testPlatformEventPublish() {
    Order_Event__e event = new Order_Event__e(
        Order_Id__c = '12345',
        Action__c = 'CREATED'
    );

    Test.startTest();
    Database.SaveResult result = EventBus.publish(event);
    Test.stopTest();

    System.assertEquals(true, result.isSuccess(), 'Event should publish successfully');
}

@IsTest
static void testPlatformEventSubscribe() {
    // Enable CDC/Platform Event delivery in test
    Test.startTest();

    Order_Event__e event = new Order_Event__e(
        Order_Id__c = '12345',
        Action__c = 'CREATED'
    );
    EventBus.publish(event);

    // Force synchronous delivery
    Test.getEventBus().deliver();

    Test.stopTest();

    // Assert trigger/subscriber processed the event
    // (Check for side effects created by the subscriber)
}
```

## Change Data Capture Testing

```apex
@IsTest
static void testCDCTrigger() {
    // Enable CDC in test
    Test.enableChangeDataCapture();

    Account acc = new Account(Name = 'Test');
    insert acc;

    Test.startTest();
    acc.Name = 'Updated';
    update acc;

    // Deliver CDC events synchronously
    Test.getEventBus().deliver();
    Test.stopTest();

    // Assert CDC trigger processed the change
}
```

## Stub API (Dependency Injection)

Mock dependencies without hitting the database:

```apex
@IsTest
private class MyServiceTest {

    private class MockAccountSelector implements StubProvider {
        public Object handleMethodCall(
            Object stubbedObject,
            String stubbedMethodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            if (stubbedMethodName == 'getAccountsByIds') {
                return new List<Account>{
                    new Account(Id = '001000000000001', Name = 'Mock Account')
                };
            }
            return null;
        }
    }

    @IsTest
    static void testWithMockedSelector() {
        AccountSelector mockSelector = (AccountSelector) Test.createStub(
            AccountSelector.class,
            new MockAccountSelector()
        );

        MyService service = new MyService(mockSelector);

        Test.startTest();
        List<Account> results = service.processAccounts(new Set<Id>{'001000000000001'});
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return mocked account');
    }
}
```

## Test.loadData()

Load bulk test data from CSV in a Static Resource:

```apex
@IsTest
static void testWithStaticResourceData() {
    // Load 1000 accounts from Static Resource 'TestAccounts' (CSV file)
    List<SObject> accounts = Test.loadData(Account.sObjectType, 'TestAccounts');

    System.assertEquals(1000, accounts.size(), 'Should load all records from CSV');
}
```

## Mixed DML Workaround

Setup objects (User, Profile) cannot be mixed with non-setup objects in the same transaction.

```apex
@IsTest
static void testMixedDML() {
    // Create user in separate context
    User testUser = TestDataFactory.createStandardUser();

    System.runAs(new User(Id = UserInfo.getUserId())) {
        insert testUser;
    }

    // Now create non-setup objects
    Account acc = new Account(Name = 'Test');
    insert acc;

    System.runAs(testUser) {
        // Test with the new user
        Test.startTest();
        // ... test logic
        Test.stopTest();
    }
}
```

## Special Object Testing

```apex
// Products require Standard Pricebook
@IsTest
static void testWithProducts() {
    Id standardPbId = Test.getStandardPricebookId();

    Product2 product = new Product2(Name = 'Test Product', IsActive = true);
    insert product;

    PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = standardPbId,
        Product2Id = product.Id,
        UnitPrice = 100,
        IsActive = true
    );
    insert pbe;
}

// REST Endpoint Testing
@IsTest
static void testRestEndpoint() {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/accounts/001000000000001';
    req.httpMethod = 'GET';
    RestContext.request = req;
    RestContext.response = res;

    Test.startTest();
    Account result = MyRestResource.getAccount();
    Test.stopTest();

    System.assertNotEquals(null, result, 'Should return account');
}
```

## Rules

| Rule | Reason |
|------|--------|
| NEVER hardcode record IDs | IDs differ between orgs |
| ALWAYS use `Test.startTest()/stopTest()` | Resets governor limits, executes async |
| ALWAYS include assertion messages | Clarifies failures |
| ALWAYS test with 200+ records | Verifies bulkification |
| Use `@TestVisible` on private members | Avoid making them public |
| Create `TestDataFactory` class | Reusable, consistent test data |
| NEVER use `SeeAllData=true` | Exposes production data, breaks isolation |
| Test sync AND async paths | Full coverage |
| ALWAYS read implementation first | Match test assertions to actual behavior |

## Gotchas

| Issue | Detail |
|-------|--------|
| @TestSetup shared | Data is shared (not isolated) — each method gets a copy that resets |
| SeeAllData=true | Exposes production data — almost never use it |
| Async after stopTest | Future/Batch/Queueable execute AFTER `Test.stopTest()` |
| Mock before startTest | `Test.setMock()` must be called BEFORE `Test.startTest()` |
| Platform Event order | Event ordering NOT guaranteed in tests |
| Single startTest/stopTest | Can only call once per test method |
| Batch finish() | Also runs after `Test.stopTest()` |
| Mixed DML | `MIXED_DML_OPERATION` — use `System.runAs()` |
| Wrong assertion pattern | Tests may assume exceptions when impl returns empty — read impl first |

## Deployment

```bash
# Run specific test class
sf apex run test -n MyClassTest --synchronous --code-coverage -o myOrg

# Run all tests
sf apex run test --test-level RunLocalTests --code-coverage -o myOrg

# Get test results
sf apex get test -i <testRunId> -o myOrg
```
