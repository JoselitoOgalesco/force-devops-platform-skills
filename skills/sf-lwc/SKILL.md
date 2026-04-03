---
name: sf-lwc
description: |
  Build production-ready Lightning Web Components with proper patterns, wire adapters,
  component communication, styling, testing, and performance optimization. Covers
  LDS (Lightning Data Service), LMS (Lightning Message Service), reactivity, lifecycle
  hooks, navigation, and security best practices.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "2.0.0"
  tags: salesforce, lwc, lightning-web-components, jest, frontend
---

# Lightning Web Component Development Guide

Build scalable, performant Lightning Web Components following Salesforce best practices. This guide covers component architecture, data binding, styling, testing, and performance optimization.

## Understanding LWC Architecture

### Component Bundle Structure

```
myComponent/
├── myComponent.html          # Template (required)
├── myComponent.js            # Controller (required)
├── myComponent.css           # Styles (optional)
├── myComponent.js-meta.xml   # Configuration (required)
└── __tests__/
    └── myComponent.test.js   # Jest tests
```

### Naming Conventions

| File/Element | Convention | Example |
|--------------|------------|---------|
| Folder | `camelCase` | `accountCard` |
| HTML tag | `kebab-case` with namespace | `<c-account-card>` |
| JS class | `PascalCase` | `AccountCard` |
| CSS | Component scoped | Same as folder |

**💡 Junior Developer Tip:** The folder name becomes the component's tag name. `accountCard` becomes `<c-account-card>` in HTML.

---

## Component Configuration (meta.xml)

### Complete Configuration Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Account Card</masterLabel>
    <description>Displays account summary information</description>

    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
        <target>lightning__FlowScreen</target>
        <target>lightningCommunity__Page</target>
    </targets>

    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
                <object>Contact</object>
            </objects>
            <property name="showHeader" type="Boolean" default="true"
                      label="Show Header" description="Display component header"/>
            <property name="maxRecords" type="Integer" default="10"
                      label="Max Records"/>
        </targetConfig>

        <targetConfig targets="lightning__FlowScreen">
            <property name="inputRecordId" type="String" role="inputOnly"/>
            <property name="outputResult" type="String" role="outputOnly"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Target Reference

| Target | Location | Context |
|--------|----------|---------|
| `lightning__RecordPage` | Record page | Has `recordId` |
| `lightning__AppPage` | App page | No record context |
| `lightning__HomePage` | Home page | No record context |
| `lightning__FlowScreen` | Flow screen | Flow variables |
| `lightningCommunity__Page` | Experience Cloud | Site context |
| `lightning__Tab` | Custom tab | App context |
| `lightning__Inbox` | Outlook/Gmail | Email context |

---

## JavaScript Controller Patterns

### Standard Component Template

```javascript
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';
import updateAccount from '@salesforce/apex/AccountController.updateAccount';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import NAME_FIELD from '@salesforce/schema/Account.Name';

export default class AccountCard extends NavigationMixin(LightningElement) {
    // Public properties (received from parent/App Builder)
    @api recordId;
    @api maxRecords = 10;

    // Private reactive properties
    accounts = [];
    error;
    isLoading = false;

    // Store wire result for refreshApex
    wiredAccountsResult;

    // Getter for UI logic
    get hasAccounts() {
        return this.accounts?.length > 0;
    }

    get accountCount() {
        return this.accounts?.length || 0;
    }

    // Wire adapter with reactive parameter
    @wire(getAccounts, { maxRecords: '$maxRecords' })
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        const { data, error } = result;
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = this.reduceErrors(error);
            this.accounts = [];
        }
    }

    // Imperative Apex call
    async handleSave() {
        this.isLoading = true;
        try {
            await updateAccount({ accountId: this.recordId, name: this.newName });
            this.showToast('Success', 'Account updated', 'success');
            await refreshApex(this.wiredAccountsResult);
        } catch (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Utility methods
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        return error?.body?.message || error?.message || 'Unknown error';
    }
}
```

### Decorators Reference

| Decorator | Purpose | Reactive? |
|-----------|---------|-----------|
| `@api` | Public property/method | Yes |
| `@wire` | Data binding to Apex/LDS | Yes |
| `@track` | Deep object/array tracking | Yes (rarely needed) |

**Modern LWC (v55+):** Properties are reactive by default. Use `@track` only for deep object property changes.

---

## Data Access Patterns

### Lightning Data Service (LDS)

Use LDS for simple CRUD without Apex:

```javascript
import { getRecord, getFieldValue, updateRecord, createRecord, deleteRecord }
    from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ID_FIELD from '@salesforce/schema/Account.Id';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';

// Get record with FLS enforcement
@wire(getRecord, {
    recordId: '$recordId',
    fields: [NAME_FIELD, INDUSTRY_FIELD]
})
account;

// Get field value (null-safe)
get accountName() {
    return getFieldValue(this.account.data, NAME_FIELD);
}

// Update record
async handleUpdate() {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[NAME_FIELD.fieldApiName] = this.newName;

    try {
        await updateRecord({ fields });
        this.showToast('Success', 'Record updated', 'success');
    } catch (error) {
        this.showToast('Error', error.body.message, 'error');
    }
}

// Create record
async handleCreate() {
    const fields = {};
    fields[NAME_FIELD.fieldApiName] = this.newName;

    const recordInput = { apiName: ACCOUNT_OBJECT.objectApiName, fields };

    try {
        const record = await createRecord(recordInput);
        this.newRecordId = record.id;
    } catch (error) {
        this.showToast('Error', error.body.message, 'error');
    }
}
```

### When to Use LDS vs Apex

| Scenario | Use LDS | Use Apex |
|----------|---------|----------|
| Single record CRUD | ✅ | ❌ |
| Field-level security | ✅ (automatic) | ✅ (must enforce) |
| Complex queries | ❌ | ✅ |
| Bulk operations | ❌ | ✅ |
| Business logic | ❌ | ✅ |
| Cross-object queries | ❌ | ✅ |

### Refreshing Wire Data

```javascript
import { refreshApex } from '@salesforce/apex';

// Store wire result
wiredResult;

@wire(getAccounts)
wiredAccounts(result) {
    this.wiredResult = result;  // Store entire result
    // ... process data
}

// After mutation, refresh the wire
async handleSave() {
    await updateRecord({ fields });
    await refreshApex(this.wiredResult);  // Re-fetch data
}
```

---

## Component Communication

### Parent → Child (Public API)

**Child component:**
```javascript
export default class ChildComponent extends LightningElement {
    @api accountId;
    @api records = [];

    @api
    refresh() {
        // Public method callable by parent
        this.loadData();
    }
}
```

**Parent template:**
```html
<c-child-component
    account-id={recordId}
    records={accounts}>
</c-child-component>
```

**Parent calling child method:**
```javascript
handleRefresh() {
    this.template.querySelector('c-child-component').refresh();
}
```

### Child → Parent (Custom Events)

**Child dispatches event:**
```javascript
handleSelect(event) {
    const selectedId = event.target.dataset.id;

    this.dispatchEvent(new CustomEvent('select', {
        detail: { accountId: selectedId },
        bubbles: false,  // Stay in component tree (default)
        composed: false  // Don't cross shadow DOM (default)
    }));
}
```

**Parent handles event:**
```html
<c-child-component onselect={handleChildSelect}></c-child-component>
```

```javascript
handleChildSelect(event) {
    const accountId = event.detail.accountId;
    this.selectedAccountId = accountId;
}
```

### Sibling Communication (Lightning Message Service)

**1. Create message channel:**
```xml
<!-- messageChannels/AccountSelected__c.messageChannel-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<LightningMessageChannel xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Account Selected</masterLabel>
    <isExposed>true</isExposed>
    <lightningMessageFields>
        <fieldName>accountId</fieldName>
        <description>Selected account ID</description>
    </lightningMessageFields>
</LightningMessageChannel>
```

**2. Publisher component:**
```javascript
import { LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import ACCOUNT_SELECTED from '@salesforce/messageChannel/AccountSelected__c';

export default class Publisher extends LightningElement {
    @wire(MessageContext) messageContext;

    handleSelect(event) {
        publish(this.messageContext, ACCOUNT_SELECTED, {
            accountId: event.detail.accountId
        });
    }
}
```

**3. Subscriber component:**
```javascript
import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext }
    from 'lightning/messageService';
import ACCOUNT_SELECTED from '@salesforce/messageChannel/AccountSelected__c';

export default class Subscriber extends LightningElement {
    @wire(MessageContext) messageContext;
    subscription = null;

    connectedCallback() {
        this.subscribeToChannel();
    }

    disconnectedCallback() {
        this.unsubscribeFromChannel();
    }

    subscribeToChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                ACCOUNT_SELECTED,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeFromChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        this.selectedAccountId = message.accountId;
    }
}
```

---

## Lifecycle Hooks

| Hook | When | Use For |
|------|------|---------|
| `constructor()` | Component created | Initialize state (no DOM access) |
| `connectedCallback()` | Inserted into DOM | Fetch data, subscribe to events |
| `renderedCallback()` | After each render | DOM manipulation (use guard!) |
| `disconnectedCallback()` | Removed from DOM | Cleanup, unsubscribe |
| `errorCallback(error, stack)` | Child throws error | Error boundary |

### renderedCallback Guard Pattern

```javascript
hasRendered = false;

renderedCallback() {
    if (this.hasRendered) return;
    this.hasRendered = true;

    // One-time DOM manipulation
    this.template.querySelector('.chart-container')
        .appendChild(this.createChart());
}
```

**⚠️ Warning:** `renderedCallback` fires on EVERY re-render. Always use a guard flag for one-time operations.

---

## Styling

### SLDS Usage

```css
/* Use SLDS design tokens */
.container {
    padding: var(--lwc-spacingMedium); /* 1rem */
    background-color: var(--lwc-colorBackground);
    border-radius: var(--lwc-borderRadiusMedium);
}

/* Never hardcode colors */
.error {
    color: var(--lwc-colorTextError);  /* ✅ Good */
    /* color: #ff0000; */              /* ❌ Bad */
}
```

### Conditional Classes

```html
<div class={containerClass}>
    <span class={itemClass}>Item</span>
</div>
```

```javascript
get containerClass() {
    return this.isActive ? 'slds-box slds-theme_success' : 'slds-box';
}

get itemClass() {
    return `slds-text-body_regular ${this.isHighlighted ? 'highlight' : ''}`;
}
```

---

## Navigation

```javascript
import { NavigationMixin } from 'lightning/navigation';

export default class MyComponent extends NavigationMixin(LightningElement) {

    // Navigate to record
    viewRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    // Navigate to new record
    createRecord() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'new'
            }
        });
    }

    // Navigate to external URL
    goToExternal() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://example.com'
            }
        });
    }
}
```

---

## Jest Testing

### Test Template

```javascript
import { createElement } from 'lwc';
import AccountCard from 'c/accountCard';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

// Mock Apex
jest.mock('@salesforce/apex/AccountController.getAccounts', () => ({
    default: jest.fn()
}), { virtual: true });

const MOCK_ACCOUNTS = [
    { Id: '001xx000001', Name: 'ACME Corp' },
    { Id: '001xx000002', Name: 'Test Inc' }
];

describe('c-account-card', () => {
    afterEach(() => {
        // Clean up DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    // Helper to wait for async operations
    async function flushPromises() {
        return Promise.resolve();
    }

    it('displays accounts when data loaded', async () => {
        getAccounts.mockResolvedValue(MOCK_ACCOUNTS);

        const element = createElement('c-account-card', { is: AccountCard });
        document.body.appendChild(element);

        await flushPromises();

        const items = element.shadowRoot.querySelectorAll('.account-item');
        expect(items.length).toBe(2);
    });

    it('shows error when apex fails', async () => {
        getAccounts.mockRejectedValue({ body: { message: 'Server error' } });

        const element = createElement('c-account-card', { is: AccountCard });
        document.body.appendChild(element);

        await flushPromises();

        const error = element.shadowRoot.querySelector('.error-message');
        expect(error.textContent).toContain('Server error');
    });

    it('calls handler when button clicked', async () => {
        const element = createElement('c-account-card', { is: AccountCard });
        document.body.appendChild(element);

        const handler = jest.fn();
        element.addEventListener('select', handler);

        const button = element.shadowRoot.querySelector('lightning-button');
        button.click();

        expect(handler).toHaveBeenCalled();
    });
});
```

---

## Performance Best Practices

| Do | Don't |
|----|-------|
| ✅ Use `@wire` for automatic caching | ❌ Fetch in `connectedCallback` for every instance |
| ✅ Use getters sparingly | ❌ Complex logic in getters (reruns every render) |
| ✅ Cache DOM queries | ❌ Query DOM in loops |
| ✅ Debounce input handlers | ❌ Fire events on every keystroke |
| ✅ Use `if:true/false` | ❌ Hide with CSS for large unused trees |

### Debouncing Example

```javascript
searchTerm = '';
delayTimeout;

handleSearchInput(event) {
    clearTimeout(this.delayTimeout);
    const value = event.target.value;

    this.delayTimeout = setTimeout(() => {
        this.searchTerm = value;
        this.performSearch();
    }, 300);
}
```

---

## Common Mistakes & Fixes

### Mistake 1: Direct DOM Mutation
```javascript
❌ this.template.querySelector('.title').textContent = 'New Title';
✅ Use reactive property: this.title = 'New Title';
```

### Mistake 2: Forgetting to Unsubscribe
```javascript
❌ // No disconnectedCallback
✅ disconnectedCallback() { unsubscribe(this.subscription); }
```

### Mistake 3: Complex Getter Logic
```javascript
❌ get filteredItems() { return this.items.filter(/* complex */); }
✅ Cache in a property during data load
```

### Mistake 4: Missing Error Handling
```javascript
❌ const result = await apexMethod();
✅ try { await apexMethod(); } catch(e) { this.showToast('Error', ...); }
```
