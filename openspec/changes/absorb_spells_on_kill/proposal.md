# Proposal: Absorb Spells on Kill

## Context
Currently, when enemies are killed, they may drop spells as physical block items. This does not align with the desired magical fantasy where the player "learns" from defeated foes. We want to replace physical loot with a pixel-based absorption effect that grants new spells directly to the player's library.

## Objectives
- Replace physical spell loot blocks with a "soul-like" pixel absorption effect.
- Implement a system where killing an enemy triggers a decomposition into particles that fly toward the player.
- Upon absorption, the player learns a random spell from the enemy's possible loot pool.
- Ensure duplicate prevention (player only learns spells they don't already have).
- Ensure every enemy has a defined spell pool.
- Integrate learned spells into the Wand Editor as functional components.

## Proposed Changes
1. **Enemy System**: 
   - Add `spell_pool` (Array of Spell IDs) to `CharacterData` or `BaseNPC`.
   - Override `die()` or `take_damage()` to trigger the `SpellAbsorptionManager` instead of spawning `LootItem`.
2. **Visual Effect**:
   - Create a `PixelAbsorptionVFX` that spawns at the enemy's death position.
   - Particles move toward the player using an attractor or lerp logic.
3. **Player Data**:
   - `GameState.unlocked_spells` will be checked and updated.
   - Display a notification/toast when a new spell is learned.
4. **Wand Editor**:
   - Ensure the UI refreshes to show newly unlocked spell nodes in the workbench.

## Design Decisions
- **VFX Implementation**: Use a `GPUParticles2D` or a custom `Node2D` with light-weight `Sprite2D` particles for better control over the "flying towards player" pathing.
- **Spell Pool**: Define a default spell pool for all enemies, with specific pools for different enemy types (e.g., Slimes might give "Acid Splash", Fire Elementals give "Fireball").
- **Exclusivity**: If a player has learned all spells in an enemy's pool, falling back to a "Mana Crystal" or just the visual effect without a new spell.
