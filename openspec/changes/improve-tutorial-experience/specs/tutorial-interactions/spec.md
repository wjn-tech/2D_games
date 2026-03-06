# Spec: Improved Tutorial Interactions

## ADDED Requirements

### Requirement: Enhance opening cinematic
The opening sequence MUST establish a tense atmosphere before dialogue begins.

#### Scenario: Opening Cinematic
> **Given** the tutorial scene starts,
> **When** the `_ready` function runs,
> **Then** the screen should shake (Camera2D offset noise).
> **And** a red overlay (CanvasModulate/ColorRect) should flicker to simulate an emergency.
> **And** after 2 seconds, the first dialogue ("State: CRITICAL...") should appear.

### Requirement: Verify active movement
The player MUST prove they can move the character freely before the step completes.

#### Scenario: Meaningful Movement Check
> **Given** the player is in the `MOVEMENT` phase,
> **When** the player presses movement keys (WASD),
> **Then** the player character should visibly move on screen.
> **And** the tutorial should NOT advance until the player has moved at least 50 pixels from the start position.
> **And** the movement controls should remain unlocked until the required distance is covered.

### Requirement: Guide inventory usage visually
A helper cursor MUST demonstrate interaction steps for the inventory.

#### Scenario: Visual Inventory Guidance
> **Given** the player reaches the `INVENTORY` phase,
> **When** the dialogue instructs to "Open your inventory",
> **Then** a ghost mouse cursor should demonstrate moving the mouse to the inventory button (or key prompt).
> **When** the inventory is open and the instruction is "Drag wand to hotbar",
> **Then** a ghost mouse cursor should demonstrate dragging the Wand item from the backpack slot to the first hotbar slot repeatedly.

### Requirement: Teach wand programming logic
The tutorial MUST teach the correct logical flow (Source -> Projectile) and ensure a clean slate.

#### Scenario: Wand Logic Programming Flow
> **Given** the player reaches the `PROGRAM` phase,
> **When** the dialogue instructs to "Open the Logic Interface (K)",
> **Then** the tutorial waits for the `wand_editor_opened` event.
> **When** the editor opens, if the wand contains pre-existing logic,
> **Then** the logic grid should be cleared (reset to empty).
> **And** the ghost mouse should demonstrate dragging a **Generator** (Mana Source) from the palette to grid position (1,1).
> **When** the generator is placed,
> **Then** the ghost mouse should demonstrate dragging a **Projectile** from the palette to grid position (3,1).
> **When** both nodes are placed,
> **Then** the ghost mouse should demonstate dragging a connection wire from the Generator's output to the Projectile's input.
> **When** the connection is made,
> **Then** the tutorial advances to the `COMBAT` phase.

### Requirement: Improve transition to gameplay
The transition from tutorial to the main game MUST be seamless and dramatic.

#### Scenario: Crash Transition
> **Given** the player breaks the wall in the `COMBAT` phase,
> **When** the dialogue reaches "TOO LATE! BRACE FOR IMPACT!",
> **Then** a strong screen shake should occur.
> **And** the screen should fade to white/black over 2 seconds.
> **And** the player should be teleported to the main world spawn point.
> **And** the screen should fade back in.
> **And** the tutorial scene should be removed from the tree.
