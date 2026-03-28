# sf-deploy

Deploy Salesforce metadata safely and efficiently.

## Description

This skill provides guidance for deploying metadata to Salesforce orgs using SFDX, Metadata API, and change sets. Covers deployment strategies, validation, quick deploy, rollback planning, and CI/CD integration.

## Features

- **SFDX Deployment** — sf project deploy commands
- **Metadata API** — Package.xml-based deployments
- **Change Sets** — Point-and-click deployment
- **Validation** — Check-only deployments before committing
- **Quick Deploy** — Reuse validated deployments
- **Rollback Planning** — Destructive changes and recovery
- **CI/CD Integration** — GitHub Actions, Jenkins pipelines

## Quick Start

1. Validate deployment: `sf project deploy start --dry-run`
2. Review test results and coverage
3. Deploy: `sf project deploy start`
4. Verify in target org
5. Document changes for rollback

## Usage

Invoke this skill when:
- Deploying metadata to production
- Setting up CI/CD pipelines
- Planning rollback strategies
- Troubleshooting deployment errors

## Related Skills

- [sf-debug](../sf-debug/) — Deployment error diagnosis
- [sf-test](../sf-test/) — Test coverage requirements
- [sf-schema](../sf-schema/) — Metadata dependencies
