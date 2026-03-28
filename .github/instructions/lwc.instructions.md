---
applyTo: "**/lwc/**"
---

# Lightning Web Component Standards

## Component Structure

```
componentName/
├── componentName.html       # Template
├── componentName.js         # Controller
├── componentName.css        # Styles (optional)
└── componentName.js-meta.xml # Configuration
```

## Meta Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Component Label</masterLabel>
    <description>What this component does</description>
    <targets>
        <target>lightning__AppPage</target>
        <target>lightning__RecordPage</target>
        <target>lightning__Tab</target>
    </targets>
</LightningComponentBundle>
```

## JavaScript Patterns

```javascript
/**
 * @description Component description
 * @author AI generated for Force.com DevOps Platform Team
 */
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

// Apex imports
import getRecords from '@salesforce/apex/Controller.getRecords';

export default class ComponentName extends NavigationMixin(LightningElement) {
    @api recordId;
    @track data = [];
    error;

    // Wire service for reactive data
    @wire(getRecords, { recordId: '$recordId' })
    wiredRecords({ error, data }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }
}
```

## Toast Notifications

```javascript
this.dispatchEvent(new ShowToastEvent({
    title: 'Success',
    message: 'Record saved',
    variant: 'success'
}));
```

## Navigation

```javascript
this[NavigationMixin.Navigate]({
    type: 'standard__recordPage',
    attributes: {
        recordId: this.recordId,
        actionName: 'view'
    }
});
```

## Action Overrides

For New/Edit button overrides, use Aura wrapper:

```xml
<!-- AccountNewOverride.cmp -->
<aura:component implements="lightning:actionOverride,force:hasRecordId">
    <c:accountNewAction />
</aura:component>
```

## Testing

Run Jest tests:
```bash
npm run test:unit
npm run test:unit:coverage
```
