## 1. World Generation Foundations
- [x] 1.1 Extend underground generation to support distinct cave archetypes, biome-themed underground pockets, and deterministic placement rules tied to world seed and chunk coordinates.
- [x] 1.2 Add cave accessibility rules so underground generation preserves traversable descent routes, reconnectable chambers, and manageable dead-end frequency across chunk boundaries.
- [x] 1.3 Define metadata or helper queries needed by encounter systems to classify cave type, biome identity, local reachability, and encounter-worthy terrain regions.
- [x] 1.4 Add terrain richness layers for major surface biomes, including landmark/decorator placement rules and safe integration with chunk streaming and delta persistence.

## 2. Underground Encounter Ecology
- [x] 2.1 Define cave-region spawn rules so underground and cavern encounters react to cave archetype, local openness, and reachability instead of only broad depth bands.
- [x] 2.2 Prevent cave encounter placement in sealed, unfair, or non-traversable pockets unless intentionally marked as special challenge spaces.
- [x] 2.3 Add biome-native underground hostile families or variants for cave bands that currently reuse generic fallback spawns.

## 3. Hostile Content Expansion
- [x] 3.1 Expand the hostile spawn roster so major biome/depth bands gain native enemy families rather than relying on the current shared fallback pool.
- [x] 3.2 Define spawn weighting, grouping, and progression rules that bind hostile families to matching terrain features, time windows, and depth bands.
- [x] 3.3 Add or revise hostile scene/resource data so each family has a stable role, readable visual identity, and deterministic spawn integration.

## 4. Combat Identity
- [x] 4.1 Define a signature attack pattern for each hostile family in scope, including telegraph, effective range, and intended player response.
- [x] 4.2 Integrate signature attacks with the shared combat pipeline so damage, timing, projectiles, dash logic, and status effects remain consistent.
- [x] 4.3 Add balancing passes for overlap cases where two hostile families occupy the same biome/depth band.

## 5. Validation
- [ ] 5.1 Add regression coverage or debug verification steps for seed determinism, chunk reload stability, terrain/hostile pairing consistency, and cave accessibility.
- [ ] 5.2 Validate representative seeds to confirm terrain diversity, cave readability, hostile distribution, underground encounter fairness, and attack uniqueness across biomes.
- [x] 5.3 Run openspec validate expand-exploration-terrain-and-hostiles --strict and resolve all validation issues.
