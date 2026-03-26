## ADDED Requirements

### Requirement: NPC Classification Integrity
Runtime group membership SHALL reflect npc_data semantics and MUST isolate hostile-only systems from friendly or town NPCs.

#### Scenario: Friendly or town NPC initialization
- GIVEN a merchant, princess, or other non-hostile NPC enters the world
- WHEN its runtime initialization completes
- THEN it MUST join the generic discovery groups required for interaction and settlement systems
- AND it MUST NOT join hostile_npcs or any hostile-only runtime group

#### Scenario: Hostile NPC initialization
- GIVEN a hostile creature enters the world
- WHEN its runtime initialization completes
- THEN it MUST join hostile_npcs and other hostile combat groups
- AND systems that count, despawn, save, or filter hostile actors MUST only observe true hostiles

### Requirement: Base Initialization Completeness
Every BaseNPC instance SHALL complete core initialization exactly once regardless of spell-pool hydration or other enemy-specific helper paths.

#### Scenario: Non-hostile startup
- GIVEN a non-hostile NPC with no intrinsic spell-pool setup path
- WHEN the node enters the tree
- THEN nameplate setup, interaction-layer setup, blackboard synchronization, and HSM initialization MUST still occur

#### Scenario: Hostile startup with prefilled data
- GIVEN a hostile NPC whose intrinsic spell pool is already populated
- WHEN the node enters the tree
- THEN the NPC MUST still complete the same core initialization sequence exactly once

### Requirement: Damage-Time Aggro Broadcast
Faction assist notifications SHALL originate from damage-time threat events rather than post-death cleanup.

#### Scenario: Ally takes damage
- GIVEN an NPC is damaged by an attacker
- WHEN nearby allies are eligible to assist
- THEN the help broadcast MUST occur at damage time
- AND the damaged NPC's faction or alignment MUST be used to filter responders
