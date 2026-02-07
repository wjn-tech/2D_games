# Tasks

1.  **Core Data Structures**
    - [x] Create `SpellInstruction` class (Resource or simple Class).
    - [x] Create `ExecutionTier` class.
    - [x] Create `ModifierStack` helper class.
    - [x] Add `total_mana_cost` to `SpellProgram` output.

2.  **Compiler Logic**
    - [x] Implement `WandCompiler.compile(wand_data) -> SpellProgram`.
    - [x] Implement recursive graph traversal handling.
    - [x] **Validation:** Implement Cycle Detection (DFS) to reject loops.
    - [x] **Validation:** Implement Mana Cost calculation vs Wand Capacity check.

3.  **Runtime Engine**
    - [x] Refactor `SpellProcessor.cast_spell` to accept a compiled `RootTier`.
    - [x] Implement `SpellProcessor.execute_tier(tier, position, rotation)`.

4.  **Entity Updates**
    - [x] Create `ProjectileBase` class to handle movement and impact.
    - [x] Create `TriggerBase` (inherits `ProjectileBase`) for common trigger logic.
    - [x] Implement specific Trigger types as generic Projectiles with special behaviors:
        - [x] `CollisionTrigger` (Spawns on collision).
        - [x] `TimerTrigger` (Spawns on timeout, fizzles on collision).
        - [x] `DisappearTrigger` (Spawns on `tree_exiting`/death).

5.  **Integration**
    - [x] Hook `WandEditor` save to trigger re-compilation and handle errors (Cycles/Mana).
    - [x] Update `Player` input to call new `cast_spell`.
