# sf-deploy Merged Skill

**Version:** 3.0.0
**Merged From:** `force-platform-skills/skills/sf-deploy/SKILL.md` (v2.0.0) + `improved-skills/sf-deploy-IMPROVEMENTS.md`

## Change Summary

| Section | Change Type | Description |
|---------|-------------|-------------|
| Phased Deployment for Fresh Scratch Orgs | **NEW** | Deploy in phases to avoid schema cache issues |
| Fresh Scratch Org Deployment Checklist | **NEW** | Step-by-step checklist for new scratch orgs |
| Apex Schema Cache Issues | **NEW** | Diagnosis and 3 solutions for "No such column" errors |
| Common Deployment Errors | **EXTENDED** | Added schema cache error patterns |

## Why These Changes?

The improvements address a specific issue observed when:

1. Custom objects and Apex are deployed atomically to a fresh scratch org
2. Apex compiles before object metadata is fully registered in the schema cache
3. The compiled Apex cannot query fields that technically exist ("No such column" error)

### Problem Symptoms

- Deployment reports success
- Fields visible in Setup > Object Manager
- Fields appear in FieldDefinition query
- Runtime error: `No such column 'MyField__c' on 'MyObject__c'`

### Solutions Added

| Solution | Approach |
|----------|----------|
| Phased Deployment | Deploy objects first, verify, then deploy Apex |
| Force Recompilation | Add version comment to trigger recompile |
| MDAPI for Objects | Use MDAPI deployment path for schema components |
| Tooling API Compile | Query ApexClass to trigger metadata refresh |

## Files

- [SKILL.md](SKILL.md) — Full merged skill

## Original Sources

- [`force-platform-skills/skills/sf-deploy/SKILL.md`](../../force-platform-skills/skills/sf-deploy/SKILL.md)
- [`improved-skills/sf-deploy-IMPROVEMENTS.md`](../../improved-skills/sf-deploy-IMPROVEMENTS.md)
