# Change: Refactor Precomputed Cache Lifecycle and Storage Footprint

## Why
The current world preload artifact strategy stores large per-chunk precomputed payloads under a global cache root and does not guarantee lifecycle cleanup when worlds are abandoned. This causes uncontrolled disk growth (multi-GB on C:), weak ownership boundaries between saves and caches, and poor long-term operability.

## What Changes
- Reclassify world persistence into authoritative save data vs disposable regeneration cache:
  - Authoritative: player/world deltas that MUST survive.
  - Disposable: seed-derivable precomputed artifacts that MAY be deleted at any time.
- Introduce explicit cache lifecycle governance for precomputed artifacts:
  - Global and per-world disk budget caps.
  - LRU and stale-world eviction policy.
  - Deterministic invalidation on identity/schema mismatch.
- Introduce compact storage contract for precomputed artifacts:
  - Use compressed containerized payload format instead of unbounded raw per-chunk dictionary serialization.
  - Preserve deterministic reconstruction and runtime load path compatibility.
- Add operational observability for disk footprint:
  - Expose per-tier size accounting (authoritative save vs precompute cache) and eviction events.

## Impact
- Affected specs:
  - `world-precomputed-cache-management`
  - `world-storage-footprint-control`
- Affected code (apply stage):
  - `src/systems/world/infinite_chunk_manager.gd`
  - `src/systems/world/world_topology.gd`
  - `src/core/save_manager.gd`
  - `src/core/game_manager.gd`
  - Optional support scripts for migration/cleanup telemetry

## Scope Notes
- This proposal is a storage/governance optimization and does not change gameplay rules.
- This proposal does not remove deterministic seed-based world generation.
- This proposal does not require code implementation in proposal stage; implementation occurs after approval.