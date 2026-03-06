# Spec: Design Beautiful Glow Cursors

## Capability: cursor-visuals

### MODIFIED Requirements

#### Requirement: Beautiful Glow Cursors
Replace the system-style mouse cursors with custom Aether-Punk (Magical Industrial) themed cursors featuring pre-baked "outer glow outlines" for character-rich visual feedback.

#### Scenario: Default Magical Shard Cursor
- **Given** the player is in the main tutorial or survival world
- **When** no interactive elements are hovered and no UI is focused
- **Then** the cursor icon should be a stylized "Mana Shard" (Arrow-like) with a Soft Blue Glow Outline.

#### Scenario: Interaction Glow Cursor (Talk/Open)
- **Given** the player is near an NPC or interactive object
- **When** the cursor is hovered over a "Court Mage" or "Interactive Door"
- **Then** the cursor icon should change to a "Silhouette Hand" or "Open Eye" with an Emerald Green Glow Outline.

#### Scenario: Pickup/Action Glow Cursor
- **Given** there are dropped "Loot Items" or "Gatherable Wood" on the ground
- **When** the cursor is hovered over a pickup area
- **Then** the cursor icon should change to a "Magnet" or "Clutching Hand" with a White Soft Glow Outline.

#### Scenario: Aiming/Targeting Sigil Cursor
- **Given** the player has a combat tool (e.g., Training Wand) equipped and ready
- **When** the player is aiming into the world to fire magic
- **Then** the cursor icon should change to a "Circular Magical Sigil" (Crosshair) with a Focused Red Glow Outline.
