# Tasks: Stabilize NPC Runtime Integrity

## 1. Runtime classification and initialization
- [x] 1.1 Move BaseNPC one-time initialization out of enemy-only helper paths and document the required initialization order.
- [x] 1.2 Correct hostile, enemy, generic NPC, and town-NPC group registration so friendly or town actors never enter hostile-only groups.
- [x] 1.3 Normalize any spawn, save/load, despawn, and door logic that currently relies on the broken classification behavior.

## 2. Combat and aggro consistency
- [x] 2.1 Update the threat-notification flow so ally help is triggered by damage-time events instead of death cleanup.
- [x] 2.2 Introduce one shared combat-target handoff contract for HSM and BT activation, including combat exit cleanup.
- [x] 2.3 Ensure already-hostile allies can refresh their target and do not immediately fall out of combat because one runtime context is missing target state.

## 3. Specialized AI ownership
- [x] 3.1 Decide the controlling AI path for SlimeNPC and remove duplicate generic combat-tree/state updates from its scene or runtime setup.
- [x] 3.2 Audit specialized hostile scenes after the ownership rule is applied to catch ai_type, behavior-tree, or scene-configuration mismatches.

## 4. Settlement and migration consistency
- [x] 4.1 Register town NPCs into the population group consumed by settlement housing, migration, and assignment systems.
- [x] 4.2 Replace migration checks that read unsupported player-data currency fields with the canonical CharacterData money field or API.
- [x] 4.3 Verify friendly town NPCs participate in settlement logic without being counted by hostile-only systems.

## 5. Validation
- [ ] 5.1 Regression-check hostile spawn counting, hostile despawn, save/load hostile restoration, and hostile-only door behavior with friendly NPCs present.
- [ ] 5.2 Regression-check combat entry, ally aggro assist, slime combat behavior, and combat exit for both fresh detection and assisted aggro.
- [ ] 5.3 Regression-check merchant arrival, housing assignment, and merchant interaction flows after the runtime contracts are repaired.
