## Context
The project already uses an active-cell queue liquid solver with chunk-scoped persistence and fractional overlay rendering. Recent tuning increased apparent speed but reduced fluid realism: motion appears quantized, direction changes are abrupt, and equalization lacks pressure-like continuity.

## Goals
- Improve water-like continuity without reducing overall gameplay responsiveness.
- Preserve deterministic and chunk-friendly simulation suitable for infinite streaming.
- Keep save/load liquid state parity intact across loaded and unloaded chunks.
- Maintain frame stability under normal exploration and local terrain edits.

## Non-Goals
- Replacing the authoritative grid solver with full particle or rigid-body fluids.
- Rewriting world generation topology or chunk storage format.
- Introducing multiplayer synchronization in this change.

## Technical Stack
- Godot 4.5 runtime
- Typed GDScript systems
- Core modules:
  - LiquidManager for active-cell simulation and overlay data
  - InfiniteChunkManager for chunk lifecycle and persistence flush orchestration
  - WorldChunk as serialized chunk state carrier
- Rendering path:
  - LiquidRuntimeLayer for isolation from background wall tiles
  - LiquidOverlay for fractional fill and packet visuals

## Decisions
- Decision: Keep the active-cell queue architecture and refine transfer policy.
  - Why: Existing model is performant and chunk-compatible; realism issues are mostly pacing and transfer granularity.
- Decision: Introduce bounded local pressure equalization in active neighborhoods.
  - Why: Improves lateral surface smoothness and reduces staircase liquid fronts.
- Decision: Add short-lived directional inertia per active cell.
  - Why: Prevents frame-to-frame flip-flop and improves perceived continuity.
- Decision: Preserve strict simulation budgets with explicit fallback.
  - Why: Prevents visual fidelity improvements from creating frame spikes.

## Alternatives Considered
- Full SPH/particle simulation:
  - Rejected due to high CPU cost, non-trivial persistence, and mismatch with chunked authoritative storage.
- Pure visual smoothing only:
  - Rejected because the current issue is physical continuity, not just rendering.
- Global whole-world relaxation passes:
  - Rejected due to poor scalability with streaming world chunks.

## Risks and Trade-offs
- Risk: More micro-steps can increase CPU use.
  - Mitigation: Hard per-frame limits and dynamic settle throttling.
- Risk: Inertia may cause overshoot or delayed equalization.
  - Mitigation: Use short decay windows and cap directional bias.
- Risk: New pacing may alter legacy level timing.
  - Mitigation: Keep throughput targets and expose tuning constants with compatibility defaults.

## Validation Plan
- Functional:
  - Cavity drain should look continuous for several sub-steps, not binary jumps.
  - Connected pools should equalize with reduced checkerboard artifacts.
- Persistence:
  - Save/reload must reproduce pre-save liquid distribution, including chunks with initialized-but-empty liquid state.
- Performance:
  - Frame-time budget in liquid-heavy scenes must stay within configured limits.

## Rollout Plan
1. Introduce fidelity controls with compatibility defaults.
2. Enable continuity tuning for limited scenarios and run deterministic replay checks.
3. Raise defaults after automated and manual acceptance thresholds pass.
4. Keep rollback path by reverting to compatibility tuning profile.

## Implementation Notes (2026-03-28)
- Implemented in `src/systems/world/liquid_manager.gd`:
  - Added water-only open-fall hysteresis state (`_open_fall_mode_until_ms`) and decision helper `_should_use_open_fall_stream(...)` to reduce direct-fall/packet mode flicker.
  - Added bounded water-only lateral split gain helper `_apply_water_lateral_split_gain(...)` with strict source/capacity caps (`WATER_LATERAL_SPLIT_GAIN=1.01`).
  - Extended open-column probe tolerance for near-source tiny thin films (`WATER_OPEN_FALL_THIN_FILM_EPS`) to improve boundary continuity without enabling unsupported shelves.
  - Ensured new hysteresis state is cleared in runtime reset and chunk-prune lifecycle paths.
  - Tuned open-fall vertical priority toward natural motion by keeping a visible downward slice floor, shorter (but not extreme) water-only cooldown cap, and moderate lateral damping while open-fall is active.
  - Updated overlay rendering for low-volume vertically-linked water cells from narrow ribbon style to blended full-width stream-sheet presentation to avoid artificial texture-like columns.
  - Extended bubble collapse rules to include top-bottom enclosed seam voids (without requiring lateral support), using conservative vertical-neighbor donor transfer to preserve mass.
  - Removed downward quantization dead-zone by adding a bounded micro-trickle fallback for sub-quantum downward flow and retry scheduling when downward capacity exists.
  - Reduced stream-sheet lip inset to avoid visual pseudo-gaps that looked like bubbles under thin surface films.
  - Removed cooldown busy-requeue thrash by introducing a bounded cooldown-ready scheduler that scans `_fall_next_ms` and enqueues only cells whose timers have elapsed.
  - Added debug metric `cooldown_cells` for observing cooldown queue pressure in runtime diagnostics.
  - Extended seam-bubble collapse with bounded deep vertical endpoint probing (`VERTICAL_SEAM_MAX_GAP`) so seam cells can bridge upper/lower pools even when immediate bottom/top neighbors are still empty.
  - Increased seam bridge transfer (`VERTICAL_SEAM_TRANSFER`) to keep collapse-generated seam cells above overlay visibility threshold, preventing hidden-connector visual bubbles and apparent floating slabs.
  - Fixed deep probe early-fail path: `_probe_vertical_seam_endpoint(...)` now continues scanning when it encounters same-type thin intermediate films below seam threshold, instead of returning failure before reaching deeper stable endpoints.
  - Aligned vertical seam bridge minimum neighbor threshold with render visibility (`VERTICAL_SEAM_MIN_NEIGHBOR_AMOUNT := RENDER_EPSILON`) so visible thin caps remain eligible for bridge formation.
  - Updated seam-collapse candidate gating: same-type underfilled candidates (amount below seam threshold) are no longer skipped as non-empty; bridge transfer now tops up existing amount with capacity clamp.
  - Runtime rollback note: `_process(...)` now bypasses post-simulation repair passes (static hole fill, fast relax, local pressure equalization, bubble collapse) and executes only core active-cell simulation with packet settlement and cooldown-ready scheduling.
  - Core-loop anti-sleep guard: downstream-capacity wait now keeps downstream-priority wakeup and adds delayed source-cell self-retry scheduling (`_schedule_delayed_retry`, `DOWNSTREAM_WAIT_RETRY_MS`) to prevent potential-flow sources from leaving the active path permanently.
  - Vertical-only wait guard: when `fall_waiting_for_downstream` is active, `_simulate_active_cell(...)` suppresses same-tick lateral spread/edge-spill from the source so bottom-drain transitions do not produce uphill-looking side growth.
- Regression coverage added in `tests/test_worldgen_bedrock_and_liquid.gd`:
  - `_test_liquid_open_fall_hysteresis_window`
  - `_test_liquid_open_fall_vertical_priority`
  - `_test_liquid_open_fall_short_cooldown_cap`
  - `_test_liquid_vertical_seam_bubble_collapse`
  - `_test_liquid_downward_micro_trickle_no_deadzone`
  - `_test_liquid_cooldown_ready_scheduler`
  - `_test_liquid_downstream_wait_schedules_self_retry`
  - downstream-wait test now also asserts no side cells are created during the wait tick
  - `_test_liquid_multi_cell_vertical_gap_collapse`
  - `_test_liquid_vertical_seam_probe_through_thin_intermediate`
  - `_test_liquid_vertical_seam_visible_thin_cap_bridge`
  - `_test_liquid_vertical_seam_underfilled_candidate_topup`
  - `_test_liquid_water_split_gain_guardrail`
  - `_test_liquid_clear_epsilon_threshold`
- Runtime notes updated in `docs/worldgen_staged_pipeline.md` under Runtime Liquid Refactor Notes.
