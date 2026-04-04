# Salesforce AI Skills

Skills library for AI coding assistants.

## Quick Start

```bash
./install.sh                         # Install skills to all AI tool locations
npm run lint && npm run prettier     # Lint and format
npm run test:unit                    # Run Jest tests
npm run prettier:verify              # Check formatting
```

## Skills

Use `/sf-find` to discover which skill applies, or load a specific skill directly. See `README.md` for the full catalog.

## Structure

| Directory | Purpose |
|-----------|---------|
| `.github/skills/` `.claude/skills/` `.agents/skills/` | Installation targets |
| `force-app/` | Salesforce metadata (when developing) |

## Conventions

- **Author**: `AI generated for Force.com DevOps Platform Team`
- **API Version**: 62.0 (LWC), 66.0 (Apex/project)
- **Security**: Enforce CRUD/FLS via `Schema.stripInaccessible()` and `WITH USER_MODE`
- **Skill structure**: `SKILL.md` + `README.md` + `references/` folder
