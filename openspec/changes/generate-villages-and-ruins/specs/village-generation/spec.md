# Capability: Village and Ruin Generation

## MODIFIED Requirements

### Requirement: World Generation
The world generator SHALL now include structured settlements and historical ruins.

#### Scenario: Village Generation
- **Given** the world is being generated.
- **When** a flat area of at least 40 tiles is found on the surface.
- **Then** a village cluster containing 3-5 buildings should be spawned.
- **And** each building should contain at least one NPC or a loot chest.

#### Scenario: Ruin Generation
- **Given** the world is being generated.
- **When** the generator processes the underground layer or remote surface areas.
- **Then** isolated ruin structures should be spawned with a 5% probability in suitable locations.
- **And** ruins should always contain at least one loot chest.

### Requirement: Building Interaction
Buildings MUST be interactive and destructible.

#### Scenario: Looting Chests
- **Given** a player is near a generated chest.
- **When** the player interacts with the chest.
- **Then** a loot UI should open showing randomized items based on the building type.

#### Scenario: Dismantling Buildings
- **Given** a player has a suitable tool (e.g., axe or pickaxe).
- **When** the player attacks a building structure.
- **Then** the building should take damage and eventually drop resources (wood, stone, etc.).
