# Change: Align Worldgen to Terraria 107-Step Mapping and Full Pre-Start Preload

## Why
Current startup only warms a local spawn area (roughly nearby chunks) and then relies on runtime streaming for unseen regions. This does not satisfy the requested behavior: terrain generation should follow a full Terraria 107-step style model (skipping only inapplicable or unavailable items), and the game should complete full world preload before entering gameplay to maximize smoothness.

## What Changes
- Introduce a deterministic `107-step terrain mapping contract` for world generation:
  - Keep strict step order compatibility at index level.
  - Allow skipping only when a step is not needed for this project or is impossible due to missing systems/assets.
  - Require explicit skip reasons and compatibility substitutions.
- Add startup `full-world preload gate` for finite planetary worlds:
  - Gameplay handoff is blocked until all world chunks in configured preload bounds are generated and persisted.
  - Existing spawn-area warmup remains a fallback path for legacy/infinite mode.
- Add preload readiness/performance contracts:
  - Preload must run in deterministic bounded batches with progress telemetry and resumable state.
  - After preload completion, exploration must not trigger first-time generation spikes for in-domain chunks.
- Cross-link with existing staged worldgen and depth-boundary changes:
  - Reuse current staged-pass architecture and hard-floor boundary constraints.
  - Expand from local startup warmup to full-domain preload completion.

## Impact
- Affected specs:
  - `worldgen-terraria-107-step-parity`
  - `world-startup-full-world-preload`
  - `world-preload-performance-readiness`
- Related existing changes:
  - `update-worldgen-staged-passes-and-bedrock-floor`
  - `diagnose-world-streaming-stutter-root-causes`
  - `shift-worldgen-to-planetary-wraparound`
- Affected code (planned apply stage):
  - `src/systems/world/world_generator.gd`
  - `src/systems/world/infinite_chunk_manager.gd`
  - `src/core/game_manager.gd`
  - `src/systems/world/world_topology.gd`
  - preload metadata/storage integration paths under save/runtime systems

## Scope Notes
- This proposal targets terrain/worldgen behavior and startup gating only.
- It does not attempt to clone non-terrain Terraria systems.
- For legacy infinite mode, full-world preload is not required; finite planetary mode is the primary target for this capability.
