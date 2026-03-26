## Context
Current frame hitches align with world streaming and save pipeline synchronization points.

Observed hotspot chain:
1. `Player._physics_process` periodically calls `InfiniteChunkManager.update_player_vicinity`.
2. `InfiniteChunkManager._process` consumes pending queues and performs chunk build/enrichment on main thread.
3. Chunk build invokes `WorldGenerator.generate_chunk_cells` (noise-heavy 64x64 loops), then `_apply_cells_to_layers` (large `set_cell` batches), and may instantiate entities.
4. Unload/save paths can synchronously write chunk deltas and autosave data in gameplay time.

## Goals / Non-Goals
- Goals:
  - Make stutter root causes attributable with deterministic telemetry.
  - Enforce per-frame streaming budgets across load/enrichment/unload/entity stages.
  - Remove periodic save hitches from gameplay-critical frames.
- Non-Goals:
  - Rewriting world generation algorithms in this change.
  - Altering biome/cave gameplay outcomes.
  - Introducing networking or external profiling services.

## Decisions
- Decision: Add operation-level timing and workload counters.
  - Why: Existing warnings only cover chunk build and enrichment duration, but do not attribute `set_cell`, instantiation count, unload save cost, or autosave write stages.
  - Alternatives considered:
    - Rely only on Godot Profiler manually: rejected because it is hard to regress-check in CI/automation.

- Decision: Split streaming into strict frame-budget stages with backpressure.
  - Why: Single-frame accumulation from critical load + enrichment + unload cleanup causes frame spikes.
  - Alternatives considered:
    - Increase budgets: rejected because it shifts spikes rather than eliminating them.

- Decision: Convert save flush to hitch-safe pipeline contract.
  - Why: `save_all_deltas` and autosave compression are synchronous and can overlap with movement-time streaming.
  - Alternatives considered:
    - Disable autosave: rejected due to data safety regression.

- Decision: Define measurable acceptance thresholds (P95/P99) for walking in generated terrain.
  - Why: Prevent future regressions from hidden work moving back to hot paths.

## Risks / Trade-offs
- Additional instrumentation has minor runtime overhead.
  - Mitigation: Keep telemetry sampling configurable and lightweight in non-debug builds.
- Deferred save behavior may increase data-loss window on sudden crash.
  - Mitigation: keep bounded flush interval and force flush on explicit save/quit.
- Aggressive budget slicing may cause visible late-pop-in.
  - Mitigation: preserve critical-path guarantees (walkable collision first, enrichment later).

## Validation Plan
- Runtime validation scenario: continuous walking across chunk boundaries for fixed duration with stable seed.
- Metrics to capture:
  - frame-time P50/P95/P99
  - per-stage ms (critical load, enrichment, apply cells, entity spawn, unload save, autosave write)
  - queue backlog depth over time
- Pass criteria:
  - No periodic hitch cluster aligned with autosave interval.
  - Budget breaches are observable and attributable with chunk/stage tags.

## Open Questions
- Should unload persistence be fully deferred, or partially deferred with emergency synchronous fallback near memory limits?
- What minimum hardware profile should define the acceptance threshold baseline?
