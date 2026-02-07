# Spec: Wand Data Structure

## ADDED Requirements

#### Requirement: Wand Embryo Definition
The system must define a `WandEmbryo` resource that acts as the blueprint for wand creation.

#### Scenario: Assessing Embryo Potential
- **Given** a player has a "Tier 1 Wooden Embryo"
- **Then** its `grid_resolution` should be small (e.g., 4x4)
- **And** it should have 0 inherent attack damage (Container only).

#### Requirement: Visual Material Stats
Materials used in the visual construction of the wand must contribute to the wand's final statistics.

#### Scenario: Heavy Wand
- **Given** a wand embryo
- **When** the player fills the visual grid with [Iron Ore] blocks
- **Then** the wand's `weight` stat should increase proportionally to the count of Iron Ore.
- **And** the wand's `durability` or `defense` should increase.

#### Requirement: Wand Instance Persistence
The system must store the specific configuration of a player's wand in a `WandData` resource/dictionary.

#### Scenario: Saving a Custom Wand
- **Given** a player has painted a wand "Pink" and added "Fire Logic"
- **When** the game saves or the item is moved
- **Then** the `visual_matrix` and `logic_circuit` data must be preserved intact.
