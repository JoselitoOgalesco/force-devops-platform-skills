# sf-code-review (Merged)

Merged version combining the original skill with runtime validation improvements.

## Changes from Original

| Feature | Original | Merged |
|---------|----------|--------|
| Rubric | 25 points (static) | 30 points (+5 runtime) |
| Static Analysis | ✅ Full coverage | ✅ Full coverage |
| Runtime Validation | ❌ Not covered | ✅ Full workflow |
| Schema Verification | ❌ Not covered | ✅ FieldDefinition queries |
| Post-Deployment | ❌ Not covered | ✅ Verification scripts |
| Schema Sync Issues | ❌ Not covered | ✅ Diagnosis + resolution |
| Report Template | ❌ Not included | ✅ Combined static + runtime |

## Version

- Original: 2.0.0
- Merged: 3.0.0

## Usage

```bash
# Run static analysis
sf code-analyzer run --workspace force-app/ --view table

# Then run runtime validation
sf apex run test --test-level RunLocalTests --target-org myOrg --wait 10
```
