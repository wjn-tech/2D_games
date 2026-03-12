## 1. Authoritative Liquid Foundations
- [ ] 1.1 Introduce a chunk-friendly authoritative liquid data layer that stores liquid type, fill amount, and active or sleeping state independently from the visual tilemap.
- [ ] 1.2 Implement deterministic active-region liquid stepping with vertical fall, lateral equalization, settling, and sleeping behavior for at least Water and Lava.
- [ ] 1.3 Persist modified liquid state in chunk deltas and ensure liquid reload behavior is stable across unload and reload cycles.

## 2. Worldgen and Settling
- [ ] 2.1 Add biome- and depth-aware liquid reservoir placement for at least surface or shallow water pockets and deep lava pools.
- [ ] 2.2 Add a worldgen settling or stabilization pass so newly generated liquid bodies do not remain in obviously suspended or noisy intermediate states.
- [ ] 2.3 Expose deterministic queries for nearby liquid presence, liquid type, and settled reservoir context so gameplay systems can consume them.

## 3. Interaction Rules
- [ ] 3.1 Add tile or material metadata for liquid openness, fallthrough behavior, flammability, and heat or reaction behavior.
- [ ] 3.2 Implement baseline entity interactions for Water and Lava, including movement or immersion effects plus drowning or damage semantics where applicable.
- [ ] 3.3 Implement at least one stable liquid reaction path, such as Water and Lava producing a solid result, and wire water-fire or lava-fire hooks through the same reaction layer.
- [ ] 3.4 Add basic fill or drain interfaces for future bucket, pump, or scripted liquid placement tools.

## 4. Presentation Layer
- [ ] 4.1 Render liquid bodies from authoritative fill data with readable surface height, color, and opacity or emissive cues per liquid type.
- [ ] 4.2 Implement visual-only liquidfalls or drips as a separate presentation path that can be triggered by level geometry without requiring full volume simulation.
- [ ] 4.3 Evaluate optional near-camera splash or metaball-like enhancements inspired by the attached Godot fluid demos without making them the authoritative world simulation.

## 5. Phased Expansion
- [ ] 5.1 Add profile-based extension points for slower buff-style liquids such as Honey.
- [ ] 5.2 Reserve a dedicated special-rule path for a future transmutation liquid instead of hardcoding all liquids into one generic branch.

## 6. Validation
- [ ] 6.1 Add debug or regression checks for settling stability, chunk reload consistency, liquid-type flow differences, and reaction determinism.
- [ ] 6.2 Validate representative seeds and runtime scenarios to confirm useful reservoir generation, stable active-region simulation, and non-authoritative liquidfall presentation.
- [ ] 6.3 Run openspec validate implement-elemental-chemistry --strict and resolve all validation issues.