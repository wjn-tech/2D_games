## Context
The project already has chunk streaming, deterministic generation, and cave region tags, but the player-facing loop still lacks reliable natural entry cues and strong deep-cavern identity. Any upgrade must also respect runtime smoothness: players should be able to keep walking without visible loading stalls.

## Goals / Non-Goals
- Goals:
  - Make cave entrances discoverable from normal surface traversal.
  - Make deeper underground feel broader, layered, and more distinct.
  - Preserve deterministic generation and wrapped-world compatibility.
  - Enforce generation workload limits that protect movement smoothness.
- Non-Goals:
  - No full combat redesign.
  - No mandatory full tileset overhaul.
  - No rewrite of save/delta architecture.

## Decisions
- Decision: Use a staged cave workflow rather than a single carve rule.
  - Stage A: terrain-relief and entrance-anchor discovery.
  - Stage B: traversal-critical carve (fast path).
  - Stage C: deep-space widening, archetype shaping, and enrichment.
  - Why: keeps startup and walking-time chunk loads responsive while still enabling richer cave structure.

- Decision: Introduce entrance families with deterministic spacing budgets.
  - Families include cave mouth, ravine cut, sinkhole, cliff slit, and funnel-like descent (or equivalent).
  - Why: players should regularly see meaningful descent opportunities without turning the surface into continuous holes.

- Decision: Define deep-cavern identity through depth bands plus shaped archetypes.
  - Depth bands control openness, connector frequency, and hazard/resource bias.
  - Archetypes include large chambers, horizontal galleries, compartment clusters, and rare connector corridors.
  - Why: depth progression should feel like entering different underground zones, not one repeated cave texture.

- Decision: Add long-form connector routes as first-class outputs.
  - At least one route family should connect multiple major cave spaces for orientation and sustained traversal.
  - Why: long connectors improve exploration flow and reduce repetitive vertical re-entry behavior.

- Decision: Enforce streaming-safe generation budgets.
  - Critical chunk generation must complete within bounded per-frame work.
  - Enrichment is deferred and chunk-safe.
  - Why: cave quality cannot come at the cost of movement hitching.

## Risks / Trade-offs
- Richer cave geometry can increase per-chunk workload.
  - Mitigation: strict split between critical path and deferred enrichment, with measurable budgets.
- More entrance families can accidentally over-fragment the surface.
  - Mitigation: deterministic spacing, per-region caps, and spawn-safe constraints.
- Reusing existing tiles may reduce visual novelty.
  - Mitigation: rely on geometry, scale, openness, and sparse accent assets for readability.

## Migration Plan
1. Add new metadata contracts for entrance family and deep-cavern archetype tags.
2. Keep existing cave tags queryable; expose additive fields for new systems.
3. Roll out staged generation path behind deterministic checks.
4. Validate representative seeds for entrance density, deep-cavern readability, and runtime smoothness.

## Open Questions
- Should world-size preset influence entrance spacing and long-route frequency linearly, or with per-preset hand-tuned curves?
- Do we want one global long-route budget per world, or independent budgets per macro region?
