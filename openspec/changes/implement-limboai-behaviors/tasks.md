# Tasks: LimboAI Implementation

## 1. Setup Task Scripts (Core)
Create the reusable logic blocks in `src/systems/npc/ai/tasks/`.
- [ ] Create `BTRandomWander.gd`: Logic for picking a random point on NavMesh.
- [ ] Create `BTChaseTarget.gd`: Logic for updating NavAgent target to Player pos.
- [ ] Create `BTConditionInAttackRange.gd`: Distance check.
- [ ] Create `BTPerformAttack.gd`: Animation trigger + Damage call.

## 2. Implement Specific Behaviors (Resources)
Use the Godot Editor to create `BehaviorTree` resources (`.behtree` or `.tres`).
- [ ] Create `zombie_ai.tres`: Standard chase-and-hit logic.
- [ ] Create `slime_ai.tres`: Jump-based attack logic.
- [ ] Create `villager_ai.tres`: Wander and Flee logic.

## 3. Integration
- [ ] Update `BaseNPC.gd` to ensure `BTPlayer` is initialized correctly.
- [ ] Assign the new `.tres` resources to the `zombie.tscn`, `slime.tscn` scenes in the editor.
- [ ] Verify `Blackboard` data synchronization in `BaseNPC._physics_process`.
