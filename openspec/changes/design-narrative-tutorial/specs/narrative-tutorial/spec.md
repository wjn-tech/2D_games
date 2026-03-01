# Spec: Narrative Tutorial Component

## ADDED Requirements

### Requirement: Tutorial Sandbox Isolation
The game MUST transition new players starting a new save into a closed 	utorial_spaceship.tscn sandbox before dropping them into the main world.

#### Scenario: Launching a new game
- When a player clicks "New Game".
- Then instead of main.tscn, 	utorial_spaceship.tscn is loaded.

### Requirement: Player Movement Lock
The player character MUST be locked in a frozen or cinematic state, preventing arbitrary movement while the tutorial is ongoing.

#### Scenario: Spawning into tutorial
- When the tutorial scene initializes.
- Then player directional inputs are ignored or disabled.

### Requirement: Lore Exposition Prompt
A "Court Mage" NPC MUST deliver dialogue automatically upon entering the tutorial scene outlining the game's lore: the Star Sea origins, the stolen magic, and the imperative to reclaim the magic to rebuild the kingdom.

#### Scenario: Entering the spaceship
- When the player gains control in the tutorial room.
- Then the Mage begins a dialogue tree detailing the history of the falling kingdom and the starship's mission to dive into the monster-infested world to reclaim their stolen powers.

### Requirement: Dialogue Signal Extension
The existing dialogue manager MUST support parsing and emitting custom signals during specific text nodes.

#### Scenario: Hooking logic to dialogue
- When the dialogue parser reads a tag like [signal=give_items].
- Then the respective engine signal is fired so external scripts can react synchronously.

### Requirement: Dynamic Item Dispensation
The tutorial NPC MUST inject starting items (wand components, crafting materials) into the player's inventory mid-conversation as a desperate act of "salvaging before the crash".

#### Scenario: Preparing for instruction
- When the dialogue hits the dispensation node emphasizing the urgency of survival.
- Then the signal triggers InventoryManager.add_item() with predefined tutorial resources.

### Requirement: Submersive Turbulence
The camera MUST periodically shake to simulate ship turbulence during the dialogue.

#### Scenario: Scripted Rumble
- When specific dialogue nodes are active or timed intervals are reached (indicating monster anti-air fire).
- Then the script issues camera offsets to create a rumble effect.

### Requirement: Guided UI Validation - Magic
The UI manager MUST forcefully open the Wand Editor UI during the magic explanation phase and MUST force the player to construct a valid spell before proceeding.

#### Scenario: Injecting Magic knowledge
- When the NPC states "Take the last surviving wand core, we use magic to fight!" 
- Then the Wand Editor opens.
- When the player attempts to close the editor.
- Then the system checks if a valid spell is slotted; if false, it blocks closure or re-prompts the player. If true, the tutorial proceeds.

### Requirement: Guided UI Validation - Crafting
The UI manager MUST forcefully open the Inventory UI during the crafting phase for an interactive tutorial.

#### Scenario: Injecting Crafting knowledge
- When the NPC states "Our supplies are gone. We must craft items in our backpacks from whatever is left!" 
- Then the Inventory crafting tab opens for the player to utilize the granted materials.

### Requirement: Actionable Tutorial Skip
The system MUST provide a skip shortcut that immediately terminates the teaching sequence and transitions to the crash finale.

#### Scenario: Player presses ESC
- When a player holds or presses the skip button (e.g., ESC) during the tutorial.
- Then the dialogue closes, UI resets, and the catastrophic crash sequence starts immediately.

### Requirement: Cinematic Crash End Phase
The tutorial MUST conclude with a catastrophic screen effect representing the ship crashing violently onto the planet surface.

#### Scenario: Impact
- When the Tutorial Dialogue tree finishes naturally or is skipped.
- Then a massive camera shake triggers, followed by a Tween that fades a fullscreen ColorRect to black.

### Requirement: Payload Transition Output
Following the crash fade-to-black, the application MUST load the main game world with the player character retaining the tutorial knowledge/starter items.

#### Scenario: Transition to world
- When the screen goes to 100% black due to the crash fade effect.
- Then get_tree().change_scene_to_file("res://scenes/main.tscn") is executed, and the player drops into the starting biome to begin rebuilding the kingdom.
