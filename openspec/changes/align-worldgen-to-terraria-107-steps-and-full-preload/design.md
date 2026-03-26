## Context
The project already uses staged world generation with critical/enrichment splitting and startup spawn-area warmup. However:
- Worldgen parity is currently defined at stage-family level rather than explicit 107-step compatibility indexing.
- Startup only guarantees local readiness around spawn, not full-world preload completion.
- Runtime exploration can still hit first-time generation work on unseen chunks.

The requested direction is stronger: emulate Terraria's 107-step terrain process as far as applicable, skip only unsupported/non-needed items with explicit rationale, and finish full preload before gameplay starts to maximize smooth exploration.

## Goals / Non-Goals
- Goals:
  - Define a deterministic 107-step compatibility model for terrain generation.
  - Add full-world preload gate before `PLAYING` in finite planetary mode.
  - Ensure preload completion removes first-time generation spikes for in-domain exploration.
  - Preserve deterministic seed behavior and chunk reproducibility.
- Non-Goals:
  - 1:1 implementation of every original Terraria internal function.
  - Expansion into non-terrain systems (combat, NPC social, UI redesign).
  - Forcing full preload in legacy infinite topology mode.

## Decisions
- Decision: Represent Terraria compatibility as an indexed `step catalog` with explicit disposition.
  - Each of 107 entries has: `step_index`, `step_name`, `status`, `mapped_family`, `execution_hook`, `skip_reason`, `compat_note`.
  - `status` values: `implemented`, `adapted`, `skipped`.
  - `skip_reason` is mandatory when status is `skipped`.

- Decision: Restrict allowed skip reasons to deterministic categories.
  - Allowed values:
    - `NOT_TERRAIN_SCOPE` (step is outside terrain generation capability)
    - `MISSING_PROJECT_SYSTEM` (required subsystem not present)
    - `MISSING_ASSET_SET` (required tile/content family absent)
    - `ENGINE_OR_TOPOLOGY_CONSTRAINT` (incompatible with current finite-wrap model)
  - Free-form skipping is disallowed.

- Decision: Introduce full-world preload in finite planetary mode as startup gate.
  - Before `PLAYING`, preload all chunks in configured preload domain and persist generated results.
  - Startup overlay remains active until preload completion.
  - If preload fails or times out, startup aborts to menu with structured failure reason.

- Decision: Keep legacy/infinite mode behavior compatible.
  - If topology is legacy/infinite, system falls back to current spawn-area warmup path.
  - Full-world preload is required only for finite planetary mode.

- Decision: Use deterministic bounded-batch preloading with resume support.
  - Preload executes chunk batches with per-frame budgets and telemetry.
  - Progress is persisted so interrupted sessions can resume from last checkpoint.
  - Completion state is tied to world topology identity and seed.

- Decision: Define preload readiness as "no first-time generation for in-domain chunks".
  - After preload complete, entering any preloaded chunk should load persisted data rather than trigger full generation pipeline.

## Trade-offs
- Longer startup time before first control handoff.
- Extra disk usage for preloaded chunk persistence.
- Additional complexity in preload checkpointing and version invalidation.
- Better runtime smoothness by shifting heavy cost to startup.

## Migration Plan
1. Add 107-step catalog and mapping governance (spec + metadata contracts).
2. Add full-world preload domain definitions for planetary presets.
3. Add preload orchestrator and completion checkpoint model.
4. Gate gameplay handoff on preload completion for planetary worlds.
5. Add telemetry and validation hooks for readiness and smoothness.
6. Keep legacy mode fallback unchanged.

## Validation Strategy
- Determinism:
  - Same seed and topology produce identical step disposition report and chunk outputs.
- Coverage:
  - Catalog contains 107 indexed entries with no missing indices.
- Skip governance:
  - Every skipped step has one allowed skip reason and compatibility note.
- Startup gate:
  - Planetary mode does not enter `PLAYING` before full preload completion.
- Smoothness:
  - Post-handoff traversal within preload domain does not trigger first-time generation work.
- Tooling:
  - `openspec validate align-worldgen-to-terraria-107-steps-and-full-preload --strict` passes.

## Open Questions
- No blocking ambiguity for proposal stage.
- Apply stage can tune preload domain vertical bounds and timeout defaults per preset.
