# Spec: Spell Absorption from Kill

## Requirement: Enemy Spell Decay
#### Description: 
Enemies must decompose into pixel particles upon death instead of dropping physical loot for spells.

#### Scenario: Enemy Health Depleted
- **Given** an enemy (BaseNPC) has its health reach <= 0.
- **When** the enemy "dies".
- **Then** the `BaseNPC` visual node is hidden or removed.
- **And** a `SpellAbsorptionVFX` is spawned at its location.
- **And** the VFX begins decomposing the enemy's silhouette into particles.

## Requirement: Particle Attraction to Player
#### Description: 
Pixel particles representing the enemy's essence must fly toward and be absorbed by the player.

#### Scenario: Essence Flying
- **Given** the `SpellAbsorptionVFX` has spawned its particles.
- **When** the particles are active.
- **Then** they move toward the player character's `global_position`.
- **And** they accelerate as they get closer to the player.
- **And** they vanish upon collision with the player character's collision box.

## Requirement: Intrinsic Spell Library Learning
#### Description: 
The player learns a random, non-duplicate spell from the enemy's pool upon absorbing its essence.

#### Scenario: Learning a New Spell
- **Given** the player has absorbed an enemy's essence.
- **And** the enemy's `intrinsic_spell_pool` in `CharacterData` contains `["fireball", "ice_spike"]`.
- **And** the player already knows `"fireball"`.
- **When** the essence is absorbed.
- **Then** the player learns `"ice_spike"`.
- **And** `"ice_spike"` is added to `GameState.unlocked_spells`.
- **And** `GameState` emits the `spell_unlocked` signal.

#### Scenario: No New Spells Available
- **Given** the player has already learned all spells in the enemy's `intrinsic_spell_pool`.
- **When** the essence is absorbed.
- **Then** the visual effect still plays.
- **And** no new spell is added to `GameState.unlocked_spells`.
- **And** the player receives a small amount of mana or experience (optional/fallback).

## Requirement: Editor Synchronization
#### Description: 
Any spell learned via absorption must be immediately available for use in the Wand Editor.

#### Scenario: Workbench Library Sync
- **Given** the `WandEditor` is currently open or recently initialized.
- **When** the `GameState` emits `spell_unlocked`.
- **Then** the `WandLogicWorkbench` UI refreshes its spell node library.
- **And** the newly learned spell icon appears and can be dragged into the wand's logic grid.
