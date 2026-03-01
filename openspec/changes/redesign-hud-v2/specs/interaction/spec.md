# Spec: Interaction

## ADDED Requirements

#### Scenario: Button Feedback
- **Given** onscreen buttons (H, I)
- **When** the mouse hovers over them
- **Then** they should scale up slightly (e.g., 1.1x) or brighten.
- **When** clicked
- **Then** they should depress or shift (visual press feedback).

#### Scenario: Hotbar Feedback
- **Given** the Hotbar
- **When** a slot is selected (via numeric key)
- **Then** the slot must show a distinct highlight border or "glow" effect.
- **When** the mouse hovers a slot
- **Then** it should show a tooltip with the item name.

#### Scenario: Shortcuts Visualization
- **Given** the "H" and "I" buttons
- **Then** they should visually resemble keyboard keys (e.g., square with bottom extrusion) to imply they are shortcuts.
