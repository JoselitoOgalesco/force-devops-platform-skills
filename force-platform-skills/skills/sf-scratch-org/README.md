# sf-scratch-org

Create and manage Salesforce scratch orgs for development and testing.

## Description

This skill helps you create, configure, and troubleshoot scratch orgs with proper feature enablement, phased deployment strategies, and schema synchronization fixes. Use for setting up development environments, debugging fresh org issues, or automating scratch org workflows.

## Features

- **Scratch Org Lifecycle** — Create, configure, deploy, and delete scratch orgs
- **Edition Selection** — Choose Developer, Enterprise, Professional, or Group based on your needs
- **Phased Deployment** — Deploy objects first, then Apex to avoid schema sync issues
- **Schema Troubleshooting** — Fix "No such column" errors with recompilation strategies
- **Feature Configuration** — Enable Communities, ServiceCloud, PersonAccounts, and more
- **Automation Scripts** — Scriptable setup for consistent environments

## Quick Start

1. Create scratch org: `sf org create scratch -f config/project-scratch-def.json -a my-scratch -d 30`
2. Deploy objects first: `sf project deploy start -d force-app/main/default/objects/ -o my-scratch`
3. Deploy Apex second: `sf project deploy start -d force-app/main/default/classes/ -o my-scratch`
4. Assign permission sets: `sf org assign permset -n My_Permission_Set -o my-scratch`
5. Import data: `sf data import tree -p data/sample-data-plan.json -o my-scratch`

## Usage

Invoke this skill when:
- Creating new scratch orgs for development
- Troubleshooting "No such column" or schema errors
- Configuring project-scratch-def.json features
- Setting up automated scratch org creation scripts
- Debugging deployment failures in fresh orgs

## Related Skills

- [sf-deploy](../sf-deploy/) — Deployment strategies and error handling
- [sf-test](../sf-test/) — Running tests in scratch orgs
- [sf-data](../sf-data/) — Importing test data
- [sf-permissions](../sf-permissions/) — Managing permission sets
