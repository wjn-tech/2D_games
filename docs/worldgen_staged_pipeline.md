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
- Vertical cascade fix: when a cell cannot fall because downstream capacity is temporarily full, runtime now prioritizes waking the below cell and schedules a delayed self-retry for the source cell, preventing busy immediate requeue while avoiding source-cell sleep starvation.
- Vertical-priority guard: while a source cell is in downstream-capacity wait, lateral spread/edge-spill from that source is suppressed for the tick, preventing uphill-looking side growth during bottom-drain events.
- Packet robustness fix: falling packets now validate destination chunk writability before deposit (otherwise they are returned to source), and inflight flags are rebuilt from active packets each frame to prevent stale lock states that can stop flow.
- Scheduler fairness fix: active liquid processing switched from LIFO stack pop to FIFO queue pop, and downstream-capacity retries now prioritize waking the below cell; this prevents local requeue starvation that can freeze apparent flow.
- Surface lake fill fix: basin water seeding now fills each basin column up to ~2/3 of depth-from-surface instead of a single bottom row, and surface-basin seed budget is raised to avoid underfilled lakes.
- Surface lake cavity fix: basin candidates now pre-carve a shallow bowl cavity before seeding water, ensuring worldgen reserves physical space for lakes rather than relying on accidental empty cells.
- Water contact-tile cleanup: water no longer rewrites neighboring terrain into liquid-contact atlas tiles during seeding, removing stray deep-blue artifact blocks around lakes.
- Lake continuity fix: downward transfer into same-type liquid now commits directly to the destination cell (without packet detachment), preventing persistent void gaps inside lake bodies.
- Side-fill granularity fix: lateral transfer quantum reduced (`1/64`) to improve low-volume equalization and reduce checker/void artifacts in shallow lake regions.
- Temporal-detail tuning: downward packet quantum is refined from `1/16` to `1/32`, while per-step delay and packet travel durations are reduced proportionally (water `90/120ms` -> `45/60ms`, lava `150/180ms` -> `75/90ms`) so motion appears finer without stretching total fall completion time.
- Worldgen pre-settle fix: chunk ingest now runs bounded immediate settle passes before first render, so newly generated water/lava appears near equilibrium at load time instead of requiring long runtime convergence.
- Persistence parity fix: chunk liquid persistence now has an explicit `liquid_state_initialized` marker; once initialized, even empty liquid states are treated as meaningful save data and will not be replaced by regenerated `_liquid_seeds` on reload.
- Save-time runtime sync: `InfiniteChunkManager.save_all_deltas()` now asks `LiquidManager` to flush in-memory runtime liquid state back into `WorldChunk.liquid_cells` before dirty-write scheduling, ensuring manual saves capture current liquid state even when chunks are still loaded.
- Unload persistence ordering fix: chunk unload now syncs runtime liquid into the loaded `WorldChunk` before persistable-change checks, and liquid-touched loaded chunks are auto-registered into `world_delta_data` so liquid-only edits are not dropped.
- Flow-fidelity continuity: transfer quanta are refined (`down: 1/16 -> 1/32`, `side: 1/32 -> 1/64`) and per-frame active-step budget is increased (`56 -> 88`) so motion remains smooth while maintaining aggregate throughput.
- Adaptive falling cadence: fall cooldown now scales with transferred amount and local head difference, reducing binary start-stop behavior and improving continuous cavity draining.
- Direction stability and pressure pass: near-equal lateral decisions now keep a short-lived remembered direction, and idle frames run a bounded local pressure equalization pass to reduce checkerboard/staircase fronts without whole-world sweeps.
- Steady-state bubble fix: lateral target capacity now converges to full-cell (`1.0`), pressure equalization adds micro-gap transfer for near-equilibrium (`1.00 vs 0.96`) deadzones, and static hole fill now transfers from neighboring donor cells (mass-conservative) instead of creating liquid.
- Bubble cleanup extension: idle pressure equalization can now transfer into supported empty side cells, allowing enclosed interior voids to be rehydrated without enabling unsupported lateral shelf spread.
- One-layer bubble collapse: idle phase now runs a bounded enclosed-bubble pass that fills single-cell interior voids (top/bottom enclosed and 3-neighbor support) via neighbor transfer, preserving mass and preventing persistent mid-body slit bubbles.
- Active bubble cleanup: when liquid is still flowing, a smaller per-frame bubble-collapse budget also runs so one-cell gaps are corrected without waiting for full idle.
- Waterfall continuity: water now prefers direct open-column falling (when the next two cells are open) instead of relying on packet-only descent, producing a more Terraria-like continuous waterfall column.
- Waterfall anti-flicker (water-only): open-column direct-fall mode now keeps a short hysteresis window and tolerates tiny near-source thin-film amounts, reducing packet/direct mode flip-flop in borderline cavities.
- Water split tuning (water-only): lateral transfer keeps a strict bounded +1% gain (`WATER_LATERAL_SPLIT_GAIN=1.01`) after quantization, capped by source amount and target capacity to avoid runaway growth.
- Tail cleanup guardrail: `CELL_CLEAR_EPSILON` behavior is now regression-covered to ensure tiny residual amounts are culled while just-above-threshold liquid remains persisted.
- Waterfall vertical-priority tuning (water-only): open-column mode keeps a visible downward slice floor and shorter cooldown while still allowing moderate lateral bleed, producing less rigid pillar behavior.
- Waterfall visual continuity: low-volume vertically-connected water cells now render as a full-width stream sheet with top-lip blending (instead of fixed narrow ribbons), reducing artificial "overlay texture" appearance.
- Seam-void bubble fix: bubble collapse now explicitly patches top-bottom enclosed vertical seam voids (even when left/right support is missing), removing persistent one-tile horizontal cavity lines inside large water bodies while preserving mass.
- Root-cause dead-zone fix: downward transfer no longer hard-stalls for sub-quantum films when open-fall is not active; a bounded micro-trickle path keeps thin water layers draining instead of suspending and leaving persistent air pockets.
- Stream-lip artifact reduction: stream-sheet top lip inset was reduced to avoid rendering a fake dark gap beneath thin surface films.
- Performance root-cause fix: cells blocked by fall cooldown are no longer re-enqueued every frame; a cooldown-ready scheduler now activates them only when their timer elapses, reducing active-queue thrash and frame spikes in heavy waterfall scenes.
- Multi-cell seam-collapse fix: vertical seam bubble collapse now probes deeper vertical endpoints (bounded depth) instead of immediate neighbors only, so stacked air gaps between upper/lower pools collapse progressively rather than leaving apparent floating slabs.
- Seam visibility guard: per-collapse vertical transfer was increased so bridge cells cross render visibility threshold, reducing "hidden connector" cases that looked like persistent bubbles or suspended liquid layers.
- Deep-probe continuity fix: vertical seam endpoint probing now continues past same-type thin intermediate films instead of early-failing, so deeper stable endpoints can still be discovered and multi-row air gaps no longer persist under thin films.
- Seam-threshold parity fix: vertical seam bridge minimum neighbor amount is now aligned with overlay visibility threshold (`RENDER_EPSILON`), so visible thin caps can still bridge with lower pools and no longer appear as suspended slabs above bubble rows.
- Underfilled-seam candidate fix: seam collapse no longer skips same-type underfilled candidate cells (above clear epsilon but below seam threshold); these cells are now topped up as bridge cells, removing persistent algorithmic gap rows.
- Core-logic runtime rollback: post-simulation repair passes (static hole fill, fast relax, pressure equalization, bubble collapse) are temporarily disabled in `_process`; runtime now relies on core gravity-first active-cell simulation, lateral spread, packet settlement, and cooldown-ready scheduling only.
- Porting parity cleanup (2026-03-30): legacy post-simulation repair passes and related constants are removed from `LiquidManager`; runtime behavior is now exclusively defined by `_simulate_active_cell` core flow path and scheduler.
- No upward insertion contract (2026-03-30): all historical upward candidate fill paths are removed, and regression tests now assert that runtime never creates new liquid cells above the source layer.
- Bottom-anchor rendering contract (2026-03-30): liquid overlay now computes bottom-anchored fill metrics for every cell with assertions, and thin-film rendering keeps the same bottom-attached invariant to avoid same-cell floating artifacts.

## Liquid Fidelity Rollout Checklist (2026-03)
- Keep throughput parity by tuning `MAX_ACTIVE_STEPS_PER_FRAME` and `SIMULATION_BUDGET_MS` together; avoid raising one without the other.
- Keep realism knobs aligned: `DOWN_FLOW_QUANTUM`, `SIDE_FLOW_QUANTUM`, `MAX_DOWN_FLOW_PER_STEP`, `MAX_SIDE_FLOW_PER_STEP`.
- Validate persistence parity after any tuning change: save while loaded, unload/reload, and initialized-empty chunk paths.
- If frame-time spikes occur, first reduce `PRESSURE_EQUALIZATION_BUDGET`; second reduce `MAX_ACTIVE_STEPS_PER_FRAME`; keep quanta unchanged unless visual continuity regresses.

## Dual Acceptance Metrics
- `core_stage_coverage_rate`: threshold `>= 0.95`
- `step_item_coverage_rate`: threshold `>= 0.80`
- Current implementation reports both metrics from `WorldGenerator.get_stage_alignment_metrics()`.
