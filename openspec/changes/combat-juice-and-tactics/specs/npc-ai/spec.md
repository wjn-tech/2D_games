# Spec: Tactical NPC AI

**Status**: Draft
**Version**: 1.0

## MODIFIED Requirements

### `AI-001` - Telegraphing Attacks
#### Scenario: NPC prepares attack
- **Given** an NPC decides to attack the player.
- **When** entering the `Attack_Charge` state.
- **Then** the NPC plays a "Windup" animation.
- **And** a visual indicator (exclamation mark or red tint) appears above the NPC 0.4s before the hitbox activates.
- **And** the NPC rotates to face the player during the first 50% of the charge, then locks rotation.

### `AI-002` - Flanking Behavior
#### Scenario: Multiple enemies engage
- **Given** 2+ enemies are engaging the player.
- **When** selecting a movement target.
- **Then** Enemy A chooses a direct path.
- **And** Enemy B chooses a point 45 degrees offset from the Player-EnemyA axis (Flanking).
- **And** they maintain a minimum separation distance of `50px` from each other to prevent stacking.

### `AI-003` - Reactionary Defense
#### Scenario: Player attacks
- **Given** the Player initiates an attack animation while looking at the NPC.
- **And** the NPC is in `State_Combat_Idle`.
- **When** the attack is detected (via simulated "hearing" or proximity trigger).
- **Then** the NPC has a `30%` chance to transition to `State_Dodge` (backward jump) immediately.
