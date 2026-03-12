## Context
The project already ships an infinite chunked world built from noise-driven terrain, basic landmarks, and a compact hostile roster. The user's request is not for another generation framework, but for a more rewarding exploration loop where terrain shape, biome identity, underground structure, enemy composition, and attack patterns all reinforce each other.

Current reality in code:
- WorldGenerator produces surface height, biome assignment, cave/tunnel carving, trees, ore replacement, and a limited set of structures.
- InfiniteChunkManager streams chunk cells and overlays structures, trees, and saved deltas.
- NPCSpawner currently supports a small roster with simple biome/depth/time gating, including a coarse cavern zone split but little cave-specific encounter logic.
- Several hostile attack paths already exist, but only a few enemies are truly behavior-distinct.

## Goals / Non-Goals
- Goals:
- Make underground traversal more varied and readable than the current threshold-carved caves.
- Make cave progression reliably traversable so players can descend, route around chambers, and re-enter underground regions without excessive dead ends or sealed encounter pockets.
- Make surface and transition terrain feel regionally distinct without abandoning the current chunk/delta architecture.
- Expand hostile families in a biome-aware way so terrain identity and enemy identity co-evolve.
- Make underground hostile generation react to cave context and reachability rather than only broad depth bands.
- Give each hostile family in scope a signature attack or combat behavior that changes player response.

- Non-Goals:
- Replace the infinite chunk architecture with a fundamentally different world system.
- Introduce story progression, boss progression, or loot economy redesign in this change.
- Create final-art-grade content counts for every future biome in one iteration.

## Decisions
- Decision: Split the proposal into four capability deltas instead of one giant spec.
- Alternatives considered: One monolithic exploration spec would be shorter, but it would make validation and implementation sequencing vague.

- Decision: Treat underground cave improvement and terrain richness as separate but linked capabilities.
- Alternatives considered: Combining them would hide an important implementation dependency: cave topology can evolve independently from surface landmark/decorator density.

- Decision: Define cave accessibility as a proposal-level requirement rather than leaving it as an implementation detail.
- Alternatives considered: Purely aesthetic cave diversification would be easier to ship, but it would not address the user's stated need for better exploration quality underground.

- Decision: Bind new hostile families to biome/depth bands and terrain features instead of adding a global enemy list.
- Alternatives considered: Adding standalone monsters first would be faster, but it would not satisfy the user's request for terrain-matched exploration.

- Decision: Require cave encounter logic to consider cave-region type and local reachability, not only biome/depth labels.
- Alternatives considered: Using only biome/depth tags would keep the spawner simpler, but it would continue producing cave encounters that feel detached from actual underground space quality.

- Decision: Require signature attacks at the family level rather than only broad archetype labels.
- Alternatives considered: Reusing generic melee/projectile patterns with only stat changes would increase count but not meaningfully improve playability.

## Risks / Trade-offs
- More cave variety can reduce readability or navigation if connection rules are too chaotic.
  Mitigation: require deterministic archetypes with traversable connectors and validation on representative seeds.

- Accessibility constraints can reduce raw randomness and make some cave shapes less dramatic.
  Mitigation: prioritize readable exploration loops first, then layer optional rare set-piece caves on top of a reachable backbone.

- More biome-native hostiles can create spawn-table complexity and balance spikes.
  Mitigation: define spawn composition rules per biome/depth band and validate representative seeds instead of tuning ad hoc.

- Cave-aware spawning can accidentally place hostile pressure in sealed or unfair spaces if region tags are too coarse.
  Mitigation: require encounter-worthy cave regions to expose enough metadata for spawn validation, including whether a space is traversable or pocket-like.

- Signature attacks increase content cost per enemy family.
  Mitigation: allow reuse of shared combat modules while requiring distinct telegraph/behavior combinations.

## Migration Plan
1. Formalize terrain and cave requirements first so world tags and spawn hooks are stable.
2. Add cave accessibility and cave-region classification hooks before expanding underground spawn tables broadly.
3. Add terrain richness and encounter hooks for surface and transition spaces.
4. Expand hostile families biome by biome or depth band by depth band.
5. Implement or revise signature attacks after the roster and habitat mapping are stable.

## Open Questions
- This proposal intentionally does not lock exact final enemy counts per biome; implementation can choose conservative content tiers so long as each major biome/depth band gains native encounter identity.
- Landmark/decorator content can be tile-based, entity-based, or hybrid, as long as it remains deterministic under chunk reloads.
