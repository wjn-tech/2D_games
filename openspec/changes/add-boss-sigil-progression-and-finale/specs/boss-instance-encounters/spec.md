## ADDED Requirements

### Requirement: Boss Sigils SHALL Open Dedicated Encounter Scenes
Using a valid boss sigil SHALL transfer player into mapped dedicated boss encounter scene.

#### Scenario: Enter slime king room with sigil
- **GIVEN** player owns and equips `slime_king_sigil`
- **WHEN** player presses interact
- **THEN** sigil is consumed
- **AND** encounter runtime loads slime king room scene

#### Scenario: Encounter entry has no extra gate
- **GIVEN** player owns and equips any valid boss sigil
- **WHEN** player presses interact in normal gameplay state
- **THEN** encounter starts without extra biome/time/quest preconditions

### Requirement: Encounter Entry SHALL Execute Camera Intro and Gate Lock
Entering encounter scene SHALL execute deterministic opening sequence before active combat.

#### Scenario: Opening sequence baseline
- **GIVEN** player consumes valid encounter trigger item
- **WHEN** encounter scene loads
- **THEN** opening camera sequence is played
- **AND** gate lock is applied before boss combat becomes active
- **AND** player receives encounter-start feedback

### Requirement: Boss Rooms SHALL Be Independent Scenes with Tutorial-Style Baseline
Each boss room SHALL be implemented as an independent scene and SHALL follow tutorial-style baseline for composition and visual rhythm.

#### Scenario: Independent scene isolation
- **GIVEN** player has entered any boss encounter room
- **WHEN** encounter starts
- **THEN** active combat scene is independent from main world streaming context
- **AND** room does not require world chunk streaming nodes to function

#### Scenario: Tutorial-style baseline check
- **GIVEN** boss room scene is loaded
- **WHEN** scene structure validation runs
- **THEN** room includes tutorial-style baseline composition nodes
- **AND** room remains isolated from tutorial story scripting

### Requirement: Boss Encounters SHALL Support Repeat Challenges
Boss encounters SHALL allow repeated entry and repeated reward distribution under same rules.

#### Scenario: Re-enter completed boss
- **GIVEN** player has previously defeated a boss
- **WHEN** player consumes another matching sigil
- **THEN** encounter entry is allowed again
- **AND** victory reward rules are applied again

### Requirement: Encounter Failure SHALL Return Player to Main World Flow
Player death in boss encounter SHALL fail the encounter and return player to main world flow.

#### Scenario: Death causes direct return
- **GIVEN** boss encounter is active
- **WHEN** player health reaches zero
- **THEN** encounter result is failure
- **AND** only encounter trigger item consumption remains effective
- **AND** player is returned to pre-entry world position

### Requirement: Boss Projectile Attacks SHALL Use Visible Physical Entities
All boss projectile attacks SHALL be represented by visible entity projectiles with collision and hit feedback.

#### Scenario: Projectile readability contract
- **GIVEN** any boss executes a projectile attack pattern
- **WHEN** projectiles spawn
- **THEN** each projectile has visible render presence
- **AND** each projectile has collision representation for hit detection
- **AND** projectile hit result is surfaced through combat feedback pipeline

### Requirement: Each Boss Victory SHALL Grant Its Unique Core
Defeating a boss SHALL grant exactly one unique core mapped to that boss.

#### Scenario: Skeleton king victory reward
- **GIVEN** skeleton king encounter ends in victory
- **WHEN** reward distribution runs
- **THEN** exactly one `skeleton_king_core` is granted

#### Scenario: Repeat victory remains reward-valid
- **GIVEN** player re-enters a previously cleared boss encounter
- **WHEN** victory reward distribution runs
- **THEN** mapped core reward is granted again by the same rule
