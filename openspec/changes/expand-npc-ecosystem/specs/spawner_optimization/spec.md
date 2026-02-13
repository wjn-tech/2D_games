# Spec: Spawner Optimization

## MODIFIED Requirements

### Req: Population Density
The number of NPCs in an area must scale based on the context and biome.

#### Scenario: Village Population
- **Given** The player is in a "Village" biome.
- **When** The spawner runs its cycle.
- **Then** It should allow for a higher `area_capacity` than wilderness biomes.

### Req: Herd Spawning
Certain species should spawn in cohesive groups rather than isolated individuals.

#### Scenario: Wolf Pack Spawn
- **Given** A "wolf" spawn rule with a `herd_size` of (3, 5).
- **When** A wolf is selected to spawn.
- **Then** The spawner should attempt to instantiate 3 to 5 wolves in a tight radius.
