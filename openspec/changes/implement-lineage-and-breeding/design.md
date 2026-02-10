# Design: Lineage and Breeding System

## 1. Attribute System Refactor (`CharacterData`)

Current `CharacterData` uses flat floats (e.g., `strength = 10.0`).
New structure requires separating "Nature" (Genes) from "Nurture" (Leveling).

### New Schema
```gdscript
# 基础数值配置 (Const/Resource)
const BASE_STATS = {
    "strength": 10.0,
    "health": 100.0,
    ...
}
const INC_PER_WILD_LEVEL = 0.05 # 5% per wild level
const INC_PER_TAMED_LEVEL = 0.02 # 2% per tamed level

# Runtime Data
var stat_levels = {
    "strength": { "wild": 5, "tamed": 0, "mutation": 0 },
    "agility": { "wild": 3, "tamed": 2, "mutation": 0 },
    ...
}

# Mutation Counters
var mutations = {
    "patrilineal": 0, # 父系
    "matrilineal": 0  # 母系
}

# Calculated Property
func get_stat_value(stat_name: String) -> float:
    var base = BASE_STATS[stat_name]
    var levels = stat_levels[stat_name]
    var wild_mult = 1.0 + (levels.wild * INC_PER_WILD_LEVEL)
    var tamed_mult = 1.0 + (levels.tamed * INC_PER_TAMED_LEVEL)
    # 变异等级通常算作野生等级的一部分，或者独立叠加
    # 方舟逻辑：变异 = +2 野生等级
    return base * wild_mult * tamed_mult
```

## 2. Breeding Logic (`LineageManager`)

### Inheritance Algorithm
When a baby is born:
1. **Stat Selection**: For each stat, 55% chance to inherit higher wild level from parents, 45% lower.
2. **Mutation Check**:
   - Total mutation score = Father.mutations.total + Mother.mutations.total.
   - If score < 20 (on distinct lineage sides), chance for mutation (~7.3%).
3. **Mutation Effect**:
   - Select random stat.
   - Add +2 to `wild` level of that stat.
   - Increment `mutations.patrilineal` or `matrilineal` on the child.
   - Trigger color shift (future visual implementation).

### Growth System
- **Stages**: `BABY` -> `JUVENILE` -> `ADULT`.
- **Scaling**: Sprite scale scales from 0.3 to 1.0 over `growth_time`.
- **Imprinting**: Player interaction (Feed/Cuddle) increases `imprint_quality` (0-100%).
  - Effect: Bonus stats (Multiplicative), **not inherited**.
  
## 3. Interaction & Marriage

### NPC Interaction
- `SocialManager`: Tracks Affinity (0-1000).
- **Propose**:
  - Requirement: Affinity > 800 + "Town" faction.
  - Action: Set `CharacterData.spouse_id`.
- **WooHoo (Breeding)**:
  - Requirement: Married + Cooldown ready.
  - Result: Spawn `Baby` entity at NPC location.

## 4. Death & Inheritance Flow

### Death Handling
1. `Player.hp <= 0`.
2. `GameManager`:
   - Set state `GAME_OVER`.
   - Drop inventory (create `LootContainer` at player pos).
   - Pause game logic.
3. **Heir Selection UI**:
   - List all `children` from `LineageManager`.
   - Show stats/mutations comparisons.
   - "Select Heir" button.
4. **Transition**:
   - If Heir is far: `Camera` tween to Heir pos.
   - Transfer Player Control (Input) to Heir entity.
   - Heir becomes the new `Player` (Group/Tag update).
   - Old Player entity removed/ragdolled.

## 5. UI Requirements
- **Family Tree**: Graph view of ancestors.
- **Stat Inspector**: Show "Wild: 20 | Tamed: 5 | Mutation: 2".
- **Heir Selector**: Distinctive UI on death.

## 6. Developer Tools (Cheat System)

To facilitate debugging the long-cycle features:

- **Commands** (exposed via a Debug UI panel or simple keybinds):
  - `debug_set_affinity(target_npc, value)`: Instantly set relationship (e.g., 1000 for marriage).
  - `debug_force_marry(target_npc)`: Skip affinity/proposal, instant marriage.
  - `debug_spawn_baby(target_npc)`: Skip pregnancy/cooldown, instant baby at feet.
  - `debug_grow_child(target_npc, stage)`: Force set age/stage (e.g., Baby -> Adult).
  - `debug_kill_player()`: Instantly reduce HP to 0 to test inheritance UI.
  - `debug_view_genes(target_npc)`: Inspect raw Wild/Tamed/Mutation values.
