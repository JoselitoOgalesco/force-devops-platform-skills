# sf-test Merged Skill

**Version:** 2.0.0  
**Merged From:** `force-platform-skills/skills/sf-test/SKILL.md` (v1.0.0) + `improved-skills/sf-test-IMPROVEMENTS.md`

## Change Summary

| Section | Change Type | Description |
|---------|-------------|-------------|
| Aligning Tests with Implementation Behavior | **NEW** | Don't assume exceptions; check implementation first |
| Pattern A/B/C (Defensive/Strict/Permissive) | **NEW** | Three patterns for null handling behavior |
| Flexible Test Template | **NEW** | Test pattern for unknown implementation behavior |
| Test Generation Workflow | **NEW** | 4-step process for generating accurate tests |
| Testing Record Status Values | **NEW** | Match test data to actual field implementation checks |
| Rules table | **EXTENDED** | Added "ALWAYS read implementation first" |
| Gotchas table | **EXTENDED** | Added wrong assertion pattern warning |

## Why These Changes?

The improvements address a common issue where generated tests assume specific exception-throwing behavior that doesn't match the actual implementation.

### Problem Symptoms

- Generated tests expect `IllegalArgumentException` for null input
- Implementation returns empty list instead of throwing
- Tests fail with "Should have thrown exception"

### Root Cause

The original skill assumed strict validation patterns (throw on invalid input). Many implementations use defensive patterns (return empty/null).

### Solutions Added

| Pattern | Implementation Style | Test Approach |
|---------|---------------------|---------------|
| A - Defensive | `return new List<>()` | Assert empty result |
| B - Strict | `throw new IllegalArgumentException()` | Catch and verify exception |
| C - Permissive | No validation, let SOQL handle | Assert non-null result |

### New Workflow

1. **Analyze implementation** — What does it actually do on null/invalid input?
2. **Map behaviors** — Document each edge case behavior
3. **Generate tests** — Match assertions to actual behavior
4. **Adjust after run** — Fix any remaining mismatches

## Files

- [SKILL.md](SKILL.md) — Full merged skill

## Original Sources

- [`force-platform-skills/skills/sf-test/SKILL.md`](../../force-platform-skills/skills/sf-test/SKILL.md)
- [`improved-skills/sf-test-IMPROVEMENTS.md`](../../improved-skills/sf-test-IMPROVEMENTS.md)
