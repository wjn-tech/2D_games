# Design: Stabilize NPC Runtime Integrity

## Context
NPC behavior is currently split across BaseNPC, LimboHSM states, behavior-tree tasks, specialized enemy scripts, spawn/save systems, and settlement population logic. The defects are not isolated implementation mistakes; they are contract mismatches between systems that all assume different answers to the same questions:

- Which NPCs are hostile, friendly, or town residents?
- When is BaseNPC considered fully initialized?
- Which runtime context owns the active combat target?
- Which controller owns movement and attack decisions for specialized enemies?
- Which group and currency source are authoritative for town migration?

## Goals
- Restore one consistent runtime classification model for hostile, generic, and town NPCs.
- Make BaseNPC initialization deterministic and independent from enemy-only data setup.
- Ensure combat entry, ally assist, and combat exit all observe the same target state.
- Eliminate duplicate AI ownership for specialized hostile actors such as SlimeNPC.
- Make settlement systems discover town NPCs and evaluate migration eligibility using supported fields.

## Non-Goals
- Rebalance combat numbers, spawn weights, or merchant prices.
- Redesign the full NPC feature roadmap.
- Replace LimboHSM or behavior trees with a different AI framework.
- Expand ecology, romance, or quest depth beyond the runtime fixes required here.

## Decisions

### Decision: Separate semantic classification from convenience groups
Runtime groups must be derived from NPC semantics, not from fallback shortcuts. Hostile-only systems should depend on hostile-specific groups. Settlement and housing systems should depend on a town-specific group. Generic discovery systems may still use a broader NPC group.

Implication:
- Friendly and town NPCs remain discoverable to interaction, housing, and world-query systems.
- Only truly hostile NPCs are counted by hostile spawn-density, hostile despawn, hostile-only door filters, and hostile save/load restoration.

### Decision: BaseNPC initialization is a fixed one-time sequence
Core initialization must not be hidden inside helper functions that only execute for certain hostile data paths. BaseNPC needs a single deterministic startup phase that always covers:
- runtime group registration
- visual/nameplate setup
- collision and interaction-layer setup
- blackboard synchronization
- HSM startup
- optional hostile-only extras such as spell-pool hydration

Implication:
- Non-hostile NPCs and enemies with prefilled data receive the same foundational setup.
- Optional enemy features can remain conditional without making the rest of the actor partially initialized.

### Decision: Combat target handoff is an explicit runtime contract
The codebase currently uses more than one blackboard/runtime context. Instead of relying on ad hoc writes, combat entry must go through one explicit contract that writes the target wherever the active combat consumers expect it before combat starts.

Recommended contract:
- Damage, perception, and ally-assist events call a shared target-assignment path.
- That path writes target state to every runtime context that participates in combat for that NPC.
- Combat exit clears target state through the same contract.

Implication:
- CombatState, BT tasks, and ally-assist flows observe the same target immediately.
- Already-hostile responders can refresh their target instead of ignoring new threats.

### Decision: Specialized enemy scenes must have a single AI owner
If a scene uses a bespoke script that performs its own perception, locomotion, and attack loop, generic HSM/BT combat trees must not simultaneously own those same decisions. Shared services from BaseNPC are acceptable, but decision ownership must be exclusive.

Implication:
- SlimeNPC either owns combat end-to-end, or it delegates fully to the generic AI stack.
- Scene configuration must reflect that choice by removing or disabling conflicting generic state trees.

### Decision: Town migration uses canonical town grouping and currency fields
Settlement logic should not depend on implicit discovery through generic NPC groups or unsupported player-data fields. Town residents must enter the population group consumed by settlement systems, and arrival thresholds must read the supported CharacterData money source.

Implication:
- Merchant arrival checks work during fresh runtime and after save/load.
- Housing scans, manual assignment, and happiness logic can locate town NPCs without special-case searches.

## Risks and Trade-offs
- Recomputing runtime groups from semantic data may change behavior for saves that accidentally relied on the current bug. Mitigation: normalize groups on scene entry or post-load reconstruction rather than preserving stale group state.
- Making target propagation explicit increases BaseNPC coordination responsibilities. Mitigation: keep the contract narrow and centered on target set/clear rather than broader AI orchestration.
- Removing duplicate slime AI ownership may reveal assumptions in custom effects or contact-damage timing. Mitigation: validate slime-specific combat feel after ownership is simplified.

## Migration Plan
1. Define and implement the classification invariants in BaseNPC startup.
2. Move all mandatory BaseNPC initialization into a single unconditional startup sequence.
3. Route combat target assignment and clearing through one shared helper contract.
4. Reconfigure SlimeNPC and any similar specialized scenes to use one AI owner.
5. Update settlement discovery and migration checks to use town_npcs and CharacterData money.
6. Run targeted runtime regressions for hostile counting, ally assist, slime combat, merchant arrival, and housing assignment.

## Open Questions
- None that block proposal drafting. The repair can proceed with the existing NPC taxonomy of Hostile, Town, and generic NPC actors.
