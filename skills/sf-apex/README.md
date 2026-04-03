# sf-apex

Generate and review production-ready Apex code for Salesforce.

## Description

This skill helps you write Apex code that follows Salesforce best practices including governor limit awareness, bulkification patterns, and CRUD/FLS compliance. Use for writing Apex classes, triggers, batch jobs, queueable jobs, or reviewing existing code.

## Features

- **Governor Limit Awareness** — Stay within SOQL, DML, CPU, and heap limits
- **Bulkification Patterns** — Handle collections, not single records
- **CRUD/FLS Compliance** — Enforce security with stripInaccessible or WITH SECURITY_ENFORCED
- **Trigger Frameworks** — Handler patterns for scalable trigger design
- **Async Processing** — Batch, Queueable, Future, Schedulable patterns
- **Exception Handling** — Proper try-catch with logging

## Quick Start

1. Check governor limits before writing queries/DML
2. Use collections (List, Set, Map) — never SOQL/DML in loops
3. Add WITH SECURITY_ENFORCED or stripInaccessible for security
4. Build test classes with 85%+ coverage

## Usage

Invoke this skill when:
- Writing new Apex classes or triggers
- Reviewing existing Apex code
- Debugging governor limit errors
- Implementing batch or queueable jobs

## Related Skills

- [sf-test](../sf-test/) — Test class generation
- [sf-debug](../sf-debug/) — Debug log analysis
- [sf-soql](../sf-soql/) — Query optimization
- [sf-security](../sf-security/) — CRUD/FLS enforcement
