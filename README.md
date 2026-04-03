# Force Platform Skills

Comprehensive Salesforce development skills for AI coding assistants. Compatible with GitHub Copilot, Claude, Cursor, Codex, Gemini, and other LLM-powered coding tools.

## Installation

### Quick Install (Recommended)

```bash
# Clone or download, then run:
./install.sh

# Or install to a specific project:
./install.sh /path/to/your/project

# Install globally (user-level):
./install.sh --global

# Uninstall:
./install.sh --uninstall
```

The installer creates skills in all supported locations:

| AI Tool | Skills Location | Instructions File |
|---------|-----------------|-------------------|
| GitHub Copilot | `.github/skills/` | `.github/copilot-instructions.md` |
| Claude/Cursor | `.claude/skills/` | `CLAUDE.md` |
| Generic Agents | `.agents/skills/` | `AGENTS.md` |

### Manual Installation

Copy the `skills/` folder to your project under the appropriate path for your AI tool:

```bash
# GitHub Copilot
cp -r skills/* .github/skills/

# Claude / Cursor
cp -r skills/* .claude/skills/

# Generic
cp -r skills/* .agents/skills/
```

## Skills

### Code Development
| Skill | Purpose |
|-------|---------|
| `sf-apex` | Apex classes, triggers, async patterns, governor limits, CRUD/FLS |
| `sf-lwc` | Lightning Web Components, Jest tests, wire adapters |
| `sf-soql` | SOQL queries, optimization, relationship queries, aggregates |
| `sf-test` | Test classes, code coverage, mocking, async testing |

### Configuration & Schema
| Skill | Purpose |
|-------|---------|
| `sf-flow` | Flows, Process Builder migration, automation best practices |
| `sf-schema` | Custom objects, fields, validation rules, metadata XML |
| `sf-permissions` | Permission Sets, PSGs, CRUD/FLS auditing, access troubleshooting |

### Integration
| Skill | Purpose |
|-------|---------|
| `sf-integration` | Named Credentials, Connected Apps, Platform Events, CDC |

### Operations
| Skill | Purpose |
|-------|---------|
| `sf-deploy` | Deployment, CI/CD, package.xml, error diagnosis |
| `sf-data` | Data migration, sandbox seeding, bulk operations |
| `sf-debug` | Debug logs, governor limits, error diagnosis |

### Security & Compliance
| Skill | Purpose |
|-------|---------|
| `sf-security` | Security auditing, CRUD/FLS, AppExchange review |

### Specialized
| Skill | Purpose |
|-------|---------|
| `sf-agentforce` | Agentforce AI agents, topics, actions, PromptTemplates |
| `sf-omnistudio` | OmniScripts, FlexCards, Integration Procedures, Data Mappers |
| `sf-diagram` | ERDs, class diagrams, sequence diagrams from metadata |
| `sf-docs` | Salesforce documentation navigation |
| `sf-code-review` | Automated code review with Salesforce Code Analyzer |

### Discovery
| Skill | Purpose |
|-------|---------|
| `sf-find` | Skill discovery and selection |

## References

| File | Purpose |
|------|---------|
| `references/governor-limits.md` | Per-transaction limits, async limits, monitoring |

## Requirements

- Salesforce CLI v2+ (`sf`)
- Authenticated org (`sf org login web`)

## Compatibility

| AI Tool | Tested | Notes |
|---------|--------|-------|
| GitHub Copilot | ✅ | Full support via `.github/skills/` |
| Claude (Anthropic) | ✅ | Full support via `.claude/skills/` or CLAUDE.md |
| Cursor | ✅ | Uses Claude path `.claude/skills/` |
| Codex (OpenAI) | ✅ | Uses AGENTS.md instructions |
| Gemini (Google) | ✅ | Uses AGENTS.md instructions |
| Windsurf | ✅ | Uses `.agents/skills/` |
| Cody (Sourcegraph) | ✅ | Uses AGENTS.md instructions |

## Usage

After installation, invoke skills in your AI assistant:

```
/sf-apex        # Load Apex development skill
/sf-lwc         # Load LWC development skill
/sf-find        # Discover which skill to use
```

Or reference skills in prompts:
```
Using the sf-apex skill, create a trigger handler for Account...
```

## Key Features

- **Multi-platform compatible** - Works with all major AI coding tools
- **Detailed instructions** - Step-by-step guides for junior developers
- **Governor limits awareness** - Built-in limit checking throughout
- **CRUD/FLS compliance** - Security patterns enforced
- **Bulkification** - Collection-based patterns for scale
- **Self-contained** - No broken links, all content included
- **Real-world examples** - Based on Salesforce best practices

## Contributing

1. Fork the repository
2. Add or modify skills in `skills/` directory
3. Each skill needs:
   - `SKILL.md` with YAML frontmatter (name, description)
   - `references/` folder for supplementary docs
4. Run `./install.sh` to test locally
5. Submit a pull request

## Author

AI generated for Force.com DevOps Platform Team
