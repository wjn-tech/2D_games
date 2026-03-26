# Change: Enhance Natural Cave Entrances and Deep Caverns

## Why
Players want underground exploration to feel like discovering a real world, not digging straight down into repetitive noise pockets. The current generation already has cave tags and basic reachability, but practical experience still shows three gaps:

- Natural surface-to-underground entrances are too rare or too similar, so exploration often collapses into manual vertical digging.
- Deep underground spaces are not consistently broad, layered, and memorable across long traversal distance.
- Streaming-time cave generation can still create hitch risk if we increase complexity without strict workload budgets.

External Terraria references reinforce this direction:
- `World generation` documents a staged pass model (surface caves, mountain caves, large cavern caves, mini-biomes, cleanup) rather than one monolithic carve pass.
- `Biomes`, `Underground`, and `Cavern` emphasize layered underground identity plus shaped sub-regions (Underground Desert, Marble, Granite, Spider Nest, etc.).
- `Biomes` also highlights long traversable underground connectors (Abandoned Minecart Track), which improve orientation and long-form exploration.

This proposal converts those ideas into scoped, deterministic, and streaming-safe requirements for this project.

## What Changes
- Add explicit entrance-family generation so surface exploration regularly exposes readable cave entry points (mouths, ravines, sinkholes, cliff cuts, funnels, or equivalents).
- Strengthen deep-cavern progression with deterministic depth bands and wider, more memorable underground spaces.
- Add at least one long-form connector route family that links multiple large cave spaces.
- Keep all new cave logic deterministic per seed and chunk, and compatible with wrapped planetary topology.
- Add strict generation workload budgets so cave quality upgrades do not introduce walking-time loading stalls.

## Detailed Scope
- Focused capabilities: `exploration-underground-generation` and `exploration-terrain-richness`.
- This change does not add new enemy families, combat systems, or full tileset replacement.
- This change does not require replacing existing persistence architecture; deltas remain authoritative overrides.
- This change can reuse existing base material families, with only limited optional accent tiles.

## Impact
- Affected specs:
  - exploration-underground-generation
  - exploration-terrain-richness
- Affected code:
  - `src/systems/world/world_generator.gd`
  - `src/systems/world/infinite_chunk_manager.gd`
  - `src/systems/world/world_topology.gd`
  - debug and validation tools related to cave and traversal checks
- Relationship to existing changes:
  - Builds on `shift-worldgen-to-planetary-wraparound` for finite wrapped topology assumptions.
  - Complements (not replaces) broad terrain initiatives by narrowing acceptance criteria to natural entrances, deep cavern readability, and runtime smoothness.
