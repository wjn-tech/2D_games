## ADDED Requirements

### Requirement: Boss Arenas SHALL Provide Multi-Layer Visual Composition
Each boss arena SHALL include a minimum three-layer visual composition (far background, midground atmosphere, foreground detail) while preserving existing collision boundaries.

#### Scenario: Layered composition baseline
- **GIVEN** any of the four boss encounter scenes is loaded
- **WHEN** visual structure validation runs
- **THEN** scene contains explicit far/mid/foreground visual nodes
- **AND** arena collision boundary nodes remain unchanged in behavior

### Requirement: Boss Gates SHALL Expose Readable Lock-State Visual Feedback
Boss gate visuals SHALL communicate lock and unlock states through color + luminance + motion cues, not color change alone.

#### Scenario: Lock state readability
- **GIVEN** encounter gate is locked before combat
- **WHEN** gate visual state is evaluated
- **THEN** gate shows lock-specific visual feedback with at least two channels among color, glow intensity, and animation

#### Scenario: Unlock state readability
- **GIVEN** encounter completes and gate unlocks
- **WHEN** unlock transition plays
- **THEN** gate enters a distinct unlock visual state
- **AND** player can distinguish unlocked state within one second

### Requirement: Boss Arena Theme SHALL Be Tokenized Per Encounter
The four boss arenas SHALL use per-encounter visual tokens while sharing a unified layout contract.

#### Scenario: Unified layout with differentiated theme
- **GIVEN** slime, skeleton, eye, and mina encounter rooms
- **WHEN** style token validation runs
- **THEN** each room has a defined token set (primary hue, event accent, atmosphere strength)
- **AND** all rooms still satisfy the same structural template requirements

### Requirement: Visual Enhancement SHALL Preserve Combat Readability
Arena visuals SHALL not reduce readability of player, boss, or projectile entities during active combat.

#### Scenario: Projectile readability guard
- **GIVEN** boss projectiles are active during combat
- **WHEN** readability checks run on representative combat frames
- **THEN** projectile silhouettes remain visually separable from the background
- **AND** failed readability checks block acceptance

### Requirement: Visual Systems SHALL Support Budgeted Degradation
Boss arena visual systems SHALL provide a bounded degradation path under performance pressure.

#### Scenario: Budget pressure fallback
- **GIVEN** runtime detects visual budget pressure
- **WHEN** degradation policy is applied
- **THEN** non-critical ambience effects are reduced first
- **AND** gameplay-critical visual feedback (boss, player, gate state) remains intact