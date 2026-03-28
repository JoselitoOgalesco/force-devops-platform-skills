# sf-security

Implement Salesforce security best practices.

## Description

This skill provides comprehensive guidance for CRUD/FLS enforcement, sharing model configuration, secure coding practices, and security review preparation. Covers both declarative security and programmatic enforcement.

## Features

- **CRUD/FLS Enforcement** — stripInaccessible, WITH SECURITY_ENFORCED
- **Sharing Model** — OWD, sharing rules, role hierarchy
- **Secure Coding** — Prevent SOQL injection, XSS, CSRF
- **Security Review** — AppExchange security checklist
- **Encryption** — Platform encryption and Shield
- **Session Security** — Login policies and MFA

## Quick Start

1. Set appropriate Organization-Wide Defaults
2. Enforce CRUD/FLS in all Apex code
3. Use parameterized queries (never string concatenation)
4. Implement sharing rules for exceptions
5. Run security scanner before deployment

## Usage

Invoke this skill when:
- Writing secure Apex code
- Designing sharing model
- Preparing for security review
- Implementing field-level encryption

## Related Skills

- [sf-apex](../sf-apex/) — Security in code
- [sf-permissions](../sf-permissions/) — Access control
- [sf-soql](../sf-soql/) — Secure queries
