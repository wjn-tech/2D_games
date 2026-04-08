## 1. Contracts and Metrics
- [x] 1.1 Define underground zoning contract that combines depth band and macro-region context into deterministic underground region classes.
- [x] 1.2 Define cave archetype budget contract, including minimum large-cavern opportunities and long-route connector opportunities in representative traversal windows.
- [x] 1.3 Define ore deposition contract for connected cluster-first ore bodies and prohibit purely pointwise scatter as the dominant pattern.
- [x] 1.4 Define quality metrics and acceptance thresholds for: large-cavern frequency, ore connectedness, cross-chunk continuity, underground regional diversity, and traversal reachability.
- [x] 1.5 Define medium-strength stratification contract (clear transitions without harsh discontinuities).
- [x] 1.6 Define spawn-safe early-descent contract (at least one beginner-friendly route within bounded travel distance).

## 2. Generation Design (No Code in Proposal Stage)
- [x] 2.1 Specify traversal-critical vs deferred-enrichment responsibilities for cave shaping and ore deposition to preserve runtime smoothness.
- [x] 2.2 Specify deterministic seeding model for region zoning, cavern budgets, and ore body growth across chunk boundaries.
- [x] 2.3 Specify metadata contract for downstream systems and debug tools (region id, archetype id, deposit family, connectivity hints).
- [x] 2.4 Specify liquid contract preservation boundaries (no behavioral regressions in liquid generation/simulation interfaces).
- [x] 2.5 Specify save-compatibility policy: no forced retroactive rewrite of existing worlds; new rules apply to new world generation/new chunks.

## 3. Validation Plan
- [x] 3.1 Define seed-regression validation cases for underground diversity (region entropy, chamber-scale distribution, route continuity).
- [x] 3.2 Define ore validation cases (connected-component sizes, cross-chunk continuity, depth profile correctness, zone/depth bias).
- [x] 3.3 Define performance guardrail checks to ensure new logic does not regress walking-time chunk streaming smoothness (balanced quality profile).
- [x] 3.4 Define liquid regression checks to prove liquid behavior remains intact.

## 4. OpenSpec Hygiene
- [x] 4.1 Ensure proposal, design, and spec deltas are internally consistent and reference the same capability boundaries.
- [x] 4.2 Run openspec validate improve-underground-diversity-and-ore-deposition --strict.
- [x] 4.3 Resolve all validation issues before implementation approval.