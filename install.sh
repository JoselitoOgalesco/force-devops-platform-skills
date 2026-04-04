#!/bin/bash
# =============================================================================
# Force Platform Skills - Multi-Platform Installer
# =============================================================================
# Installs Salesforce development skills for multiple AI coding assistants:
# - GitHub Copilot (.github/skills/)
# - Claude/Cursor (.claude/skills/)
# - Generic agents (.agents/skills/)
#
# Usage:
#   ./install.sh                    # Install to current project
#   ./install.sh /path/to/project   # Install to specific project
#   ./install.sh --global           # Install to user home directory
#   ./install.sh --uninstall        # Remove installed skills
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/skills"
REFERENCES_SOURCE="$SCRIPT_DIR/references"
AGENTS_SOURCE="$SCRIPT_DIR/agents"

# Default target is current directory
TARGET_DIR="$(pwd)"
GLOBAL_INSTALL=false
UNINSTALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)
            GLOBAL_INSTALL=true
            TARGET_DIR="$HOME"
            shift
            ;;
        --uninstall|-u)
            UNINSTALL=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [options] [target-directory]"
            echo ""
            echo "Options:"
            echo "  --global, -g      Install to user home directory (~/.github, ~/.claude, ~/.agents)"
            echo "  --uninstall, -u   Remove installed skills"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        Install to current project"
            echo "  $0 /path/to/project       Install to specific project"
            echo "  $0 --global               Install globally for user"
            echo "  $0 --uninstall            Remove skills from current project"
            exit 0
            ;;
        *)
            TARGET_DIR="$1"
            shift
            ;;
    esac
done

# Directories to install to
COPILOT_DIR="$TARGET_DIR/.github/skills"
CLAUDE_DIR="$TARGET_DIR/.claude/skills"
AGENTS_DIR="$TARGET_DIR/.agents/skills"

# Agent directories
COPILOT_AGENTS_DIR="$TARGET_DIR/.github/agents"
CLAUDE_AGENTS_DIR="$TARGET_DIR/.claude/agents"
GENERIC_AGENTS_DIR="$TARGET_DIR/.agents/agents"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Force Platform Skills - Multi-Platform Installer     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Uninstall mode
if [ "$UNINSTALL" = true ]; then
    echo -e "${YELLOW}Uninstalling skills from: $TARGET_DIR${NC}"

    for dir in "$COPILOT_DIR" "$CLAUDE_DIR" "$AGENTS_DIR"; do
        if [ -d "$dir" ]; then
            for skill in sf-apex sf-lwc sf-soql sf-test sf-flow sf-schema sf-permissions \
                         sf-integration sf-deploy sf-data sf-debug sf-security \
                         sf-agentforce sf-omnistudio sf-diagram sf-docs sf-find \
                         sf-code-review sf-eval sf-scratch-org; do
                if [ -d "$dir/$skill" ]; then
                    rm -rf "$dir/$skill"
                    echo -e "  ${RED}✗${NC} Removed $dir/$skill"
                fi
            done
        fi
    done

    echo -e "${YELLOW}Uninstalling agents from: $TARGET_DIR${NC}"

    for dir in "$COPILOT_AGENTS_DIR" "$CLAUDE_AGENTS_DIR" "$GENERIC_AGENTS_DIR"; do
        if [ -d "$dir" ]; then
            for agent in sf-reviewer devops-researcher release-dependency-engine; do
                if [ -f "$dir/$agent.agent.md" ]; then
                    rm -f "$dir/$agent.agent.md"
                    echo -e "  ${RED}✗${NC} Removed $dir/$agent.agent.md"
                fi
            done
        fi
    done

    echo -e "\n${GREEN}✓ Uninstall complete${NC}"
    exit 0
fi

# Check source exists
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo -e "${RED}Error: Skills source not found at $SKILLS_SOURCE${NC}"
    exit 1
fi

echo -e "${YELLOW}Source:${NC} $SKILLS_SOURCE"
echo -e "${YELLOW}Target:${NC} $TARGET_DIR"
echo ""

# Count skills
SKILL_COUNT=$(find "$SKILLS_SOURCE" -maxdepth 1 -type d -name "sf-*" | wc -l | tr -d ' ')
echo -e "${GREEN}Found $SKILL_COUNT skills to install${NC}"
echo ""

# Create directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$COPILOT_DIR"
mkdir -p "$CLAUDE_DIR"
mkdir -p "$AGENTS_DIR"

# Create README.md in each skills directory
SKILLS_README='# Salesforce Skills

AI skills for Salesforce development. Use `/sf-find` to discover which skill applies.

## Available Skills

| Skill | Purpose |
|-------|---------|
| sf-agentforce | Agentforce agents, topics, actions, PromptTemplates |
| sf-apex | Apex code generation and review |
| sf-code-review | Automated code review with Salesforce Code Analyzer |
| sf-data | Data migration, sandbox seeding, bulk operations |
| sf-debug | Debug logs, governor limits, troubleshooting |
| sf-deploy | Deployment and CI/CD workflows |
| sf-diagram | ERDs, class diagrams, and architecture diagrams |
| sf-docs | Salesforce documentation and ApexDoc guidance |
| sf-eval | Code quality evaluation and benchmarking |
| sf-find | Skill discovery and selection |
| sf-flow | Flow development |
| sf-integration | Named Credentials, Connected Apps, Platform Events |
| sf-lwc | Lightning Web Components |
| sf-omnistudio | OmniScripts, FlexCards, Integration Procedures |
| sf-permissions | Permission Sets, PSGs, access troubleshooting |
| sf-schema | Object and field design |
| sf-security | Security review |
| sf-soql | SOQL query building |
| sf-test | Test class generation |

## Usage

Load directly: `/sf-apex`, `/sf-lwc`, `/sf-flow`, `/sf-deploy`, etc.
'

for target in "$COPILOT_DIR" "$CLAUDE_DIR" "$AGENTS_DIR"; do
    echo "$SKILLS_README" > "$target/README.md"
done

# Install skills
install_skill() {
    local skill_path="$1"
    local skill_name=$(basename "$skill_path")

    echo -e "\n${YELLOW}Installing: $skill_name${NC}"

    # Copy to all platforms
    for target in "$COPILOT_DIR" "$CLAUDE_DIR" "$AGENTS_DIR"; do
        cp -r "$skill_path" "$target/"
        echo -e "  ${GREEN}✓${NC} $target/$skill_name"
    done
}

# Install each skill
for skill in "$SKILLS_SOURCE"/sf-*; do
    if [ -d "$skill" ]; then
        install_skill "$skill"
    fi
done

# Copy references if they exist
if [ -d "$REFERENCES_SOURCE" ]; then
    echo -e "\n${YELLOW}Copying references...${NC}"
    for target in "$COPILOT_DIR" "$CLAUDE_DIR" "$AGENTS_DIR"; do
        mkdir -p "$target/../references"
        cp -r "$REFERENCES_SOURCE"/* "$target/../references/" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} $(dirname "$target")/references/"
    done
fi

# Install agents if they exist
if [ -d "$AGENTS_SOURCE" ]; then
    AGENT_COUNT=$(find "$AGENTS_SOURCE" -maxdepth 1 -name "*.agent.md" | wc -l | tr -d ' ')
    echo -e "\n${BLUE}Installing $AGENT_COUNT agents...${NC}"

    # Create agent directories
    mkdir -p "$COPILOT_AGENTS_DIR"
    mkdir -p "$CLAUDE_AGENTS_DIR"
    mkdir -p "$GENERIC_AGENTS_DIR"

    for agent in "$AGENTS_SOURCE"/*.agent.md; do
        if [ -f "$agent" ]; then
            agent_name=$(basename "$agent")
            echo -e "\n${YELLOW}Installing agent: $agent_name${NC}"

            for target in "$COPILOT_AGENTS_DIR" "$CLAUDE_AGENTS_DIR" "$GENERIC_AGENTS_DIR"; do
                cp "$agent" "$target/"
                echo -e "  ${GREEN}✓${NC} $target/$agent_name"
            done
        fi
    done
fi

# Create workspace instruction files
echo -e "\n${BLUE}Creating workspace instruction file...${NC}"

# Single AGENTS.md file (works with all AI tools)
AGENTS_FILE="$TARGET_DIR/AGENTS.md"
if [ ! -f "$AGENTS_FILE" ]; then
    cat > "$AGENTS_FILE" << 'EOF'
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
EOF
    echo -e "  ${GREEN}✓${NC} Created $AGENTS_FILE"
else
    echo -e "  ${YELLOW}⚠${NC} Skipped $AGENTS_FILE (already exists)"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Installation Complete!                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Skills installed to:${NC}"
echo -e "  • $COPILOT_DIR"
echo -e "  • $CLAUDE_DIR"
echo -e "  • $AGENTS_DIR"
echo ""
echo -e "${BLUE}Agents installed to:${NC}"
echo -e "  • $COPILOT_AGENTS_DIR"
echo -e "  • $CLAUDE_AGENTS_DIR"
echo -e "  • $GENERIC_AGENTS_DIR"
echo ""
echo -e "${BLUE}Workspace file created:${NC}"
echo -e "  • AGENTS.md (works with all AI tools)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Restart your AI coding assistant"
echo -e "  2. Try: /sf-find to discover available skills"
echo -e "  3. Or load directly: /sf-apex, /sf-lwc, etc."
echo -e "  4. Use @devops-researcher, @release-dependency-engine, or @sf-reviewer for specialized agents"
