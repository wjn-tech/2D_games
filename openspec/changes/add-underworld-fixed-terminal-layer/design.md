## Context
The project already defines underground depth bands, cave archetypes, and bedrock boundaries, but deep exploration still depends on distributed stochastic outcomes. The requested experience is a guaranteed large underworld destination near bedrock that behaves like an underground surface.

## Goals / Non-Goals
- Goals:
  - Guarantee one world-scale fixed underworld layer per new world.
  - Place the layer tightly above bedrock transition while allowing controlled overlap/intrusion.
  - Make the layer visually and navigationally distinct: giant open space plus cliffs and suspended islands.
  - Guarantee at least one natural primary route from mid-cavern.
  - Raise ore abundance by 30% in underworld-adjacent regions.
- Non-Goals:
  - No retroactive full rewrite of existing saves.
  - No requirement to add brand-new tile assets in this proposal.
  - No combat/content-system expansion in this change.

## Key Decisions
- Decision: Create independent capability `underworld-generation`.
  - Rationale: This layer has unique generation, access, and resource contracts that are clearer as a standalone capability.

- Decision: Single deterministic underworld mega-space per world.
  - Rationale: User selected fixed world landmark behavior rather than multi-region random occurrences.

- Decision: Anchor above bedrock transition with controlled intrusion.
  - Rationale: Keeps progression consistent with terminal depth expectations while allowing dramatic boundary shape.

- Decision: Near full-circumference horizontal extent and >=180 vertical span.
  - Rationale: Required to read as an underground surface rather than a local chamber.

- Decision: Aggressive morphology profile.
  - Rationale: User selected high-contrast terrain identity over conservative continuity.

- Decision: One guaranteed natural primary path from mid-cavern.
  - Rationale: Ensures discoverability without forcing manual deep shafts.

- Decision: +30% ore density in neighboring depth bands and edge zones.
  - Rationale: Makes terminal expedition materially rewarding and distinct.

- Decision: Legacy metadata backfill without forced chunk rewrite.
  - Rationale: Preserves old-save compatibility while making underworld reachable in active worlds by normalizing missing metadata.

## Architecture Notes
1. Placement model
- Use topology metadata to derive deterministic underworld anchor band near bedrock transition start.
- Derive world-scale span and local shape fields from seed and wrapped X coordinates.

2. Geometry model
- Generate one dominant open cavity floor/ceiling envelope.
- Carve major escarpments and terraces.
- Add deterministic suspended island clusters with bounded density.

3. Access model
- Reserve at least one deterministic trunk route from mid-cavern connector families to underworld envelope.
- Validate route continuity across chunk seams.

4. Resource model
- Apply +30% ore-density multiplier in configured adjacency windows (above, inside edge, and immediate flanks).
- Keep mineral type affinity rules deterministic and depth-aware.

## Risks / Trade-offs
- Risk: Large fixed cavity can reduce biome diversity if too dominant.
  - Mitigation: Keep shape warping and island distribution high-frequency but deterministic.
- Risk: Performance spikes from world-scale geometry shaping.
  - Mitigation: Keep traversal-critical carving bounded and defer decorative enrichment.
- Risk: Bedrock intrusion can break sealing assumptions.
  - Mitigation: Define explicit max intrusion depth and keep hard-floor safety invariants.

## Validation Plan
- Determinism checks for anchor location and geometry identity per seed.
- Coverage checks for width and vertical span contracts.
- Connectivity checks for guaranteed primary route from mid-cavern.
- Ore-density checks for +30% adjacency uplift.
- Streaming and seam continuity checks in wrapped planetary topology.

## Implementation Notes (Apply Stage)
- Added underworld metadata markers and query contract in topology metadata:
  - `underworld_layer_enabled`, `underworld_layer_revision`
  - `underworld_anchor_chunk`, `underworld_primary_route_chunk`
  - `underworld_horizontal_coverage_ratio`, `underworld_min_vertical_span`, `underworld_ore_uplift_multiplier`
- Added underworld placement normalization (revision v2):
  - spawn-side anchor as default underworld centerline
  - full-circumference coverage ratio (`1.0`) for no-gap terminal reachability
  - legacy metadata backfill for missing underworld fields without forced chunk rewrite
- Added topology API for consumers:
  - `is_underworld_layer_enabled()`
  - `get_underworld_generation_config()`
- Added deterministic underworld geometry in world generation:
  - world-scale near-full-circumference envelope
  - minimum vertical span contract
  - controlled bedrock-transition intrusion with hard-floor preservation
  - aggressive morphology: cavity, cliffs, suspended islands
  - deterministic primary route from mid-cavern depth window
- Added underworld-aware metadata exposure in underground tile query path.
- Added underworld-adjacent ore uplift integration (+30%) in ore cluster generation path and diagnostics.
- Added regression tests for:
  - legacy metadata backfill activation
  - fixed-layer scale/placement invariants
  - primary route continuity
  - seam continuity
  - ore uplift behavior
  - traversal-critical generation performance smoke

### Code Mapping
- Topology and metadata:
  - src/systems/world/world_topology.gd
- Underworld geometry and ore uplift integration:
  - src/systems/world/world_generator.gd
- Regression coverage:
  - tests/test_worldgen_bedrock_and_liquid.gd
