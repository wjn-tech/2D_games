# Design: Spell Absorption System

## Overview
This system replaces traditional physical spell loot with a magical "absorption" mechanic. When an enemy is killed, its essence (represented as pixels) decomposes and flies toward the player, who then "learns" a new spell from the enemy's innate knowledge.

## Subsystems

### 1. Spell Pool Definition
We will add a new field to `CharacterData` called `intrinsic_spell_pool`. 
- Type: `Array[String]` (Spell IDs)
- Usage: When an enemy dies, we pick a random ID from this pool that is NOT in `GameState.unlocked_spells`.

### 2. Absorption VFX (`src/systems/magic/vfx/spell_absorption_vfx.gd`)
- Responsibilities:
  - Generate a burst of particles at the enemy's death location.
  - Animate particles moving toward the player's position.
  - Scale with enemy size.
  - Signal completion when the "core" essence reaches the player.

### 3. Spell Absorption Manager (`src/systems/magic/spell_absorption_manager.gd`)
- Responsibilities:
  - Global singleton or helper that coordinates death signals and VFX.
  - Handles the library update logic:
    ```gdscript
    func absorb_from_npc(npc: BaseNPC):
        var pool = npc.npc_data.intrinsic_spell_pool
        var new_spells = pool.filter(func(id): return !GameState.unlocked_spells.has(id))
        if new_spells.size() > 0:
            var spell_id = new_spells.pick_random()
            GameState.unlocked_spells.append(spell_id)
            GameState.spell_unlocked.emit(spell_id)
        # Always trigger VFX even if no new spell
        spawn_vfx(npc.global_position)
    ```

### 4. Integration with Wand Editor
- Currently, `WandEditor` reads `GameState.unlocked_spells` to populate its "Spell Library".
- We need to ensure that the `spell_unlocked` signal correctly triggers a UI refresh without requiring a scene restart.

## Trade-offs
- **Duplicate Prevention**: If a player has learned everything, they get nothing new. We might add a small "Mana Refill" or "Experience" reward to avoid the "empty kill" feeling.
- **VFX Performance**: If many enemies die at once, many particles will be flying. We should limit the number of active absorption VFX instances.
