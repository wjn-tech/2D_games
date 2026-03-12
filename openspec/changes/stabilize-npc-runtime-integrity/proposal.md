# Change: Stabilize NPC Runtime Integrity

## Why
Current NPC and hostile-creature behavior violates its own architecture in several places: friendly and town NPCs can enter hostile-only runtime groups, core BaseNPC initialization only completes for a subset of enemies, aggro propagation writes targets into inconsistent blackboards, SlimeNPC runs a bespoke controller in parallel with generic combat trees, and settlement migration depends on group assignments and currency fields that are not consistently valid at runtime.

These defects cascade across spawning, save/load, combat entry, hostile despawn, housing assignment, and door filtering. The project needs one scoped repair proposal that restores consistent runtime contracts before more NPC content is layered on top.

## What Changes
- Define runtime classification invariants for hostile, generic, and town NPC groups.
- Require BaseNPC core initialization to run exactly once for every NPC instance, independent of spell-pool population or enemy-only branches.
- Define a single combat-target handoff contract between damage events, faction assist logic, the state machine, and behavior trees.
- Require specialized NPC controllers to have clear ownership over perception, locomotion, and combat so duplicate AI loops cannot run in parallel.
- Require settlement migration and housing systems to consume the canonical town-NPC group and the canonical player currency source.

## Impact
- Affected specs: ai-state-machine, npc-runtime-integrity, settlement-population
- Affected code: src/systems/npc/base_npc.gd, src/systems/npc/faction_manager.gd, src/systems/npc/slime_npc.gd, scenes/npc/slime.tscn, scenes/npc/merchant.tscn, scenes/npc/princess.tscn, src/systems/npc/npc_spawner.gd, src/core/save_manager.gd, src/systems/settlement/settlement_manager.gd, src/systems/lineage/character_data.gd, src/systems/world/interactive_door.gd
- Affected behavior: hostile counting and despawn, ally aggro assist, slime combat ownership, town migration eligibility, housing assignment, and friendly-vs-hostile filtering in shared world systems
