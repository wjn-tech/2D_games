# Spec: NPC Variety

## ADDED Requirements

### Req: Diverse Roles
NPCs must belong to specific roles that dictate their social and combat interactions.

#### Scenario: Guard NPC Engagement
- **Given** A "village_guard" NPC is idle in a town.
- **And** A "slime" (Hostile) enters the guard's detection range.
- **When** The guard detects the slime.
- **Then** The guard should switch to "Combat" mode and attack the slime.

#### Scenario: Merchant NPC Recognition
- **Given** An NPC has the "Merchant" occupation.
- **When** The player looks at its nameplate.
- **Then** It should display its role (e.g., "Food Merchant: Bobert").

#### Scenario: Wizard Spell Casting
- **Given** A "village_wizard" NPC is in the world.
- **When** A hostile target is detected.
- **Then** The wizard should use magical projectiles to attack.
- **And** The wizard should play a distinct casting animation/visual.

#### Scenario: Visual Accessories
- **Given** A "Guard" NPC.
- **When** The NPC is rendered.
- **Then** A small rectangle (Shield) should be visible on its side.
- **And** Its primary color should be distinctive (e.g., Metallic Blue).

#### Scenario: Peasant Fleeing
- **Given** A passive "villager_peasant" NPC.
- **And** Combat is occurring nearby.
- **When** the peasant is within range of a hostile entity.
- **Then** the peasant should attempt to move away from the threat.
