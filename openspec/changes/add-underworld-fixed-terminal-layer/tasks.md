## 1. Contracts and Scope
- [x] 1.1 Define deterministic single-underworld-per-world placement contract anchored above bedrock transition.
- [x] 1.2 Define scale contract: near full-circumference horizontal presence and minimum vertical span of 180 tiles.
- [x] 1.3 Define aggressive morphology contract (giant cavity base, cliff systems, suspended island groups).
- [x] 1.4 Define controlled bedrock-transition intrusion bounds and hard-floor safety invariants.

## 2. Traversal and Progression
- [x] 2.1 Define guaranteed natural primary access route from mid-cavern into underworld.
- [x] 2.2 Define seam-continuity contract for access and underworld geometry across wrapped chunk boundaries.

## 3. Resource Economy Integration
- [x] 3.1 Define +30% ore density uplift contract for underworld-adjacent zones.
- [x] 3.2 Define deterministic compatibility with existing mineral depth/rarity affinities.

## 4. Save and Compatibility
- [x] 4.1 Define legacy metadata backfill policy with explicit non-forced-rewrite behavior for existing saves.
- [x] 4.2 Define metadata/versioning markers needed to detect underworld-enabled worlds.

## 5. Validation
- [x] 5.1 Add deterministic regression cases for underworld placement, size, and morphology invariants.
- [x] 5.2 Add regression cases for guaranteed route existence and chunk-seam continuity.
- [x] 5.3 Add regression cases for ore-density uplift and no-regression in liquid/bedrock safety behavior.
- [x] 5.4 Add performance guardrail checks for traversal-critical generation path.

## 6. OpenSpec Hygiene
- [x] 6.1 Ensure proposal/design/spec deltas align with independent capability boundary `underworld-generation`.
- [x] 6.2 Run `openspec validate add-underworld-fixed-terminal-layer --strict` and resolve all issues.
