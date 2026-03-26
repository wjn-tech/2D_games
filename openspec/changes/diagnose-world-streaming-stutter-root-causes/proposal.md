# Change: Diagnose world streaming stutter root causes

## Why
Walking-time stutter is currently caused by multiple main-thread heavy paths executing in the same frame window. The current code shows synchronous chunk generation/apply, synchronous chunk save/unload writes, and synchronous autosave compression, which can stack into visible frame spikes.

## What Changes
- Define a runtime stutter diagnostics capability focused on chunk streaming paths and frame-budget breach attribution.
- Define a save pipeline hitch-control capability to prevent autosave/chunk-flush spikes from blocking gameplay.
- Establish explicit per-stage frame-budget contracts for critical chunk load, enrichment, unload cleanup, and entity instantiation.
- Establish acceptance criteria and validation workflow for stutter regression checks.

## Root Cause Evidence (Current Code)
- Main-thread chunk build and enrichment in `_process`:
  - `src/systems/world/infinite_chunk_manager.gd` (`_process`, `_build_chunk_on_main_thread`, `_build_chunk_enrichment_on_main_thread`).
- Dense world generation loops (64x64 per chunk, multi-noise cave logic):
  - `src/systems/world/world_generator.gd` (`generate_chunk_cells`).
- High-volume TileMap writes and full region clears:
  - `src/systems/world/infinite_chunk_manager.gd` (`_apply_cells_to_layers`, `_clear_chunk_region`).
- Synchronous scene load/instantiate in chunk entity paths:
  - `src/systems/world/infinite_chunk_manager.gd` (`_instantiate_entity`, `_spawn_npc_at`, `_spawn_chest_at`).
- Synchronous save and autosave write path (compressed + metadata + world deltas):
  - `src/core/save_manager.gd` (`_on_autosave_timeout`, `save_game`, `_write_atomic_compressed`).
  - `src/systems/world/infinite_chunk_manager.gd` (`save_all_deltas`, `_unload_chunk`).

## Impact
- Affected specs:
  - `world-streaming-performance` (new)
  - `save-pipeline-hitch-control` (new)
- Affected code (planned implementation stage):
  - `src/systems/world/infinite_chunk_manager.gd`
  - `src/systems/world/world_generator.gd`
  - `src/core/save_manager.gd`
  - `src/core/game_manager.gd` (only if startup/load gating needs budget-aware sequencing)
- User-visible outcome:
  - Reduced walking stutter during exploration and fewer periodic hitches from autosave/unload.
