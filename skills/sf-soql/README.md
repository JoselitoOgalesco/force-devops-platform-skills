# sf-soql

Write optimized SOQL queries for Salesforce.

## Description

This skill helps you write efficient SOQL queries that respect governor limits, use selective filters, handle relationships, and implement proper security. Covers query optimization, aggregate functions, and common performance pitfalls.

## Features

- **Query Optimization** — Selective filters and indexes
- **Relationship Queries** — Parent-to-child and child-to-parent
- **Aggregate Functions** — COUNT, SUM, AVG, GROUP BY
- **Security** — WITH SECURITY_ENFORCED, USER_MODE
- **Geolocation** — DISTANCE and GEOLOCATION queries
- **Performance** — Query plan analysis

## Quick Start

1. Check if filters are selective (indexed fields)
2. Query only needed fields (avoid SELECT *)
3. Use WITH SECURITY_ENFORCED for FLS
4. Test with realistic data volumes
5. Monitor query limits

## Usage

Invoke this skill when:
- Writing new SOQL queries
- Optimizing slow queries
- Implementing relationship queries
- Debugging query limit errors

## Related Skills

- [sf-apex](../sf-apex/) — Queries in Apex code
- [sf-security](../sf-security/) — Query security
- [sf-debug](../sf-debug/) — Query profiling
