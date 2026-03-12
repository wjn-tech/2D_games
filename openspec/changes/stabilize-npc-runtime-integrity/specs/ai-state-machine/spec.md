## MODIFIED Requirements

### Requirement: Combat Transition
NPCs SHALL transition to Combat only after writing a valid target into the runtime context consumed by the combat state and any active combat behavior tree.

#### Scenario: Detection-driven combat entry
- GIVEN an NPC detects a player or other hostile target
- WHEN detection logic initiates combat
- THEN the combat target MUST already be available on the first combat update tick
- AND any combat behavior tree activated for that state MUST read the same target reference

#### Scenario: Ally-assist combat entry
- GIVEN a nearby ally requests help against an attacker
- WHEN the NPC joins the fight
- THEN the NPC MUST store the attacker as its combat target before dispatching combat entry
- AND it MUST NOT immediately fall back to threat_cleared because one runtime context is missing target state

## ADDED Requirements

### Requirement: Specialized AI Ownership
A specialized NPC controller SHALL have a single owner for perception, locomotion, and attack decisions.

#### Scenario: Custom hostile controller
- GIVEN an NPC scene uses a custom script with its own combat loop
- WHEN the scene is configured for runtime
- THEN generic HSM or behavior-tree combat updates MUST be disabled or omitted for that NPC
- AND the NPC MUST NOT run duplicate combat decision loops in parallel
