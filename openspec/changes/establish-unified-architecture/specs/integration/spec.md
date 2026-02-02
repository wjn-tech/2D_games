# Spec: System Integration

## ADDED Requirements

### Requirement: Unified Event Messaging SHALL
All inter-system calls that cross domain boundaries (e.g., World to UI) SHALL go through the `EventBus` or a public Autoload API.

#### Scenario: Building destruction notification
- **Given** a `DestructibleBuilding` reaching 0 health.
- **When** the `_destroy()` method is called.
- **Then** it must emit a signal to the `EventBus` (e.g., `building_destroyed`).
- **And** the `SettlementManager` must update its local village data based on this event.

### Requirement: Layer-Isolated Interaction SHALL
All interactions (Mining, Combat, Chemistry) SHALL respect the currently active layer defined in `LayerManager`.

#### Scenario: Mining in the Underground
- **Given** the player has switched to Layer 1 (Underground).
- **When** the mining action is triggered.
- **Then** the `LayerManager` must ensure only Layer 1 tiles are targeted.
- **And** physics collisions for Layer 0 and Layer 2 must be disabled.
