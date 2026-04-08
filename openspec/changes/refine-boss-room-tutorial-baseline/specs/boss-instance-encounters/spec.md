## ADDED Requirements

### Requirement: All Boss Triggers SHALL Enter Dedicated Encounter Scenes Deterministically
For all four boss triggers, interaction SHALL always enter the mapped dedicated encounter scene.

#### Scenario: Slime king trigger always enters dedicated room
- **GIVEN** player equips `slime_king_sigil` and has at least one item count
- **WHEN** player presses interact during normal gameplay state
- **THEN** encounter runtime loads `boss_slime_king.tscn`
- **AND** combat does not execute in main world scene

#### Scenario: Mina finale trigger always enters dedicated room
- **GIVEN** player equips `forbidden_key` and has at least one item count
- **WHEN** player presses interact during normal gameplay state
- **THEN** encounter runtime loads `boss_mina_finale.tscn`
- **AND** combat does not execute in main world scene

#### Scenario: Batch regression guarantees 100 percent isolated entry
- **GIVEN** each boss trigger item is tested in at least 30 independent entry attempts
- **WHEN** encounter entry regression statistics are collected
- **THEN** every attempt enters mapped dedicated encounter scene
- **AND** entry success rate is exactly 100 percent for each boss

### Requirement: Encounter Intro SHALL Include Boss Camera Focus Before Combat
Each boss encounter SHALL run camera focus on boss before activating combat.

#### Scenario: Intro focus gate before combat activation
- **GIVEN** player has just entered any boss encounter room
- **WHEN** intro sequence starts
- **THEN** camera focus targets IntroFocus/Boss area first
- **AND** combat activation occurs only after intro focus phase finishes

#### Scenario: Intro focus duration is unified
- **GIVEN** any of the four boss encounters starts
- **WHEN** intro focus phase plays
- **THEN** boss camera focus duration is 1.2 seconds
- **AND** combat activation cannot begin before the 1.2-second focus phase completes

### Requirement: Encounter Result SHALL Preserve Existing Return Rules
This refinement SHALL preserve current return rules after encounter result.

#### Scenario: Defeat returns to entry position
- **GIVEN** player entered encounter from world position P
- **WHEN** player is defeated in encounter
- **THEN** trigger item remains consumed
- **AND** player returns to world position P

#### Scenario: Victory returns to entry position
- **GIVEN** player entered encounter from world position P
- **WHEN** encounter ends in victory
- **THEN** mapped reward resolution executes
- **AND** player returns to world position P
