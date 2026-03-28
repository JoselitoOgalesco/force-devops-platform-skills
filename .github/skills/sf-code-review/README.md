# sf-code-review

Review Salesforce code for security, performance, and best practices.

## Description

This skill provides a structured approach to code review using Salesforce Code Analyzer (`sf scanner`) with PMD rules and a 25-point quality rubric. Covers security vulnerabilities, governor limit violations, bulkification, patterns, and completeness.

## Features

- **Code Analyzer** — Run `sf scanner` with PMD, ESLint, and security rules
- **Quality Rubric** — Score code 0-25 across 5 categories
- **Security Scan** — Detect CRUD/FLS violations, injection risks
- **Governor Limits** — Find SOQL/DML in loops
- **Best Practices** — Check naming, patterns, structure
- **CI/CD Ready** — GitHub Actions and pre-commit hooks

## Quick Start

1. Install Code Analyzer: `sf plugins install @salesforce/sfdx-scanner`
2. Run scan: `sf scanner run --target force-app/ --format table`
3. Score against rubric (Security, Limits, Bulk, Patterns, Completeness)
4. Generate review report with findings

## Usage

Invoke this skill when:
- Reviewing pull requests
- Pre-deployment validation
- AppExchange security review prep
- Learning Salesforce best practices
- Auditing existing code

## Commands

```bash
# Full scan
sf scanner run --target force-app/ --format table

# Security only
sf scanner run --target force-app/ --category Security

# Fail on critical issues
sf scanner run --target force-app/ --severity-threshold 2

# Export report
sf scanner run --target force-app/ --format html --outfile report.html
```

## Related Skills

- [sf-security](../sf-security/) — CRUD/FLS and sharing model
- [sf-apex](../sf-apex/) — Apex patterns and governor limits
- [sf-test](../sf-test/) — Test class best practices
- [sf-eval](../sf-eval/) — Detailed evaluation rubric
