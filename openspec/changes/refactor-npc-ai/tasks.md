# Tasks: Deep NPC AI Refactor

## Phase 1: Actor & Navigation Setup
- [X] Verify LimboAI in `res://addons/`.
- [ ] Add `NavigationAgent2D` to `res://NPC.tscn`.
- [ ] Refactor `BaseNPC.gd`:
    - Clean up `State` enum and old `_process_state` logic.
    - Implement `move_along_path(destination)` and `stop_movement()`.
    - Implement `sync_data_to_blackboard()` method.

## Phase 2: Hierarchy & Environment Perception
- [ ] Implement `LimboHSM` on `BaseNPC`.
- [ ] Create `EnvironmentalSensor` component:
    - [ ] Sync `Weather`, `Time`, and `Biome` to Blackboard.
    - [ ] Implement nearby NPC detection for affinity logic.
- [ ] Create core HSM States: `WanderState.gd`, `CombatState.gd`, `HomeState.gd`.

## Phase 3: Behavior Integration & Tasks
- [ ] Implementation of custom Tasks:
    - Action: `BTSelectDialogue` (Picks string based on environment blackboard).
    - Condition: `BTCheckHappiness` (Evaluates affinity/neighbors).
    - Action: `BTNavigateTo` (Uses `NavigationAgent2D`).
- [ ] Draft Behavior Trees: 
    - [ ] `citizen_wander.bt`: Includes random walking and stopping to "contemplate".
    - [ ] `citizen_night_routine.bt`: Pathing to `home_pos` and locking doors.
    - [ ] `citizen_socialize.bt`: Moving towards liked neighbors to trigger "chat" icons.

## Phase 4: Data-Driven Role Injection
- [ ] Update `CharacterData` to include a reference to a `BehaviorTree` or `LimboHSM` configuration.
- [ ] Fix `InfiniteChunkManager` to inject the new AI components when spawning NPCs.

## Phase 5: Testing & Validation
- [ ] Test NPC pathfinding around player-built structures.
- [ ] Validate HSM state switching (e.g., Villager stopping work to flee from a monster).
- [ ] Verify multi-layer consistency (NPCs shouldn't "see" targets on other layers).
