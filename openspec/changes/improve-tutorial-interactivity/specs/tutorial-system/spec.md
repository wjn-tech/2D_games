## Interactive Tutorial Capability

### Requirement: Equipment Interaction (Updated)
- **Given** new player starts the game.
- **When** the Mage dialogue reaches `<emit:wait_equip>`.
- **Then** the dialogue flow stops.
- **And** the player's movement and jumping are locked, but UI inputs (e.g., Inventory 'I') remain active.
- **And** an animated arrow points to the Inventory button or Hotbar.
- **When** the player equips a `Wand` into the primary slot.
- **Then** the dialogue resumes with the next line.
- **And** the UI arrow is removed.
- **And** the player regains movement control.

### Requirement: Visual Guidance (Arrow Indicator)

The UI system must support drawing attention to specific interface elements.

#### Scenario: Highlight First Item
- **Given** the player needs to see the new item.
- **When** the tutorial calls `highlight_inventory_slot(0)`.
- **Then** a `TutorialArrow` (animated sprite/control) appears pointing at slot 0.
- **And** the arrow persists until the objective is met.

### Requirement: Event Hooks for Core Actions

The game logic must emit signals when key player actions occur to notify the tutorial system.

#### Scenario: Crafting Success
- **Given** the player combines `wood.tres` and `stone.tres` (or similar basic components) in the crafting grid.
- **When** the `Craft` button is pressed and succeeds.
- **Then** `EventBus.item_crafted` is emitted with the item data.
- **And** the tutorial manager catches this signal to satisfy the `wait_craft` condition.

### Requirement: Interactive Elements in World (Breakable Wall)

The tutorial scene must contain interactive objects that respond to the player.

#### Scenario: Target Practice
- **Given** the player has crafted a spell.
- **When** the Mage says "Fire at the wall!".
- **Then** a `BreakableWall` object becomes active/spawned.
- **When** the player hits the target with a projectile.
- **Then** the wall plays a destruction animation/particles.
- **And** the tutorial proceeds to the crash sequence.

### Requirement: Seamless Crash Transition

The end of the tutorial must visually and logically transition directly into the main game world without a loading screen (using the existing `GameManager` logic we fixed).

#### Scenario: Crash Ends
- **Given** the ship is destructing.
- **When** the screen fades to white/black.
- **Then** the player is moved to the world spawn.
- **And** `is_new_game` flag is cleared.
- **And** the tutorial UI/Scene is deleted.
- **And** normal gameplay resumes.
