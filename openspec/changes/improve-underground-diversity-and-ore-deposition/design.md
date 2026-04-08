## Context
Underground generation currently mixes strong ideas (depth bands, cave region tags, staged worldgen) with weak enforceable outcomes. In play, simplified critical-path carving plus per-cell ore threshold replacement can produce repetitive stone fields and scattered ore dots.

The design goal is to preserve deterministic chunked generation and streaming safety while making underground traversal and mining outcomes clearly more varied and coherent.

## Goals
- Make underground regions feel structurally distinct across depth and macro regions.
- Guarantee periodic large-space cave opportunities and long-form underground route continuity.
- Make ore look geologic (cluster-first connected deposits) rather than uniformly speckled replacements.
- Keep deterministic regeneration and chunk-boundary continuity.
- Keep runtime smoothness by isolating heavy shaping to deferred phases.
- Preserve existing liquid behavior/contracts while improving cave and ore outcomes.
- Keep stratification at medium intensity (clear progression without harsh visual discontinuity).

## Confirmed Inputs
- Exploration priorities: regional zoning readability, large caverns, long connector routes, ore geology feel, and performance stability.
- Preferred ore shape: cluster-first.
- Early exploration: keep at least one forgiving descent near spawn-safe travel radius.
- Performance strategy: balanced.
- Save policy: old saves stay compatible; new rules apply to newly generated worlds/chunks.
- Must keep: liquid system.

## Non-Goals
- Full tileset or art-style overhaul.
- New combat, enemy, quest, or economy feature scope.
- Replacing persistence architecture or world topology mode.

## Decisions
- Decision: Introduce deterministic underground zoning layers (depth-band x macro-region x local field).
  - Rationale: Existing depth-only and biome mapping is not enough to enforce visible regional variation.

- Decision: Introduce cavern budgets and archetype families as explicit contracts.
  - Rationale: Named cave regions without budgeted large-space outcomes can still collapse into narrow repeated traversal.

- Decision: Move ore generation to deposit-first modeling.
  - Rationale: Sampling ore per cell is simple but tends to salt-and-pepper distribution; deposit seeds plus bounded growth enforce cluster coherence.

- Decision: Keep liquid contracts unchanged while upgrading underground and ore generation.
  - Rationale: Liquid behavior is a hard user constraint and must not regress under topology/deposit refactors.

- Decision: Use new-world/new-chunk effectiveness instead of forced old-world rewrite.
  - Rationale: Preserves compatibility and avoids risky migration churn for existing saves.

- Decision: Keep two-phase generation policy.
  - Rationale: Traversal-critical pass must remain lightweight; expensive shaping/decoration/deposit refinement should be deferred.

## Proposed Model (High Level)
1. Underground zoning field
- Deterministic zone id from depth band, macro-region, and low-frequency warped field.
- Zone id selects cave archetype mix, openness profile, and ore deposit family weights.

2. Cavern structure shaping
- Traversal-critical pass guarantees minimum navigable backbone and connector continuity.
- Enrichment pass applies large-cavern expansions and local shaping according to zone budgets.

3. Ore deposition
- Generate deposit seeds per chunk neighborhood using deterministic hashed coordinates.
- Expand seeds into connected ore bodies using constrained cluster-first growth rules (compact cores with bounded local variation).
- Apply replacement only where host material and depth/zone predicates match.

4. Validation metrics
- Underground diversity metrics: zone entropy, archetype distribution, large-cavern occurrence rate, route continuity, and reachability.
- Ore coherence metrics: connected-component size histogram, cross-chunk continuity, nearest-neighbor spacing, and depth profile alignment.

## Risks and Trade-Offs
- Risk: Overly strict budgets can produce artificial repetition.
  - Mitigation: Keep bounded stochastic variation within deterministic seeds.
- Risk: Deposit growth can increase generation cost.
  - Mitigation: Bound seed counts and growth steps; defer non-critical work.
- Risk: Backward visual mismatch with existing saves.
  - Mitigation: Keep delta persistence authoritative and avoid changing save format in this change.

## Migration Plan
- Proposal stage: define contracts and validation only.
- Apply stage: implement in world generator and manager passes behind feature-safe defaults.
- Verification: run deterministic seed suite, continuity checks, liquid-regression checks, and performance guardrails before rollout.

## Implementation Notes (Apply Stage)
- Implemented deterministic underground zone identity and macro-region composition in world generation metadata.
- Implemented budgeted large-cavern and long-route connector gating in cave region classification.
- Implemented spawn-safe early descent guarantee via deterministic gentle-mouth anchor in the outer spawn-safe ring.
- Replaced per-cell ore replacement in chunk resource stage with cluster-first deposit growth and connected-component diagnostics.
- Implemented depth-stratified underground material selection for default stone-family biomes, with layered transitions also applied to background walls for clearer underground layering readability.
- Increased ore availability by lowering deep/mid mineral thresholds and by raising cluster sampling density, cluster target size, and growth aggressiveness.
- Reduced planetary preset bedrock depths so deep-game exploration and terminal transition become reachable earlier in normal progression.
- Expanded deep cave variety by widening cave lane depth range, extending vertical connector depth eligibility, increasing large-cavern budget at deeper levels, and broadening long-route connector depth windows.
- Increased deep-strata variation by replacing fixed terminal single-material fallback with noise-driven multi-strata mixing in very deep layers.
- Added worldgen regression tests for underground diversity, spawn descent availability, ore connectedness, seam continuity, liquid seed preservation, and performance smoke budget.
- Added regression tests for underground material stratification visibility and deep-layer ore density floor.

### Code Mapping
- World generation core updates:
  - src/systems/world/world_generator.gd
- Validation updates:
  - tests/test_worldgen_bedrock_and_liquid.gd