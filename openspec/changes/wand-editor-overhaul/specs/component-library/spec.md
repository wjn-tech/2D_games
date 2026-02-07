# Spec: Component Library

## ADDED Requirements

### Requirement: Detailed Triggers
The palette MUST offer specific trigger types beyond the generic "Trigger".

#### Scenario: Collision Trigger
- **Given** the Logic Palette
- **When** the user searches for triggers
- **Then** "Collision Trigger" is available.
- **When** placed, it compiles to a logic node that executes its children upon projectile impact.

#### Scenario: Timer Trigger
- **Given** the Logic Palette
- **When** the user searches for triggers
- **Then** "Timer Trigger" is available.
- **When** placed, it expects a "Duration" value (default 0.5s or 'On Death').

### Requirement: Generator
The palette MUST include a "Mana Source" (Generator) as the explicit root node.

#### Scenario: Mana Source
- **Given** the user places a Generator
- **When** they connect it to triggers
- **Then** the spell compiles correctly.
