# Design: Spell Progression & Monster Execution

## Architecture Overview

### 1. Data Management (`GameState.gd`)
-   **`unlocked_spells`**: An array of strings (spell IDs).
-   **`spell_item_data`**: New item type in `item_db` that acts as a container for a spell unlock.

### 2. Monster Logic (`BaseNPC.gd`)
-   **`execution_threshold`**: 0.2 (20% health).
-   **`is_executable`**: Boolean state based on health.
-   **`is_being_executed`**: State to handle the bind-pull-explode sequence.
-   **Execution Sequence**:
    1.  `bind()`: Disable AI, movement, and collisions.
    2.  `pull_to(player_pos)`: Use a Tween to move the NPC towards the player.
    3.  `explode()`: Play visual FX (no damage logic), emit signal for loot, and `queue_free()`.

### 3. Execution Input (`Player.gd`)
-   Add `_check_execution_targets()` in `_process`.
-   If a target is executable and in range (< 100px), show an "Execute [F]" prompt.

### 4. Loot Tables & Monster Mapping
Each monster type has specific drop associations:
-   **Slime**: Guaranteed `slime_essence`. Finisher Chance: `projectile_launcher` spell.
-   **Skeleton**: Guaranteed `bone_fragment`. Finisher Chance: `timer_trigger` spell.
-   **Combatant**: Guaranteed `scrap_metal`. Finisher Chance: `damage_modifier` spell.

### 5. UI Components
-   **`ExecutionPrompt`**: A small floating UI that appears above monsters.
-   **`UnlockNotification`**: A toast-style notification for "New Spell Discovered: [Name]".
-   **`WandEditor`**: Filter `logic_items` library to **completely hide** any ID not in `GameState.unlocked_spells`.

## UI/UX Flow
1.  Player attacks slime until HP < 20%.
2.  Icon appear above slime: "Press [F] to Execute".
3.  Player presses [F].
4.  Slime turns blue (energy bind), flies into player's hand, and pops into items.
5.  Text appears: "Acquired: Slime Essence", "Discovered Spell: Projectile Action".
6.  Player opens Wand Editor -> "Projectile Action" icon is now visible in the palette.
