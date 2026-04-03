# sf-eval

Evaluate and score Salesforce skill outputs for quality.

## Description

This skill provides a comprehensive 25-point evaluation rubric for assessing the quality of Salesforce code, configurations, and documentation. Use to validate outputs from other skills and ensure production readiness.

## Features

- **Code Quality Rubric** — Governor limits, bulkification, security
- **Test Coverage Scoring** — Assertions, scenarios, mocking
- **Documentation Scoring** — ApexDoc, README, comments
- **Security Evaluation** — CRUD/FLS, injection, sharing rules
- **Performance Assessment** — Query efficiency, async patterns
- **Best Practice Validation** — Salesforce standards compliance

## Quick Start

1. Run the skill output through the 25-point rubric
2. Score each category (1-5 scale)
3. Calculate total score (out of 25)
4. Address items scoring below 4
5. Re-evaluate after fixes

## Usage

Invoke this skill when:
- Reviewing code before deployment
- Validating skill outputs
- Conducting code reviews
- Assessing solution quality

## Related Skills

- [sf-apex](../sf-apex/) — Code to evaluate
- [sf-test](../sf-test/) — Test coverage evaluation
- [sf-security](../sf-security/) — Security evaluation
