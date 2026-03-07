# Tasks: Spell Absorption on Kill

## 1. Data Schema Updates
- [ ] Add `intrinsic_spell_pool: Array[String]` to `CharacterData` (`src/systems/lineage/character_data.gd`).
- [ ] Implement `add_spell(spell_id: String)` in `GameState` (`src/core/game_state.gd`) with duplicate checking.

## 2. Enemy Interaction
- [ ] Modify `BaseNPC` (`src/systems/npc/base_npc.gd`) to handle death via `take_damage()` or by connecting to a `health_depleted` signal.
- [ ] Stop `LootItem` spawning for spells in `BaseNPC` when a spell is being "absorbed" instead.
- [ ] Implement `die()` method in `BaseNPC` that notifies the `SpellAbsorptionManager`.

## 3. Visual & Mechanics (`src/systems/magic/`)
- [ ] Create `SpellAbsorptionVFX` scene/script:
    - [ ] Burst of particles at death location.
    - [ ] Use `Curve2D` or simple `lerp()` to move toward `GameState.player_node`.
- [ ] Create `SpellAbsorptionManager` singleton:
    - [ ] `handle_npc_death(npc: BaseNPC)` - coordinates VFX and learning logic.

## 4. Wand Editor & UI Integration
- [ ] Ensure `WandEditor` workbench (`src/ui/wand_editor/wand_logic_workbench.gd`) connects to `GameState.spell_unlocked`.
- [ ] Update `WandEditor` logic to dynamically add new spell icons to the library when learned.
- [ ] Create a toast/popup notification when a new spell is learned.

## 5. Verification
- [ ] Test killing different enemies with specific spell pools (e.g., Slime -> Slime Bubble spell).
- [ ] Verify duplicates are correctly skipped.
- [ ] Confirm newly learned spells appear immediately in the Wand Editor.
