## ADDED Requirements

### Requirement: Unique Signature Drop Per Hostile Type
The system SHALL define exactly one signature drop item for every currently spawnable hostile monster type, and signature items SHALL be unique across hostile types.

Current hostile type set is based on spawnable scenes from `data/npcs/hostile_spawn_table.json`:
- slime
- bog_slime
- zombie
- skeleton
- cave_bat
- frost_bat
- antlion
- demon_eye

#### Scenario: Signature uniqueness validation
- **Given** the hostile loot table data is loaded
- **When** validation checks all hostile type entries
- **Then** each hostile type has one non-empty `signature_drop.item_id`
- **And** no two hostile types share the same `signature_drop.item_id`

### Requirement: Baseline Hostile Loot Matrix
The system SHALL provide a baseline drop matrix for all current hostile monster types with the following signature mapping:
- slime -> slime_essence
- bog_slime -> bog_core
- zombie -> rotten_talisman
- skeleton -> bone_fragment
- cave_bat -> echo_wing
- frost_bat -> frost_gland
- antlion -> antlion_mandible
- demon_eye -> void_eyeball

Each hostile type SHALL additionally provide a common monster-material pool with configurable probability and quantity ranges.

#### Scenario: Hostile kill resolves baseline entry
- **Given** a hostile death event from one of the 8 baseline hostile types
- **When** loot resolution runs with no rule override hit
- **Then** the system resolves the hostile type's baseline drop entry
- **And** the signature roll uses that entry's configured probability and quantity range
- **And** the common pool roll uses that entry's configured rules

### Requirement: No Terrain-Block Items in Default Hostile Pools
Default hostile drop pools SHALL NOT use terrain block resources (for example `grass`, `dirt`, `stone`, `sand`, `snow`) as common monster drops unless an explicit rule-level exception is configured.

#### Scenario: Validate hostile pool semantic consistency
- **Given** the default hostile drop matrix is loaded
- **When** validation scans `common_pool` item IDs
- **Then** terrain block item IDs are rejected for default hostile entries
- **And** validation requires explicit `rule_override` annotation for any approved exception

### Requirement: Rule-Override-Aware Loot Resolution
The system SHALL support optional drop overrides keyed by hostile spawn `rule_id`, where override entries take precedence over hostile-type baseline entries.

#### Scenario: Underworld rule override applied
- **Given** a hostile death event with `rule_id = skeleton_underworld_legion`
- **When** loot resolution runs
- **Then** the `skeleton_underworld_legion` override is used instead of baseline `skeleton`
- **And** if override data is missing, the resolver falls back to baseline `skeleton`

### Requirement: Compatibility with Spell Absorption and Existing Rewards
The system SHALL preserve existing hostile death side effects for spell absorption, XP gain, and gold gain when item loot is introduced.

#### Scenario: Item drop does not suppress spell absorption
- **Given** a hostile dies and item loot roll executes
- **When** the death pipeline completes
- **Then** spell absorption handling still runs
- **And** XP reward is still granted
- **And** gold reward logic for hostile targets is still granted

### Requirement: Complete Coverage of Spawn Rules
The system SHALL ensure every hostile spawn rule in `data/npcs/hostile_spawn_table.json` can resolve to a valid loot configuration through either direct `rule_id` override or hostile-type baseline mapping.

#### Scenario: Full rule coverage check
- **Given** the current hostile spawn table contains 10 rules
- **When** coverage validation is executed
- **Then** all 10 rules resolve to a valid loot entry
- **And** validation fails if any rule cannot resolve to either override or baseline mapping
