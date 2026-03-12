## 1. Topology Foundation
- [x] 1.1 Define topology_mode, topology_version, circumference, world size preset, spawn anchor, and spawn-safe radius metadata for new worlds.
- [x] 1.2 Standardize initial world size presets and document how biome arc budgets and landmark budgets scale with each preset.
- [x] 1.3 Add shared wrapped-coordinate helpers for chunk lookup, tile queries, shortest-distance checks, seam-safe neighbor iteration, and canonical chunk identity.
- [x] 1.4 Update chunk streaming so east/west traversal wraps continuously across the world seam without reload gaps, duplicate chunk identities, or seam-specific query forks.

## 2. Macro World Planning
- [x] 2.1 Add a seed-derived world plan that reserves surface biome arcs, transition bands, spawn-safe regions, seam buffers, and major landmark slots across the full circumference.
- [x] 2.2 Define a landmark taxonomy and placement budget for unique landmarks, regional rare landmarks, and local non-planned decorations.
- [x] 2.3 Expose read-only queries so terrain, structures, spawning, minimap, and navigation systems can ask for macro biome, nearest landmark slot, spawn-safe status, and wrapped regional distance.
- [x] 2.4 Rework major structure placement so unique or rare world landmarks are placed from the world plan instead of only chunk-local hash decisions.

## 3. Geological Progression
- [x] 3.1 Replace unbounded depth assumptions with ordered depth bands, explicit transition rules, and a defined deepest progression region for new planetary worlds.
- [x] 3.2 Update cave and connector generation so vertical routes link intended depth bands, preserve traversal readability, and avoid endless freefall shafts as a normal outcome.
- [x] 3.3 Tie resource strata, hazard zones, and underground biome variants to both macro world region and depth band.
- [x] 3.4 Define which hazards, rare materials, and special underground pockets are globally planned versus locally generated inside an allowed region.

## 4. Streaming, Save Data, and Compatibility
- [x] 4.1 Canonicalize world delta keys and chunk persistence so seam-adjacent edits persist correctly under wrapped coordinates and do not create duplicate save files for one physical region.
- [x] 4.2 Persist topology metadata with saves and prevent legacy infinite-world saves from being silently interpreted as planetary saves.
- [x] 4.3 Update world creation and load flows so new saves explicitly opt into the planetary topology and expose the selected world size preset.
- [x] 4.4 Update minimap and other persistent world-query consumers so seam-adjacent discovery and landmark references remain continuous after save/load.

## 5. Validation
- [ ] 5.1 Verify representative seeds across all initial world size presets to confirm that traveling east or west for one full circumference returns the player to the originating region without seam artifacts.
- [ ] 5.2 Validate spawn-safe region quality, biome ordering, landmark uniqueness, depth progression, and underground traversal quality across multiple seeds and world sizes.
- [ ] 5.3 Validate save/load behavior for both planetary_v1 and legacy_infinite paths, including seam-adjacent terrain edits and minimap continuity.
- [x] 5.4 Run openspec validate shift-worldgen-to-planetary-wraparound --strict and resolve all validation issues.