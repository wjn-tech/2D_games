# Spec: Developer Debug Tools for Lineage

## ADDED Requirements

### Affinity Manipulation
Developers must be able to instantly manipulate relationship values to verify gating logic.

#### Scenario: Force Marriage
- **Given** an NPC with 0 Affinity.
- **When** the developer runs `debug_force_marry`.
- **Then** the NPC's affinity becomes Max.
- **And** the NPC becomes the player's spouse immediately.

### Growth Skipping
Developers must be able to bypass real-time waiting for growth stages.

#### Scenario: Instant Adulthood
- **Given** a Baby entity (Age 0).
- **When** the developer runs `debug_grow_child(ADULT)`.
- **Then** the Entity scales to 1.0 immediately.
- **And** stats update to Adult values.

### Lifecycle Debugging
Developers need tools to trigger rare or terminal events.

#### Scenario: Force Breeding
- **Given** a valid spouse nearby.
- **When** `debug_spawn_baby` is triggered.
- **Then** A baby is spawned immediately without pregnancy/incubation timers.

#### Scenario: Instant Death
- **Given** a healthy player.
- **When** `debug_kill_player` is triggered.
- **Then** The player HP becomes 0.
- **And** The Heir Selection flow starts immediately.
