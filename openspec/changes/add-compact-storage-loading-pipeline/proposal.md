# Change: Add Compact Storage Loading Pipeline

## Why
The project is introducing a new compact storage strategy for world precomputed artifacts, but the runtime load path is still coupled to legacy per-chunk file assumptions. Without an explicit loading pipeline contract, migration risk is high: startup regressions, cache miss storms, or blocking fallbacks can negate storage optimization goals.

## What Changes
- Define a dedicated loading pipeline for the new compact precompute storage format.
- Define deterministic load fallback order:
  - primary: compact storage artifact
  - secondary: legacy precomputed artifact compatibility reader
  - tertiary: deterministic regeneration from seed + authoritative deltas
- Define integrity and corruption handling:
  - version/schema checks
  - payload decode validation
  - quarantine + fallback instead of crash/block
- Define startup/load-time behavior constraints:
  - bounded load budget
  - progress telemetry
  - no gameplay-state corruption when cache tier fails

## Impact
- Affected specs:
  - `world-compact-storage-loading`
- Related changes:
  - `refactor-precomputed-cache-lifecycle-and-storage`
  - `align-worldgen-to-terraria-107-steps-and-full-preload`
- Affected code (apply stage):
  - `src/systems/world/infinite_chunk_manager.gd`
  - `src/systems/world/world_topology.gd`
  - `src/core/game_manager.gd`
  - optional storage index utilities under `src/systems/world/`

## Scope Notes
- Proposal stage only defines design/requirements; no implementation changes.
- This change focuses on load-path behavior and compatibility, not storage writer format details.
- Authoritative save semantics are unchanged.