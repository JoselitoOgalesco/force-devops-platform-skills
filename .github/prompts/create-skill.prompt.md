---
description: "Create a new Salesforce skill. Use when: adding capabilities, creating sf- skills, building new skill templates."
mode: agent
---

# Create Salesforce Skill

Create a new skill in the `force-platform-skills/skills/` directory.

## Inputs

- **Name**: ${input:skillName:Skill name (without sf- prefix)}
- **Purpose**: ${input:purpose:What does this skill help with?}
- **Triggers**: ${input:triggers:When should AI use this skill? (comma-separated)}

## Skill Folder

Create `force-platform-skills/skills/sf-${skillName}/` with:

### SKILL.md

```yaml
---
name: sf-${skillName}
description: |
  ${purpose}. Use when ${triggers}.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, ${skillName}
---
```

Body should include:
1. **Persona statement** - "You are a Salesforce {role} specialist..."
2. **Reference tables** - Limits, patterns, common values
3. **Code examples** - Production-ready, copy-pasteable
4. **Anti-patterns** - What NOT to do
5. **Troubleshooting** - Common errors and fixes

### README.md

```markdown
# sf-${skillName}

${purpose}

## Usage

Load with `/sf-${skillName}` or let AI auto-detect from context.

## When to Use

- ${triggers (as bullet list)}

## Contents

- SKILL.md - Main skill instructions
- references/ - Supporting documentation
```

### references/ (optional)

Add supporting docs if needed (templates, error codes, etc.)

## After Creation

1. Run `./force-platform-skills/install.sh` to deploy to all locations
2. Test: Ask AI to load `/sf-${skillName}`
3. Test auto-discovery by describing a task matching the triggers
