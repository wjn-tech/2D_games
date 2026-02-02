# Proposal: Character Attribute Engine

Establish a robust, data-driven system for character stats, leveling curves, and state management.

## Why
A sandbox RPG requires a deep attribute system (Strength, Lifespan, etc.) that can scale across generations and affect combat formulas.

## Proposed Changes
1.  **Attribute Scaling**: Implement non-linear growth curves for primary stats.
2.  **State Machine (FSM)**: Standardize character states (Idle, Move, Attack, Dead) to ensure consistent behavior.
3.  **Combat Formula Core**: Create a centralized module to calculate damage based on strength vs. defense.

## Impact
- **Consistency**: All entities (Player/NPC) use the same attribute logic.
- **Progression**: Provides the foundation for the lineage system inherited stats.

## Acceptance Criteria
- [ ] Character attributes (STR, DEX, HP) are visible in an editor inspector/UI.
- [ ] Leveling up increases stats according to a defined Resource-based curve.
