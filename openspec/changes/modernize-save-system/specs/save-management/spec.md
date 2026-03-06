# Spec: Modernize Save System

## Capability: save-management

### MODIFIED Requirements

#### Requirement: Binary Secure Saving
Transition the existing save system from a mixed JSON/Text approach to a compressed binary format with built-in recovery and backup functionality.

#### Scenario: Atomic Save Completion
- **Given** the player triggers a manual or automatic save
- **When** the `SaveManager` writes data
- **Then** it should write to a temporary file (`.tmp`) first, then rename it to the actual save file only after successful completion, ensuring no corrupted fragments remain on failed writes.

#### Scenario: Backup Recovery fallback
- **Given** a save file exists but the user's game crashed mid-save, or the data became corrupt
- **When** the game attempts to load that slot
- **Then** the `SaveManager` should detect the `FileAccess` failure or checksum mismatch and offer to load from the `.bak` (previous successful) file.

#### Scenario: Visual Save Previews (Thumbnails)
- **Given** a new save is performed
- **When** the data is written to disk
- **Then** a 320x180 resolution JPG screenshot of the current viewport should be saved alongside the data to provide visual context in the load menu.

#### Scenario: Full World World State Persistence
- **Given** the player has left dropped items (Pickups) on the ground and explored far away
- **When** saving the game
- **Then** all nodes in the `pickups` group and the current "Fog of War" mask should be serialized into the binary file.

#### Scenario: Lineage Metadata Grouping
- **Given** multiple saves across different family generations
- **When** viewing the Load Game menu
- **Then** saves should be metadata-enriched with `lineage_id` and `generation_level` for structured sorting.
