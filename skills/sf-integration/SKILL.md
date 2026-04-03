---
name: sf-integration
description: |
  Configure Salesforce integrations: Named Credentials, Connected Apps, External
  Services, Platform Events, CDC, and authentication flows. Covers both legacy
  and enhanced patterns with migration guidance.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, integration, named-credentials, oauth, platform-events, cdc
---

# Salesforce Integration Configuration Guide

This guide covers integration infrastructure configuration — Named Credentials, Connected Apps, External Services, Platform Events, Change Data Capture, and authentication flows. It's written for junior developers who need to understand both modern and legacy patterns.

## Understanding Salesforce Integrations

Before diving into configuration, understand the integration landscape:

| Pattern | Direction | Use Case |
|---------|-----------|----------|
| **Named Credentials** | Salesforce → External | Call external APIs securely |
| **Connected Apps** | External → Salesforce | External apps access Salesforce APIs |
| **Platform Events** | Internal/External | Event-driven decoupling |
| **CDC** | Salesforce → External | Real-time data change notifications |
| **External Services** | Salesforce → External | Declarative API integration in Flows |

## 1. Named Credentials

Named Credentials abstract endpoint URLs and authentication from your code. This is **critical** — never hardcode credentials or endpoints in Apex!

### Why Named Credentials?

| Without Named Credentials | With Named Credentials |
|--------------------------|----------------------|
| Hardcoded URLs in code | URL configurable per environment |
| Credentials in code/custom settings | Platform manages auth |
| Manual header construction | Automatic auth headers |
| Security review flags | Security approved pattern |

### Enhanced Named Credentials (Preferred for New Development)

Enhanced Named Credentials separate concerns into two metadata types:

| Component | Purpose | File Suffix |
|-----------|---------|-------------|
| **External Credential** | Auth config (protocol, credentials, principal) | `.externalCredential-meta.xml` |
| **Named Credential** | Endpoint URL, references External Credential | `.namedCredential-meta.xml` |

**Why the separation?** Multiple endpoints can share the same auth config. For example, staging and production APIs might use the same OAuth credentials but different URLs.

### Enhanced Named Credential Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>MyService</fullName>
    <label>My Service</label>
    <endpoint>https://api.example.com</endpoint>
    <externalCredential>MyService_Auth</externalCredential>
    <generateAuthorizationHeader>true</generateAuthorizationHeader>
    <allowMergeFieldsInBody>false</allowMergeFieldsInBody>
    <allowMergeFieldsInHeader>true</allowMergeFieldsInHeader>
</NamedCredential>
```

### External Credential (OAuth Client Credentials)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ExternalCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>MyService_Auth</fullName>
    <label>My Service Auth</label>
    <authenticationProtocol>Oauth</authenticationProtocol>
    <externalCredentialParameters>
        <parameterName>ClientId</parameterName>
        <parameterType>AuthProviderUrl</parameterType>
        <parameterValue>YOUR_CLIENT_ID</parameterValue>
    </externalCredentialParameters>
    <externalCredentialParameters>
        <parameterName>Scope</parameterName>
        <parameterType>AuthParameter</parameterType>
        <parameterValue>api read</parameterValue>
    </externalCredentialParameters>
    <principals>
        <principalName>MyServicePrincipal</principalName>
        <principalType>NamedPrincipal</principalType>
        <sequenceNumber>1</sequenceNumber>
    </principals>
</ExternalCredential>
```

### Legacy Named Credentials

Legacy Named Credentials combine endpoint and auth in a single metadata file. Still supported but limited.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>LegacyService</fullName>
    <label>Legacy Service</label>
    <endpoint>https://api.example.com</endpoint>
    <principalType>NamedUser</principalType>
    <protocol>Password</protocol>
    <username>api_user</username>
    <!-- Password stored in org, not in metadata file -->
</NamedCredential>
```

**Legacy protocol values:** `Password`, `Oauth`, `Jwt`, `JwtExchange`, `AwsSv4`, `NoAuthentication`

### Permission Set Mapping for External Credentials

**⚠️ Important:** Users access External Credentials through Permission Set mappings. Without this, callouts fail with `NAMED_CREDENTIAL_NOT_FOUND` — a very confusing error!

```xml
<!-- In a Permission Set -->
<externalCredentialPrincipalAccesses>
    <enabled>true</enabled>
    <externalCredentialPrincipal>MyService_Auth - MyServicePrincipal</externalCredentialPrincipal>
</externalCredentialPrincipalAccesses>
```

**💡 Junior Developer Tip:** If your integration works in your org but fails for others, check if they have the permission set with external credential access!

### When to Use Each Type

| Scenario | Recommendation |
|----------|---------------|
| New integration | Enhanced Named Credential + External Credential |
| Simple, single-user auth (legacy) | Legacy Named Credential |
| Multiple endpoints, same auth | One External Credential, multiple Named Credentials |
| Per-user OAuth tokens | External Credential with Per-User principal |
| Migration from Remote Site Settings | Move to Named Credentials for auth management |

### Using Named Credentials in Apex

```apex
public with sharing class IntegrationService {

    public static HttpResponse callExternalApi(String endpoint, Object payload) {
        HttpRequest req = new HttpRequest();
        // Uses Named Credential — no hardcoded URL or auth!
        req.setEndpoint('callout:MyService' + endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        return http.send(req);
    }
}
```

## 2. Remote Site Settings vs Named Credentials

### Understanding the Difference

| Feature | Remote Site Setting | Named Credential |
|---------|-------------------|-----------------|
| URL whitelisting | ✅ Yes | ✅ Yes (implicit) |
| Auth management | ❌ No (manual in code) | ✅ Yes (automatic) |
| Credential storage | Developer responsibility | Platform-managed |
| Per-environment config | Manual | Built-in |
| Merge fields | ❌ No | ✅ Yes (headers, body, URL) |
| Deployable | ✅ Yes | ✅ Yes |

### Migration Path: Remote Site Settings → Named Credentials

**Why migrate?** Remote Site Settings only whitelist URLs. Named Credentials add secure auth management — the modern, secure pattern.

**Step-by-step migration:**

1. **Create Named Credential** with the Remote Site URL as endpoint
2. **Configure auth protocol** (OAuth, Password, JWT, etc.)
3. **Update Apex code:** replace hardcoded endpoint with `callout:NamedCredentialName`
4. **Remove auth header construction** from code
5. **Delete the Remote Site Setting**
6. **Test thoroughly** in sandbox before production

**Before (insecure):**
```apex
// ❌ Bad: hardcoded endpoint, manual auth
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.example.com/orders');
req.setHeader('Authorization', 'Bearer ' + getTokenFromCustomSetting());
```

**After (secure):**
```apex
// ✅ Good: Named Credential handles everything
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:OrderService/orders');
// No auth header needed — Named Credential adds it automatically
```

## 3. Connected Apps

Connected Apps define OAuth client configuration for external applications accessing Salesforce — the reverse direction of Named Credentials.

### When You Need a Connected App

| Scenario | Need Connected App? |
|----------|-------------------|
| External web app accessing Salesforce API | ✅ Yes |
| Mobile app accessing Salesforce API | ✅ Yes |
| CI/CD deploying to Salesforce | ✅ Yes (JWT Bearer) |
| Backend service calling Salesforce | ✅ Yes |
| Salesforce calling external API | ❌ No (use Named Credential) |

### Connected App Metadata

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ConnectedApp xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>MyConnectedApp</fullName>
    <label>My Connected App</label>
    <contactEmail>admin@example.com</contactEmail>
    <oauthConfig>
        <callbackUrl>https://myapp.example.com/callback</callbackUrl>
        <certificate>MyCertificateName</certificate>
        <consumerKey>WILL_BE_GENERATED</consumerKey>
        <isAdminApproved>true</isAdminApproved>
        <isConsumerSecretOptional>false</isConsumerSecretOptional>
        <scopes>Api</scopes>
        <scopes>RefreshToken</scopes>
        <scopes>OfflineAccess</scopes>
    </oauthConfig>
    <oauthPolicy>
        <ipRelaxation>ENFORCE</ipRelaxation>
        <refreshTokenPolicy>SPECIFIC_LIFETIME</refreshTokenPolicy>
        <refreshTokenValidityPeriod>720</refreshTokenValidityPeriod>
        <refreshTokenValidityUnits>HOURS</refreshTokenValidityUnits>
    </oauthPolicy>
</ConnectedApp>
```

### OAuth Scopes Reference

| Scope | What It Allows | When to Use |
|-------|---------------|-------------|
| `Api` | Access REST/SOAP APIs | Most integrations |
| `Web` | Access via browser | Web app with user session |
| `Full` | Full access | ⚠️ Avoid in production |
| `RefreshToken` | Enable refresh tokens | Long-lived access |
| `OfflineAccess` | Same as RefreshToken | Standard OAuth name |
| `Chatter` | Chatter REST API | Chatter integrations |
| `CustomPermissions` | Custom permission access | Permission-gated features |
| `OpenID` | OpenID Connect identity | SSO integrations |
| `Profile` | User profile info | User info retrieval |
| `Email` | User email | Email address access |

### IP Relaxation Options

| Value | Behavior | Use Case |
|-------|----------|----------|
| `ENFORCE` | Enforce IP restrictions from Connected App | Production — most secure |
| `BYPASS` | Bypass org IP restrictions | CI/CD, service accounts |
| `BYPASS_WITH_VALID_BROWSER_SESSION` | Bypass only if active browser session | Hybrid scenarios |

### Auth Flow Decision Guide

| Flow | Use Case | Client Type | User Interaction |
|------|----------|-------------|-----------------|
| **JWT Bearer** | Server-to-server, CI/CD, backend automation | Confidential | None (pre-authorized) |
| **Web Server** | Web apps with user login | Confidential | Browser redirect |
| **Auth Code + PKCE** | SPAs, mobile apps, public clients | Public | Browser redirect |
| **Client Credentials** | M2M, service accounts (no user context) | Confidential | None |
| **Device Flow** | CLI tools, headless devices, IoT | Public or confidential | Out-of-band user auth |
| **Refresh Token** | Maintain sessions without re-auth | Either | None (silent) |

### Decision Rules (Flowchart)

1. **No user context needed?** → Client Credentials (if available) or JWT Bearer
2. **Backend service?** → JWT Bearer with X.509 certificate
3. **User-facing web app?** → Web Server flow
4. **Public client (SPA/mobile)?** → Auth Code + PKCE (mandatory)
5. **No browser?** → Device Flow
6. **Long-lived access?** → Add `RefreshToken` / `OfflineAccess` scope

### JWT Bearer Flow Setup (CI/CD, Server-to-Server)

**Used for:** GitHub Actions, Jenkins, backend services

1. Generate X.509 certificate and private key
2. Upload certificate to Connected App
3. Pre-authorize the Connected App for the integration user's profile
4. Set `isAdminApproved` to `true`
5. Integration sends JWT signed with private key to token endpoint

Token endpoint: `https://login.salesforce.com/services/oauth2/token`
Grant type: `urn:ietf:params:oauth:grant-type:jwt-bearer`

## 4. External Services

External Services let you register an OpenAPI spec and auto-generate invocable actions usable in Flow, Einstein Bots, and Apex.

### Why External Services?

- **Declarative callouts** — no Apex needed for simple API calls
- **Auto-generated actions** — Flow can call any operation in the spec
- **Named Credential integration** — auth handled automatically

### Requirements and Constraints

| Constraint | Value |
|-----------|-------|
| OpenAPI version | **3.0 only** (2.0/Swagger not supported for new registrations) |
| Spec size limit | 100 KB |
| Max operations | 50 per registration |
| Auth | All operations use the Named Credential |
| HTTP methods | GET, POST, PUT, PATCH, DELETE |

### External Service Metadata

```xml
<?xml version="1.0" encoding="UTF-8"?>
<ExternalServiceRegistration xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>MyExternalService</fullName>
    <label>My External Service</label>
    <namedCredential>MyService</namedCredential>
    <schema>--- OpenAPI JSON spec inlined or referenced ---</schema>
    <schemaType>OpenApi3</schemaType>
    <serviceBinding>
        <fieldName>operationName</fieldName>
        <value>createOrder</value>
    </serviceBinding>
    <status>Complete</status>
</ExternalServiceRegistration>
```

### Using External Service in Flow

1. In Flow Builder, add an **Action** element
2. Filter by category **"External Services"**
3. Select the operation (e.g., `createOrder`, `getCustomer`)
4. Map Flow variables to input/output parameters
5. The Named Credential handles authentication automatically

**💡 Junior Developer Tip:** External Services are great for simple integrations. For complex scenarios (error handling, retries, conditional logic), use Apex with Named Credentials.

## 5. Platform Events

Custom event bus for decoupled, event-driven integration within Salesforce and with external systems.

### Why Platform Events?

| Problem | Platform Event Solution |
|---------|------------------------|
| Tight coupling between systems | Fire event, subscribers handle it |
| Long-running processes | Async via event triggers |
| External system notifications | Pub/Sub API for subscribers |
| Audit trails | Events represent what happened |

### Event Definition

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Order_Event__e</fullName>
    <label>Order Event</label>
    <pluralLabel>Order Events</pluralLabel>
    <publishBehavior>PublishAfterCommit</publishBehavior>
    <fields>
        <fullName>Order_Id__c</fullName>
        <label>Order Id</label>
        <type>Text</type>
        <length>18</length>
    </fields>
    <fields>
        <fullName>Action__c</fullName>
        <label>Action</label>
        <type>Text</type>
        <length>50</length>
    </fields>
    <fields>
        <fullName>Payload__c</fullName>
        <label>Payload</label>
        <type>LongTextArea</type>
        <length>131072</length>
        <visibleLines>5</visibleLines>
    </fields>
</CustomObject>
```

### Publish Behavior

| Behavior | When Published | Use When |
|----------|----------------|----------|
| `PublishAfterCommit` | After transaction commits successfully | **Default.** Event should reflect committed data |
| `PublishImmediately` | Immediately, even if transaction rolls back | Logging, auditing, fire-and-forget notifications |

**⚠️ Critical Rule:** `PublishAfterCommit` events do NOT fire if the transaction rolls back. No retry, no automatic republish.

### Publishing Events (Apex)

```apex
public with sharing class OrderEventService {

    public static void publishOrderCreated(Order__c order) {
        Order_Event__e event = new Order_Event__e(
            Order_Id__c = order.Id,
            Action__c = 'CREATED',
            Payload__c = JSON.serialize(order)
        );

        Database.SaveResult result = EventBus.publish(event);

        // ⚠️ EventBus.publish does NOT throw — check SaveResult!
        if (!result.isSuccess()) {
            for (Database.Error err : result.getErrors()) {
                System.debug(LoggingLevel.ERROR, 'Publish error: ' + err.getMessage());
                // Consider: log to custom object, fire alert, etc.
            }
        }
    }

    // Publish multiple events efficiently
    public static void publishBatch(List<Order_Event__e> events) {
        if (events.isEmpty()) return;

        List<Database.SaveResult> results = EventBus.publish(events);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'Failed to publish event ' + i + ': ' + results[i].getErrors());
            }
        }
    }
}
```

### Subscribing to Events

**Apex Trigger (runs in separate transaction):**
```apex
trigger OrderEventTrigger on Order_Event__e (after insert) {
    List<Order_History__c> histories = new List<Order_History__c>();

    for (Order_Event__e event : Trigger.new) {
        // Process event — runs in its own execution context
        histories.add(new Order_History__c(
            Order__c = event.Order_Id__c,
            Action__c = event.Action__c,
            Event_Time__c = DateTime.now()
        ));
    }

    if (!histories.isEmpty()) {
        insert histories;
    }
}
```

**Flow:** Use Platform Event-Triggered Flow (not Record-Triggered)

**External Systems:** Use CometD or Pub/Sub API (gRPC)

### Replay and Retention

| Event Type | Retention | Throughput |
|-----------|-----------|------------|
| Standard Platform Events | 24 hours | Lower |
| High-Volume Platform Events | 72 hours | 150,000/hour |

- Use `ReplayId` in CometD or Pub/Sub API to resume from a specific point after subscriber failure
- Replay positions: `-1` (tip/latest), `-2` (all retained events), or specific Replay ID

## 6. Change Data Capture (CDC)

Streams record changes (create, update, delete, undelete) as events on the event bus automatically.

### CDC vs Platform Events

| Aspect | CDC | Platform Events |
|--------|-----|-----------------|
| **Trigger** | Automatic on record DML | Explicit publish via code/flow |
| **Schema** | Mirrors SObject fields | Custom-defined fields |
| **Use case** | React to data changes | Decouple business processes |
| **Retention** | 72 hours | 24h (standard) / 72h (high-volume) |
| **External subscribe** | Pub/Sub API, CometD | Pub/Sub API, CometD |

### Enabling CDC

1. **Setup > Change Data Capture**
2. Select objects to track (standard or custom)
3. Changes publish to channels: `/data/<ObjectName>ChangeEvent`

For custom objects: `/data/<CustomObject__c>ChangeEvent` becomes `/data/Custom_Object__ChangeEvent`

### ChangeEventHeader Fields

Every CDC event includes a header with change metadata:

| Field | Description |
|-------|-------------|
| `entityName` | SObject API name |
| `changeType` | `CREATE`, `UPDATE`, `DELETE`, `UNDELETE` |
| `changedFields` | List of fields that changed (UPDATE only) |
| `commitTimestamp` | When the change was committed |
| `transactionKey` | Groups changes from the same transaction |
| `sequenceNumber` | Order within a transaction |
| `recordIds` | IDs of changed records |
| `commitUser` | User who made the change |
| `commitNumber` | Monotonically increasing commit sequence |

### CDC Subscriber Trigger

```apex
trigger AccountChangeEventTrigger on AccountChangeEvent (after insert) {
    for (AccountChangeEvent event : Trigger.new) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        String changeType = header.getChangeType();
        List<String> changedFields = header.getChangedFields();

        // React to specific field changes
        if (changeType == 'UPDATE' && changedFields.contains('Rating')) {
            for (String recordId : header.getRecordIds()) {
                // Queue processing for each changed record
                System.enqueueJob(new RatingChangeProcessor(recordId));
            }
        }
    }
}
```

## 7. Outbound Messaging (Legacy)

**Note:** This is a legacy pattern. Prefer Platform Events or Flow HTTP Callout for new development.

### What Is Outbound Messaging?

SOAP-based outbound notifications triggered by Workflow Rules:
- Fires from Workflow Rules only (not Process Builder or Flow)
- SOAP format, automatic retry with exponential backoff for 24 hours
- Endpoint must respond with Ack ID; retries until acknowledged or 24h timeout
- Max 100 fields per message

### Migration Options

| From | To | When |
|------|-----|------|
| Outbound Messaging | Platform Events | Decoupled pub/sub, multiple subscribers |
| Outbound Messaging | Flow + HTTP Callout | Declarative, simpler endpoint |
| Outbound Messaging | Apex Callout | Complex request/response, error handling |

## 8. Gotchas and Common Mistakes

### Named Credentials

| Issue | What Happens | Fix |
|-------|--------------|-----|
| Missing Permission Set mapping | `NAMED_CREDENTIAL_NOT_FOUND` error | Add External Credential to Permission Set |
| Case-sensitive parameter names | Auth fails silently | Match case exactly |
| `generateAuthorizationHeader` = false | No auth header added | Set to `true` |
| Max 100 callouts per transaction | `System.LimitException` | Use async processing |

### Platform Events

| Issue | What Happens | Fix |
|-------|--------------|-----|
| 150,000/hour limit (high-volume) | Events rejected | Batch, throttle, or use Bulk API |
| `PublishAfterCommit` + rollback | Events never fire | Use `PublishImmediately` for critical logs |
| Not checking SaveResult | Failures go unnoticed | Always check `isSuccess()` |
| Non-idempotent subscriber | Duplicate processing | Design for at-least-once delivery |

### Change Data Capture

| Issue | What Happens | Fix |
|-------|--------------|-----|
| 72-hour replay window | Old events inaccessible | Store locally if needed longer |
| Large transaction splits | Multiple events for one transaction | Check `sequenceNumber` |
| Not all objects supported | Can't enable CDC | Check documentation |

### External Services

| Issue | What Happens | Fix |
|-------|--------------|-----|
| Swagger 2.0 spec | Registration fails | Convert to OpenAPI 3.0 |
| Spec > 100 KB | Registration fails | Simplify spec, remove unused operations |
| Complex nested schemas | Parsing issues | Flatten where possible |

### Connected Apps

| Issue | What Happens | Fix |
|-------|--------------|-----|
| Consumer key/secret in metadata | Won't work — they're generated | Create via API or UI |
| Missing admin approval | JWT Bearer fails | Pre-authorize for profiles |
| Certificate expired | Silent auth failures | Monitor and rotate certificates |
| 10-minute propagation delay | Changes not working immediately | Wait and retry |

### General Integration

| Issue | What Happens | Fix |
|-------|--------------|-----|
| Callout after DML | `CalloutException` | Callout first, then DML; or use `@future` |
| 120-second timeout | Long calls fail | Use async, chunked processing |
| Hardcoded credentials | Security violation | Use Named Credentials |

## Deployment

```bash
# Deploy Named Credentials
sf project deploy start -d force-app/main/default/namedCredentials/ -o myOrg

# Deploy External Credentials
sf project deploy start -d force-app/main/default/externalCredentials/ -o myOrg

# Deploy Platform Events
sf project deploy start -d force-app/main/default/objects/*__e/ -o myOrg

# Deploy Connected Apps
sf project deploy start -d force-app/main/default/connectedApps/ -o myOrg

# Deploy External Services
sf project deploy start -d force-app/main/default/externalServiceRegistrations/ -o myOrg
```

## Quick Reference Cheat Sheet

| I Need To... | Use This |
|--------------|----------|
| Call external API from Apex | Named Credential + HttpRequest |
| Let external app call Salesforce | Connected App |
| Call API from Flow (no code) | External Service |
| Decouple processes, notify external | Platform Events |
| React to record changes | Change Data Capture |
| Server-to-server with no user | JWT Bearer or Client Credentials |
| Web app with user login | Web Server flow |
| Mobile/SPA app | Auth Code + PKCE |