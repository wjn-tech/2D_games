# Capability: AI State Machine

Requirements for NPC logic handling.

## ADDED Requirements

### Requirement: Combat Transition
NPCs SHALL transition to Combat state when a target is detected.
#### Scenario: Spotted Player
- GIVEN a neutral NPC
- WHEN the player enters its vision cone
- THEN it MUST transition to the `Chase` state.
