## ADDED Requirements

### Requirement: Town Population Registration
Town NPCs SHALL be registered in the runtime group consumed by settlement, housing, and migration systems.

#### Scenario: Existing town NPC scene loads
- GIVEN a town NPC scene such as a merchant or princess enters the world
- WHEN initialization completes
- THEN the NPC MUST join the town population group used by settlement scans
- AND housing assignment logic MUST be able to discover it without custom scene-specific code

#### Scenario: Migrated town NPC arrives
- GIVEN the migration system instantiates a town NPC into the current scene
- WHEN arrival finalizes
- THEN the NPC MUST join the same town population group before housing or happiness logic runs

### Requirement: Migration Economy Check
Town migration unlock conditions SHALL use the canonical player currency source exposed by CharacterData.

#### Scenario: Merchant arrival threshold
- GIVEN a migration rule requires minimum player currency
- WHEN the system evaluates arrival eligibility
- THEN it MUST read the supported CharacterData money field or API
- AND the check MUST remain valid for both fresh runtime and loaded saves

### Requirement: Hostile Isolation in Shared World Logic
Friendly town NPCs SHALL participate in settlement logic without being classified as hostiles by shared world systems.

#### Scenario: Friendly NPC near hostile systems
- GIVEN friendly town NPCs coexist with hostile mobs in the same world
- WHEN settlement, spawn, save/load, and door systems evaluate them
- THEN the friendly NPCs MUST remain eligible for town logic
- AND hostile-only systems MUST not count or filter them as enemies
