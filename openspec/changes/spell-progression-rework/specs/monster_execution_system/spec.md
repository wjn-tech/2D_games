# Spec: Monster Execution System

## ADDED Requirements

### Req: Low Health Execution
Monsters can be executed when their health is critically low, providing better rewards.

#### Scenario: Execution Availability
- **Given** A Slime has 15% health (below the 20% threshold).
- **When** The player is within 50 pixels of the Slime.
- **Then** An "Execute" prompt is visible above the Slime.

#### Scenario: Execution Sequence
- **Given** An "Execute" prompt is visible.
- **When** The player presses the "Execute" button (F).
- **Then** The Slime is pulled towards the player.
- **And** The Slime explodes upon reaching the player.
- **And** No damage is dealt to the player or surrounding entities by the explosion.
- **And** Loot drops with a higher probability of containing a spell unlock.

#### Scenario: Execution Loot Bonus
- **Given** A monster has a 5% chance to drop a spell normally.
- **When** The monster is killed via execution.
- **Then** The spell drop chance is increased (e.g., to 25%).
