# sf-integration

Build Salesforce integrations with external systems.

## Description

This skill provides comprehensive guidance for integrating Salesforce with external systems using REST, SOAP, Platform Events, Named Credentials, External Services, and legacy patterns. Covers both inbound and outbound integration patterns with callout limits awareness.

## Features

- **REST Callouts** — HttpRequest/HttpResponse patterns
- **SOAP Callouts** — WSDL2Apex and WebServiceCallout
- **Named Credentials** — Secure credential management
- **External Services** — OpenAPI-based integrations
- **Platform Events** — Event-driven architecture
- **Outbound Messages** — Workflow-based integrations
- **Legacy Migration** — Moving from deprecated patterns

## Quick Start

1. Choose integration pattern (REST preferred)
2. Set up Named Credential for authentication
3. Create Remote Site Setting if needed
4. Implement callout with error handling
5. Add retry logic and logging

## Usage

Invoke this skill when:
- Building API integrations
- Migrating from legacy patterns
- Implementing event-driven integrations
- Setting up authentication

## Related Skills

- [sf-apex](../sf-apex/) — Callout implementation
- [sf-security](../sf-security/) — Credential security
- [sf-debug](../sf-debug/) — Integration troubleshooting
- [sf-test](../sf-test/) — HttpCalloutMock patterns
