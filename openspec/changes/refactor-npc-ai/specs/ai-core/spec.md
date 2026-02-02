# Spec: AI Core Integration

## ADDED Requirements

### Req: Hierarchical Orchestration (HSM)
The AI system must use a LimboHSM to manage high-level states.

#### Scenario: State Transition on Threat
- **GIVEN** an NPC in the `IdleState`.
- **WHEN** the Blackboard variable `current_threat` is populated.
- **THEN** the HSM transitions to `CombatState`.

## MODIFIED Requirements

### Req: BlackBoard Integration
NPC persistent data must be accessible to Behavior Trees via the LimboAI Blackboard.

#### Scenario: Sync CharacterData
- **GIVEN** an active `BaseNPC` with `CharacterData` assigned.
- **WHEN** the `BTPlayer` begins execution.
- **THEN** variables such as `alignment`, `speed`, and `role` from `CharacterData` are automatically synchronized to the Blackboard.

### Req: Layer-Aware Sensing
AI sensing must respect the project's multi-layer system.

#### Scenario: Layer Matching
- **GIVEN** a potential target on Layer 1.
- **AND** the NPC is on Layer 0.
- **WHEN** the `CheckTarget` task evaluates.
- **THEN** it returns FAILURE because the layers do not match.
