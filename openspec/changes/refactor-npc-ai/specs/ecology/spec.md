# Spec: NPC Ecology & Happiness

## ADDED Requirements

### Req: Happiness Index
NPCs must have a happiness value that fluctuates based on environmental and social factors.

#### Scenario: Neighbor Affinity
- **GIVEN** a Merchant NPC who likes the Nurse.
- **AND** the Nurse is within 10 tiles of the Merchant.
- **WHEN** the Merchant's happiness is recalculated.
- **THEN** it increases by a "Like" bonus, potentially reducing shop prices.

### Req: Weather-Specific Behavior
NPCs must react to changing weather conditions.

#### Scenario: Rainfall Response
- **GIVEN** a "Passive" NPC currently in `WanderState`.
- **WHEN** `SettlementManager` signals the start of rain.
- **THEN** the Blackboard variable `is_raining` becomes true.
- **AND** the HSM transitions the NPC to `HomeState`.

### Req: Contextual Dialogue
NPCs should provide feedback based on world events.

#### Scenario: Boss Defeat Dialogue
- **GIVEN** a player is talking to an NPC.
- **AND** the global flag `boss_1_defeated` is true.
- **WHEN** the BT selects a dialogue pool.
- **THEN** it prioritizes lines related to the boss defeat.
