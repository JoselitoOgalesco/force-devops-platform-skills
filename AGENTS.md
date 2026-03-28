# vibe-skills

Salesforce AI skills library with 19 development skills.

## Quick Start

```bash
./force-platform-skills/install.sh   # Install skills to all AI tool locations
npm run lint && npm run prettier     # Lint and format
npm run test:unit                     # Run Jest tests
npm run prettier:verify              # Check formatting
```

## Structure

| Directory | Purpose |
|-----------|---------|
| `force-platform-skills/skills/` | Source skills (19 total) |
| `.github/skills/` `.claude/skills/` `.agents/skills/` | Installation targets |
| `force-app/` | Salesforce metadata (when developing) |

## Skills

Use `/sf-find` to discover which skill applies, or load a specific skill directly. For the full catalog and descriptions, see [force-platform-skills/README.md](/Users/joeyogalesco/Projects/Vibe Coding/vibe-skills/force-platform-skills/README.md).

## Conventions

- **Author**: `AI generated for Force.com DevOps Platform Team`
- **API Version**: 62.0 (LWC), 66.0 (Apex/project)
- **Skill structure**: `SKILL.md` + `README.md` + `references/` folder
- **Instruction files**: See [.github/instructions](/Users/joeyogalesco/Projects/Vibe Coding/vibe-skills/.github/instructions) for Apex, LWC, Flow, test, and skills authoring rules

## References

- [force-platform-skills/README.md](/Users/joeyogalesco/Projects/Vibe Coding/vibe-skills/force-platform-skills/README.md) - Installation and full skill inventory
- [force-platform-skills/TEST_VALIDATION.md](/Users/joeyogalesco/Projects/Vibe Coding/vibe-skills/force-platform-skills/TEST_VALIDATION.md) - Skill validation coverage
- [force-platform-skills/TEST-RUN-REPORT.md](/Users/joeyogalesco/Projects/Vibe Coding/vibe-skills/force-platform-skills/TEST-RUN-REPORT.md) - Test run summary
- [force-platform-skills/references/governor-limits.md](/Users/joeyogalesco/Projects/Vibe Coding/vibe-skills/force-platform-skills/references/governor-limits.md) - Salesforce governor limits reference

## Org Access

Always ask before modifying data in orgs, especially `coretest`, `coreqa`, `coredev1`, `coredev2`, or any sandbox/production org.
