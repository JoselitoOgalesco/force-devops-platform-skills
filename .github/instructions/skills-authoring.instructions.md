---
applyTo: "**/skills/**/*.md"
---

# Skills Authoring Guidelines

## Skill Structure

Each skill folder must contain:

```
skills/sf-{name}/
├── SKILL.md       # Required: Main skill file with frontmatter
├── README.md      # Required: Human-readable documentation
└── references/    # Optional: Supporting docs, templates
```

## SKILL.md Format

```yaml
---
name: sf-{name}
description: |
  {One sentence describing what it does}. Use when {specific triggers}.
metadata:
  author: AI generated for Force.com DevOps Platform Team
  version: "1.0.0"
  tags: salesforce, {relevant-tags}
---
```

### Description Best Practices

The `description` field is how AI tools discover skills. Include:
- Primary purpose in first sentence
- "Use when:" clause with specific trigger phrases
- Keywords users might search for

**Good**: `Generate Apex test classes with proper TestSetup, mocking, and assertions. Use when writing unit tests, creating test coverage, or fixing test failures.`

**Bad**: `Helps with Apex testing.`

## Content Guidelines

1. **Start with context** - Brief persona or purpose statement
2. **Include reference tables** - Limits, patterns, error codes
3. **Show code examples** - Real, copy-pasteable patterns
4. **Add anti-patterns** - What NOT to do with explanations
5. **Keep actionable** - Every section should guide behavior

## Naming Convention

- Prefix: `sf-` for Salesforce skills
- Lowercase, hyphenated: `sf-apex`, `sf-lwc`, `sf-flow`
- Name must match folder and frontmatter `name` field

## Testing Skills

After creating or updating a skill:
1. Run install script: `./force-platform-skills/install.sh`
2. Test discovery: Ask AI to load the skill by name
3. Test trigger phrases: Ask without naming skill, verify it activates
