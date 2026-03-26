## ADDED Requirements

### Requirement: Hostile Families SHALL Expose Signature Combat Behaviors
Each hostile family in scope for world spawning SHALL have a signature combat behavior that differentiates it from simple stat-swapped melee or projectile enemies.

#### Scenario: Signature behavior is readable before impact
- **WHEN** a player encounters a hostile family in combat
- **THEN** that family presents a telegraphed signature action, movement pattern, attack timing, area control pattern, or projectile behavior that can be learned and responded to

#### Scenario: Signature attacks remain integrated with shared combat rules
- **WHEN** a hostile family uses its signature attack
- **THEN** damage application, timing resolution, and hit feedback still route through the shared combat pipeline where applicable

### Requirement: Overlapping Hostile Families SHALL Remain Distinct
Hostile families that share the same biome or depth band SHALL remain behaviorally distinct in practice.

#### Scenario: Two families in the same region do not collapse into the same role
- **WHEN** the player fights two different hostile families that can appear in the same biome or depth band
- **THEN** their pressure patterns differ by reach, mobility, telegraph, control space, status effect, summon pattern, or equivalent combat identity
