# Change: Refine Liquid Flow Fidelity

## Why
Current liquid behavior drains quickly but lacks continuous water-like motion. Players perceive movement as discrete jumps instead of coherent flow, especially during cavity draining and lateral equalization.

## What Changes
- Define a fidelity-focused runtime liquid behavior contract that prioritizes continuity while preserving current throughput targets.
- Introduce a staged simulation strategy in design (micro-step transfer, adaptive fall pacing, local pressure equalization, and short-lived directional inertia).
- Add explicit performance and determinism guardrails so improved motion does not regress frame stability.
- Add acceptance and validation criteria for visual flow quality, solver convergence, and save/load consistency.

## Tech Stack
- Engine: Godot 4.5
- Language: Typed GDScript
- Runtime systems:
  - Active-cell queue based liquid solver in LiquidManager
  - Chunk persistence via WorldChunk and InfiniteChunkManager
  - Fractional overlay rendering via LiquidOverlay and TileMapLayer isolation
- Validation:
  - Headless scene script tests for worldgen and liquid contracts
  - Deterministic seed replay checks for convergence and persistence parity

## Impact
- Affected specs: liquid-flow-fidelity
- Affected code (planned):
  - src/systems/world/liquid_manager.gd
  - src/systems/world/infinite_chunk_manager.gd
  - src/systems/world/world_chunk.gd
  - docs/worldgen_staged_pipeline.md
- User-visible impact:
  - Water appears smoother, less step-like, and more physically plausible.
  - Save/reload must preserve liquid state exactly as observed before save.
