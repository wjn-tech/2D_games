## ADDED Requirements

### Requirement: Forbidden Key SHALL Require Three Boss Cores and Arcane Dust
The crafting system SHALL define forbidden key recipe requiring 10 `arcane_dust` and one of each boss core.

#### Scenario: Craft forbidden key
- **GIVEN** player inventory contains 10 `arcane_dust`, `slime_king_core`, `skeleton_king_core`, and `eye_king_core`
- **WHEN** player crafts `forbidden_key`
- **THEN** all required materials are consumed
- **AND** exactly one `forbidden_key` is produced

### Requirement: Forbidden Key SHALL Gate Mina Final Encounter
Using `forbidden_key` SHALL open Mina final encounter scene.

#### Scenario: Enter Mina encounter
- **GIVEN** player owns and equips `forbidden_key`
- **WHEN** player presses interact
- **THEN** key is consumed
- **AND** Mina final encounter scene is loaded

### Requirement: Mina Encounter SHALL Snapshot Player Baseline at Start
At encounter start, Mina SHALL initialize from player baseline health and wand profile snapshot.

#### Scenario: Snapshot baseline on start
- **GIVEN** player starts Mina encounter with current health and active wand profile
- **WHEN** Mina entity initializes
- **THEN** Mina receives start-of-battle player health snapshot
- **AND** Mina receives start-of-battle current wand snapshot
- **AND** mid-battle player changes do not retroactively mutate Mina baseline

### Requirement: Mina Defeat SHALL Mark Persistent Completion and Keep Save Playable
Defeating Mina SHALL persist completion state and SHALL keep save playable after completion flow.

#### Scenario: Completion persistence
- **GIVEN** Mina encounter is active
- **WHEN** Mina defeat sequence completes
- **THEN** game completion flag is written into progression persistence
- **AND** player receives explicit completion feedback

#### Scenario: Continue play after clear
- **GIVEN** game completion flag has been written
- **WHEN** completion flow ends
- **THEN** player can continue gameplay on same save
- **AND** save is not hard-locked

### Requirement: Mina Final Encounter SHALL Be Repeatable After Completion
Mina final encounter SHALL remain entry-eligible after game completion state is already set.

#### Scenario: Re-enter Mina after clear
- **GIVEN** game completion flag is already true
- **WHEN** player equips and uses another `forbidden_key`
- **THEN** Mina final encounter starts normally
- **AND** completion state remains valid and save remains playable
