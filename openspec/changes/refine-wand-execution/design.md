# Design: Recursive Spell Execution

## Architecture

### 1. The Compilation Phase
We transform the `WandData` logic nodes into a `SpellProgram` Resource or Dictionary structure. This happens when closing the editor or saving the wand.

#### Validation Steps
Before generating instructions, we run strict checks:
1.  **Cycle Detection:** Perform a DFS/Tarjan's algorithm. If a cycle is detected, **compilation fails** with an error. Loops are not allowed.
2.  **Mana Capacity Check:**
    *   Wands have a `mana_capacity` property.
    *   Every Node (Spell/Modifier) has a `mana_cost`.
    *   Calculate `total_cost = sum(node.cost for node in graph)`.
    *   If `total_cost > wand.mana_capacity`, **compilation fails**.

#### Traversal Algorithm
1.  **Start** at the "Mana Source" (input slots).
2.  **Traverse** outwards.
3.  **Accumulate Modifiers**: Add modifiers to a transient `ModifierStack`.
    *   **Strict Scoping**: Modifiers in the stack apply **only** to the immediate Action or Trigger node they precede. They are **cleared** (or not passed down) when entering the `child_tier` of a Trigger.
4.  **Terminate at Effect**:
    *   **Blast (Action):** Allow the path to end. Create a `SpellInstruction` with the accumulated modifiers and the specific Blast type.
    *   **Trigger (Control):** Create a `TriggerInstruction`. **Recurse** from this Trigger node's output to build the `child_tier`. The `child_tier` starts with a fresh/empty Modifier stack (unless specific "Global Modifiers" are designed later).

### 2. Data Structures

```gdscript
# The compiled output
class SpellProgram:
    var root_tier: ExecutionTier
    var total_mana_cost: float
    var is_valid: bool

class ExecutionTier:
    var instructions: Array[SpellInstruction]

class SpellInstruction:
    var type: String # "PROJECTILE", "TRIGGER_TIMER", "TRIGGER_COLLISION", "TRIGGER_DEATH"
    var params: Dictionary # Speed, Damage, Duration
    var modifiers: Array[ModifierData]
    var child_tier: ExecutionTier # For Triggers only
```

### 3. Runtime execution ("Wand Use")
1.  **Cast:** Player Input -> `Wand.use()`.
2.  **Execution:** `SpellProcessor.execute_tier(program.root_tier, origin, direction)`.
3.  **Resource:** Wand enters `recharge_time`. (Mana is treated as a static capacity constraint, not a per-shot resource drain, based on current requirements).

### 4. Projectile & Trigger Logic
All "Spells" are entities (Projectiles).
*   **Blast:** A standard projectile. Deals damage, applies modifiers, queue_free on impact.
*   **Triggers:** These are *also* projectiles (visible or invisible, physical).
    *   **Collision Trigger:**
        *   Behavior: Flies like a bullet.
        *   On Collision: Spawns `child_tier` at impact point, then dies.
        *   On Timeout/Range: Dies *without* spawning (fizzles).
    *   **Timer Trigger:**
        *   Behavior: Flies like a bullet.
        *   On Timer Reached: Spawns `child_tier` at current location, then dies.
        *   On Collision (before timer): Dies *without* spawning (destroyed).
    *   **Disappear ("On Death") Trigger:**
        *   Behavior: Flies like a bullet.
        *   On `tree_exiting` (Hit OR Timer OR Cancelled): Spawns `child_tier` at last known location.

## Edge Cases
- **Mana Limit Exceeded:** The editor UI must prevent adding nodes if the bar is full, or prevent saving.
- **Strict Modifiers:** If I put "Fire" before a "Timer Trigger", the *Timer Bullet itself* is on fire (maybe deals contact damage). The *Child Bullet* (that appears later) is NOT on fire, unless I put another Fire modifier *after* the Timer node in the graph.

