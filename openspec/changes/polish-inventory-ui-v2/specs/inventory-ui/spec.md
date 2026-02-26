# Inventory UI Specification (New)

**Spec**: `polish-inventory-ui-v2`
**Status**: draft
**Priority**: high

## ADDED Requirements

### Requirement: Layout
The inventory UI SHALL use a three-column layout (Left: Stats/Equip, Center: Grid/Hotbar, Right: Details/Trash) to match the reference design.
#### Scenario: Basic Layout Structure
- **Given** I open the character panel (default key 'I')
- **Then** I see the Stats Panel on the left, the Inventory Grid in the center, and the Detail Panel on the right.
- **And** I see a prominent Header bar at the top displaying current resources (Gold, Diamond, Magic).

### Requirement: Stats Visualization
The UI SHALL display character statistics (STR, AGI, INT, CON) clearly on the left panel.
#### Scenario: Stats Visualization
- **Given** I have 10 STR
- **Then** I see a "STR" block in the left panel with the icon for Strength and the value "10".

### Requirement: Equipment Visualization
The UI SHALL display equipment slots for Head, Body, Hands (Main/Off), Feet, and Accessory.
#### Scenario: Equipment Visualization
- **Given** I have a Sword equipped in the Main Hand
- **Then** I see the Main Hand slot populated with the Sword icon.
- **And** The other slots display a faint "ghost" icon indicating their purpose (e.g., helmet outline for Head).

### Requirement: Trash Zone
The UI SHALL provide a distinct Trash area for deleting items.
#### Scenario: Deleting an Item
- **Given** I drag an item from the inventory grid
- **When** I drop it onto the "Trash" area in the bottom right
- **Then** The item is removed from the inventory.
- **And** A confirmation tooltip or visual feedback appears (optional but recommended).

### Requirement: Cross-Slot Drag and Drop
The implementation SHALL support drag-and-drop between all compatible slots (Backpack <-> Hotbar <-> Equipment <-> Trash).
#### Scenario: Cross-Slot Interaction
- **Given** I have a potion in the backpack
- **When** I drag it to the Hotbar slot
- **Then** The potion is moved/copied to the Hotbar (depending on logic).
- **When** I drag it to an incompatible Equipment slot (e.g., Sword slot)
- **Then** The drop is rejected.
