# GitHub Copilot Instructions

> See [AGENTS.md](/AGENTS.md) for full context. This file ensures GitHub Copilot loads workspace instructions automatically.

## Quick Start

```bash
./force-platform-skills/install.sh   # Install skills to all AI tool locations
npm run lint && npm run prettier     # Lint and format
npm run test:unit                    # Run Jest tests (LWC)
sf scanner run --target force-app/   # Run Salesforce Code Analyzer
```

## Project Overview

**vibe-skills** is a Salesforce AI skills library containing 19 skills for development assistance. The skills are installed to `.github/skills/`, `.claude/skills/`, and `.agents/skills/`.

## Conventions

- **Author metadata**: `AI generated for Force.com DevOps Platform Team`
- **API versions**: 62.0 (LWC), 66.0 (Apex/project)
- **Skill structure**: Each skill has `SKILL.md` + `README.md` + optional `references/`

## Instruction Files

These files have `applyTo` patterns and are automatically loaded for matching files:

| File | Applies To |
|------|------------|
| [apex.instructions.md](.github/instructions/apex.instructions.md) | `**/*.cls` |
| [lwc.instructions.md](.github/instructions/lwc.instructions.md) | `**/lwc/**` |
| [flow.instructions.md](.github/instructions/flow.instructions.md) | `**/*.flow-meta.xml` |
| [test.instructions.md](.github/instructions/test.instructions.md) | `**/*Test.cls` |
| [skills-authoring.instructions.md](.github/instructions/skills-authoring.instructions.md) | `**/skills/**/*.md` |

## Skills

Use `/sf-find` to discover which skill applies. Available skills:

| Category | Skills |
|----------|--------|
| **Development** | `sf-apex`, `sf-lwc`, `sf-soql`, `sf-test` |
| **Configuration** | `sf-flow`, `sf-schema`, `sf-permissions` |
| **Operations** | `sf-deploy`, `sf-data`, `sf-debug` |
| **Security** | `sf-security`, `sf-code-review`, `sf-eval` |
| **Specialized** | `sf-agentforce`, `sf-omnistudio`, `sf-diagram`, `sf-integration` |
| **Discovery** | `sf-find`, `sf-docs` |

## Agents

| Agent | Purpose |
|-------|---------|
| `sf-reviewer` | Code review with security, bulkification, and best practices checks |

## Org Access

⚠️ **Always ask before modifying data** in Salesforce orgs, especially:
- `coretest`, `coreqa`, `coredev1`, `coredev2`
- Any sandbox or production org

## References

- [AGENTS.md](/AGENTS.md) — Canonical instructions
- [force-platform-skills/README.md](/force-platform-skills/README.md) — Full skill inventory
- [force-platform-skills/references/governor-limits.md](/force-platform-skills/references/governor-limits.md) — Salesforce limits
