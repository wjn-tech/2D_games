## ADDED Requirements

### Requirement: Mina Final Encounter SHALL Provide Control Disruption Skill Windows
Mina final encounter SHALL schedule control-disruption skill windows and SHALL select one available disruption mechanic per window.

#### Scenario: Skill window selects one available mechanic
- **GIVEN** Mina final encounter combat is active
- **WHEN** a disruption skill window opens
- **THEN** Mina selects exactly one mechanic from the configured disruption pool
- **AND** selected mechanic respects cooldown and mutual exclusion constraints

### Requirement: Mina SHALL Support Safe Position Swap with Player
Mina SHALL be able to swap position with the player, and swap resolution SHALL pass safe landing validation.

#### Scenario: Position swap succeeds on valid floor points
- **GIVEN** Mina and player occupy valid navigable positions
- **WHEN** Mina triggers position swap
- **THEN** Mina and player exchange positions
- **AND** neither entity is embedded in terrain or outside encounter bounds

#### Scenario: Position swap degrades safely on invalid destination
- **GIVEN** one destination point is invalid for swap resolution
- **WHEN** Mina triggers position swap
- **THEN** full swap is cancelled
- **AND** encounter remains playable without hard-stuck state

### Requirement: Mina SHALL Apply Angina Debuff to Halve Player Max Health for 10 Seconds
Mina SHALL apply an Angina debuff that reduces player maximum health to 50% baseline for 10 seconds.

#### Scenario: Angina modifies and restores max health
- **GIVEN** player is in active Mina encounter
- **WHEN** Mina applies Angina debuff
- **THEN** player max health becomes 50% of pre-debuff baseline for 10 seconds
- **AND** player current health is clamped to modified max health if needed
- **AND** original max health is restored when debuff expires

### Requirement: Mina SHALL Disable Player Projectile Firing for 10 Seconds
Mina SHALL apply a Projectile Lock debuff that blocks player projectile emission for 10 seconds.

#### Scenario: Projectile lock blocks ranged emission only
- **GIVEN** player is under Projectile Lock during Mina encounter
- **WHEN** player attempts to fire wand or other projectile attacks
- **THEN** projectile emission is blocked for 10 seconds
- **AND** non-projectile movement and interaction inputs remain available unless affected by other active debuffs

### Requirement: Mina SHALL Invert Player Combat Movement Inputs for 10 Seconds
Mina SHALL apply an Input Inversion debuff that reverses player combat movement axes for 10 seconds.

#### Scenario: Input inversion affects combat movement but not UI controls
- **GIVEN** player is under Input Inversion during Mina encounter
- **WHEN** player provides combat movement input
- **THEN** horizontal and gravity-directional movement responses are inverted for 10 seconds
- **AND** pause/menu/inventory controls remain mapped to normal inputs

### Requirement: Mina SHALL Flip Player Gravity Direction for 10 Seconds
Mina SHALL apply a Gravity Flip debuff that inverts player gravity direction for 10 seconds and then restores baseline gravity.

#### Scenario: Gravity flip applies and restores cleanly
- **GIVEN** player is in active Mina encounter
- **WHEN** Mina applies Gravity Flip
- **THEN** player gravity direction is inverted for 10 seconds
- **AND** gravity direction returns to baseline after expiration without persistent drift

### Requirement: Mina Health Thresholds SHALL Reduce Player Attack by 20% per Fifth
Whenever Mina crosses each 20% health-loss threshold, player attack multiplier SHALL be reduced by 20% with multiplicative stacking and lower bound of 0.2.

#### Scenario: Threshold attack reduction stacks once per threshold
- **GIVEN** Mina starts at full health and player attack multiplier is 1.0
- **WHEN** Mina health crosses 80%, 60%, 40%, and 20% thresholds
- **THEN** player attack multiplier is reduced by ×0.8 per crossed threshold
- **AND** each threshold reduction triggers at most once
- **AND** player attack multiplier never drops below 0.2

### Requirement: Mina Control Debuffs SHALL Fully Clear on Encounter Exit
All Mina-specific temporary control and attribute debuffs SHALL be removed when encounter ends, regardless of victory, failure, or interruption path.

#### Scenario: Debuffs clear on failure return
- **GIVEN** player has active Angina, Projectile Lock, Input Inversion, and Gravity Flip debuffs
- **WHEN** encounter ends by player defeat and return flow
- **THEN** all Mina-applied debuffs are cleared
- **AND** player max health, projectile capability, input mapping, gravity, and attack multiplier return to baseline

### Requirement: Mina SHALL Enter Timed Invulnerability and Devour Projectiles Every 10 Seconds
During Mina final encounter, Mina SHALL enter a timed invulnerability window every 10 seconds and SHALL devour incoming projectiles during that window.

#### Scenario: Periodic invulnerability window activates
- **GIVEN** Mina encounter combat is active for at least 10 seconds
- **WHEN** periodic window trigger time is reached
- **THEN** Mina becomes invulnerable for the configured timed window
- **AND** projectiles intersecting Mina during the window are devoured instead of dealing damage

### Requirement: Mina SHALL Trigger 3-Second Invulnerability and Projectile Devour at Each Health Fifth Loss
Whenever Mina crosses each 20% health threshold, Mina SHALL gain 3 seconds invulnerability and SHALL devour projectiles for that duration.

#### Scenario: Threshold invulnerability on health fifth loss
- **GIVEN** Mina health crosses a new fifth-loss threshold
- **WHEN** threshold event resolves
- **THEN** Mina enters 3-second invulnerability
- **AND** Mina devours projectiles during the same 3-second window
- **AND** each threshold trigger occurs at most once

### Requirement: Mina Projectile Devour SHALL Increase Mina Damage by 1 Percent per Projectile
Each projectile devoured by Mina SHALL increase Mina damage multiplier by 1% within the current encounter.

#### Scenario: Devour scaling accumulates by projectile count
- **GIVEN** Mina has base damage multiplier 1.0 at encounter start
- **WHEN** Mina devours N projectiles
- **THEN** Mina damage multiplier increases by 1% per devoured projectile
- **AND** multiplier growth is deterministic from devour count

#### Scenario: Devour scaling resets on encounter end
- **GIVEN** Mina has non-default devour-based damage multiplier in an active encounter
- **WHEN** encounter ends by victory, failure, or interruption
- **THEN** devour-based damage multiplier is reset before next encounter

### Requirement: Timed and Threshold Invulnerability Windows SHALL Merge Deterministically
If timed invulnerability and threshold invulnerability overlap, Mina invulnerability state SHALL merge without early cancellation.

#### Scenario: Overlapping invulnerability windows
- **GIVEN** Mina is already invulnerable from one window source
- **WHEN** another invulnerability source triggers before current window ends
- **THEN** effective invulnerability end time is extended to the later end timestamp
- **AND** projectile devour remains active throughout the merged window
