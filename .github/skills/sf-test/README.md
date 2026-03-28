# sf-test

Generate comprehensive Apex test classes.

## Description

This skill helps you create production-ready Apex test classes with @TestSetup methods, TestFactory patterns, bulk data testing (200 records), positive/negative/permission scenarios, and HttpCalloutMock implementations. Targets 85%+ code coverage with meaningful assertions.

## Features

- **@TestSetup** — Efficient test data creation
- **TestDataFactory** — Reusable test data patterns
- **Bulk Testing** — 200-record scenarios
- **Positive/Negative Tests** — Happy path and error cases
- **Permission Testing** — Run as different users
- **HttpCalloutMock** — Mock external callouts
- **Assertions** — Meaningful validation

## Quick Start

1. Create TestDataFactory for common objects
2. Use @TestSetup for shared test data
3. Write positive tests (happy path)
4. Write negative tests (error handling)
5. Write permission tests (different users)
6. Mock all callouts with HttpCalloutMock

## Usage

Invoke this skill when:
- Creating test classes for Apex
- Implementing mock callouts
- Testing with different user contexts
- Achieving code coverage requirements

## Related Skills

- [sf-apex](../sf-apex/) — Code to test
- [sf-debug](../sf-debug/) — Test debugging
- [sf-security](../sf-security/) — Permission testing
