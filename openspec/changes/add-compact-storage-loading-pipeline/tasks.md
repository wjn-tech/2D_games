## 1. Specification
- [x] 1.1 Define compact artifact read contract (identity, schema, chunk-key lookup, decode result model).
- [x] 1.2 Define fallback precedence contract (compact -> legacy -> regeneration).
- [x] 1.3 Define load-branch telemetry contract and reason-code taxonomy.

## 2. Loading Pipeline Design
- [x] 2.1 Define bounded load scheduling behavior and startup integration points.
- [x] 2.2 Define corruption handling and quarantine lifecycle for invalid compact artifacts.
- [x] 2.3 Define canonical coordinate normalization requirements before storage lookup.

## 3. Verification
- [x] 3.1 Add validation cases for compact hit, legacy hit, and regeneration fallback.
- [x] 3.2 Add validation cases for corrupted compact artifacts and non-crashing fallback.
- [x] 3.3 Add determinism verification across different load branches.
- [x] 3.4 Run `openspec validate add-compact-storage-loading-pipeline --strict` and resolve all issues.