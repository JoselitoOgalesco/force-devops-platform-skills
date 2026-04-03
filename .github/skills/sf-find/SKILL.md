---
name: sf-find
description: Discover the right Salesforce skill for your task.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, discovery, help
---

# Skill Finder

Find the right Salesforce skill for your task.

## Available Skills

| Skill | Use When |
|-------|----------|
| **sf-apex** | Write/review Apex classes, triggers, batch jobs, queueable jobs |
| **sf-lwc** | Build Lightning Web Components with HTML, JS, CSS, Jest tests |
| **sf-soql** | Write/optimize SOQL queries, relationship queries, aggregates |
| **sf-test** | Generate test classes, improve coverage, fix failing tests |
| **sf-flow** | Create Flows, migrate Process Builders, automation best practices |
| **sf-deploy** | Deploy code, CI/CD pipelines, troubleshoot deployment errors |
| **sf-schema** | Create custom objects, fields, permission sets, metadata XML |
| **sf-data** | Data migration, sandbox seeding, bulk operations, CSV import |
| **sf-security** | Security audits, CRUD/FLS compliance, AppExchange review |
| **sf-debug** | Analyze debug logs, troubleshoot errors, profile performance |
| **sf-permissions** | Permission Sets, PSGs, FLS auditing, access troubleshooting |
| **sf-integration** | Named Credentials, Connected Apps, Platform Events, CDC |
| **sf-diagram** | Generate ERDs, class diagrams, sequence diagrams from metadata |
| **sf-agentforce** | Build Agentforce AI agents, topics, actions, PromptTemplates |
| **sf-omnistudio** | OmniScripts, FlexCards, Integration Procedures, Data Mappers |
| **sf-docs** | Find Salesforce documentation, Trailhead resources, CLI help |

## Decision Guide

### Code Development
1. **Writing Apex?** → `sf-apex`
2. **Building components?** → `sf-lwc`
3. **Need queries?** → `sf-soql`
4. **Need tests?** → `sf-test`

### Configuration
5. **Building automation?** → `sf-flow`
6. **Setting up schema?** → `sf-schema`
7. **Permission problems?** → `sf-permissions`
8. **Setting up integrations?** → `sf-integration`

### Operations
9. **Ready to deploy?** → `sf-deploy`
10. **Loading data?** → `sf-data`
11. **Debugging issues?** → `sf-debug`

### Specialized
12. **Security review?** → `sf-security`
13. **Building AI agents?** → `sf-agentforce`
14. **Working with OmniStudio?** → `sf-omnistudio`
15. **Visualizing architecture?** → `sf-diagram`
16. **Need Salesforce docs?** → `sf-docs`

## By Task

| Task | Recommended Skill |
|------|------------------|
| Write an Apex class | sf-apex |
| Create a trigger | sf-apex |
| Build a batch job | sf-apex |
| Create a Lightning component | sf-lwc |
| Write Jest tests for LWC | sf-lwc |
| Optimize a slow query | sf-soql |
| Write test coverage | sf-test |
| Build a screen flow | sf-flow |
| Migrate Process Builder | sf-flow |
| Create custom objects/fields | sf-schema |
| Create permission sets | sf-permissions |
| Set up API integration | sf-integration |
| Configure Platform Events | sf-integration |
| Deploy to production | sf-deploy |
| Fix deployment errors | sf-deploy |
| Load test data | sf-data |
| Seed sandbox | sf-data |
| Analyze debug logs | sf-debug |
| Fix governor limit error | sf-debug + sf-apex |
| Prepare for security review | sf-security |
| Build ERD diagram | sf-diagram |
| Build Agentforce agent | sf-agentforce |
| Create OmniScript | sf-omnistudio |
| Find documentation | sf-docs |

## By Error Message

| Error Contains | Check Skill |
|---------------|-------------|
| `Too many SOQL queries` | sf-apex, sf-debug |
| `UNABLE_TO_LOCK_ROW` | sf-debug |
| `MIXED_DML_OPERATION` | sf-debug, sf-test |
| `INSUFFICIENT_ACCESS` | sf-permissions, sf-security |
| `Deployment failed` | sf-deploy |
| `CRUD/FLS` | sf-security |

## Requirements

All skills require:
- Salesforce CLI v2+ (`sf`)
- Authenticated org (`sf org login web -a myOrg`)

## References

See [references/governor-limits.md](../../../references/governor-limits.md) for Salesforce per-transaction limits.
