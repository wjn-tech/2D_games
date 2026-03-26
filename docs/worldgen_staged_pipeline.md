# Worldgen Staged Pipeline

This document records the implemented Terraria-core stage family sequencing and compatibility adjustments.

## Stage Family Order
1. `foundation_and_relief`
2. `cave_and_tunnel`
3. `biome_macro`
4. `ore_and_resources`
5. `structures_and_micro_biomes`
6. `liquid_settle_and_cleanup`

## Critical vs Enrichment
- Critical stage output includes:
  - `foundation_and_relief`
  - `cave_and_tunnel`
  - `biome_macro`
- Enrichment stage output includes:
  - `ore_and_resources`
  - `structures_and_micro_biomes`
  - `liquid_settle_and_cleanup`

## Conflict Rule
- Default: later stage overrides earlier stage output.
- Whitelist preserve zones:
  - Spawn-safe corridor (`depth < 40` in spawn-safe columns)
  - Hard-floor zone (bedrock hard-floor depth and below)

## Compatibility Adjustments
- Cave carving is resealed progressively in bedrock transition depth to prevent deep runaway voids.
- Hard-floor depth enforces solid bedrock regardless of cave profile.
- Liquid phase-1 seeds are deterministic from noise gates and restricted by bedrock boundary.

## Liquid Behavior Notes (2026-03)
- Surface basin lakes now use horizontal patch seeding instead of vertical stack seeding.
- Cave water minimum seed count is depth-scaled (`min_water`: 2 -> 6 -> 8 by chunk depth bands) to avoid near-dry underground runs.
- Liquid simulation now blocks movement into solid world cells (tile layer 0), both vertical and lateral.
- Any legacy liquid cell that overlaps a newly solid tile is culled during simulation, preventing anti-physics "through-wall" flow artifacts.

## Runtime Liquid Refactor Notes (2026-03)
- Runtime solver moved from chunk round-robin polling to an active-cell queue model in `LiquidManager`.
- Each simulation step now wakes local neighbors (`up/down/left/right/self`) to propagate only dirty regions, reducing idle scans.
- Added quick-settle budget waves for post-ingest/post-edit convergence, inspired by Terraria-style settle passes.
- Chunk-load behavior now keeps empty loaded chunk containers in liquid runtime state, enabling cross-chunk inflow into previously dry chunks.
- Digging integration: `DiggingManager.tile_mined` now wakes nearby liquid cells and schedules short settle passes for immediate post-mine drainage.
- Flow rule tuning: gravity-first transfer remains dominant, and lateral spread is now gated by support under the source and target cells to prevent hanging shelves and staircase artifacts.
- Runtime cleanup/rendering: tiny residue below render threshold is no longer drawn to reduce visual speckles during settle.
- Digging guard: liquid render tiles on the background liquid layer are now excluded from mineable checks and blocked at execute-time, so water/lava cannot be removed via pickaxe.
- Digging layer policy: layers marked with `background_only` are now excluded from mineable detection and execution paths, so decorative/background walls cannot be mined by default.
- Flow realism tuning: per-step downward transfer is now capped to avoid instant full-cell drops after mining, while lateral equalization threshold/support checks were relaxed so pooled water spreads sideways earlier.
- Runtime settle pacing: quick-settle trigger passes were reduced for load/ingest/mine events to preserve visible progressive drainage instead of one-frame snap settling.
- Liquid render isolation: runtime liquids now render on a dedicated `LiquidRuntimeLayer` instead of reusing `layer_1`, preventing water/lava visuals from being painted into background wall tiles.
- Edge spill behavior: unsupported side targets can now receive limited spill when source head is high, improving side-flow continuity at ledges while keeping hanging shelves controlled.
- Visual enhancement: liquid rendering now supports amount-based atlas variant selection (high/mid/low fill) when matching tiles exist in the tileset, reducing single-tile repetition and improving perceived fluid depth.
- Simulation smoothness: per-frame runtime budget and active-cell step cap were increased to make local flow updates denser and motion more continuous.
- Fractional fill rendering fix: runtime liquid now uses a dedicated `LiquidOverlay` that draws per-cell fill height from `amount` (`0.0~1.0`), so half/quarter/sixteenth-cell water levels are shown directly instead of full-tile blocks.
- Mining compatibility fix: liquid-identification checks in `DiggingManager` are now layer-scoped to runtime liquid layer only, preventing ore tiles (e.g. copper at atlas `1,4`) from being misclassified as lava and becoming unmineable.
- Flow speed tuning: reduced per-step downward/lateral transfer and lowered per-frame solver budget to slow runtime drainage/spread and avoid fast "wash-through" behavior.
- Drip-style descent: downward transfer is now quantized to `1/16` cell units per step (`0.0625`), giving visible incremental falling instead of large chunk drops; lateral transfer is also quantized and slowed for a calmer spread.
- Gravity gating: added per-cell fall cooldown (`water: 90ms`, `lava: 150ms`) so unsupported liquid pauses briefly before each downward quantum step, producing Terraria-like staggered falling rather than instant continuous drops.
- Cooldown stability fix: cells blocked only by fall cooldown are now re-enqueued so they resume falling after delay instead of stalling mid-air.
- Merge continuity fix: downward transfer into same-type liquid below now allows sub-quantum merging near capacity, preventing separated water columns that fail to combine.
- Falling packet model: downward transfer now detaches a quantized liquid packet from the source cell, animates it through air (`water: 120ms`, `lava: 180ms`), and deposits it on arrival; this creates visible droplet-like downward motion instead of simultaneous top/bottom interpolation.
- Lateral spill continuity fix: reduced support thresholds and added a minimum side-flow quantum floor for ledge spill, preventing side transfer from being quantized to zero at low per-step budgets.
- Vertical cascade fix: when a cell cannot fall only because downstream capacity is temporarily full, it is immediately re-enqueued (and nudges the above cell) so stacked water columns can cascade in the same time window instead of strict one-layer serialization.
- Packet robustness fix: falling packets now validate destination chunk writability before deposit (otherwise they are returned to source), and inflight flags are rebuilt from active packets each frame to prevent stale lock states that can stop flow.
- Scheduler fairness fix: active liquid processing switched from LIFO stack pop to FIFO queue pop, and downstream-capacity retries now prioritize waking the below cell; this prevents local requeue starvation that can freeze apparent flow.
- Surface lake fill fix: basin water seeding now fills each basin column up to ~2/3 of depth-from-surface instead of a single bottom row, and surface-basin seed budget is raised to avoid underfilled lakes.
- Surface lake cavity fix: basin candidates now pre-carve a shallow bowl cavity before seeding water, ensuring worldgen reserves physical space for lakes rather than relying on accidental empty cells.
- Water contact-tile cleanup: water no longer rewrites neighboring terrain into liquid-contact atlas tiles during seeding, removing stray deep-blue artifact blocks around lakes.
- Lake continuity fix: downward transfer into same-type liquid now commits directly to the destination cell (without packet detachment), preventing persistent void gaps inside lake bodies.
- Side-fill granularity fix: lateral transfer quantum reduced (`1/64`) to improve low-volume equalization and reduce checker/void artifacts in shallow lake regions.
- Temporal-detail tuning: downward packet quantum is refined from `1/16` to `1/32`, while per-step delay and packet travel durations are reduced proportionally (water `90/120ms` -> `45/60ms`, lava `150/180ms` -> `75/90ms`) so motion appears finer without stretching total fall completion time.

## Dual Acceptance Metrics
- `core_stage_coverage_rate`: threshold `>= 0.95`
- `step_item_coverage_rate`: threshold `>= 0.80`
- Current implementation reports both metrics from `WorldGenerator.get_stage_alignment_metrics()`.
