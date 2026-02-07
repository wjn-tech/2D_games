# Proposal: Combat Polish & Tactical AI

**Change ID**: `combat-juice-and-tactics`

## Summary
Overhaul the combat experience by introducing a "Game Juice" feedback system (hit stop, screenshake, VFX, floating text) and upgrading NPC AI to exhibit tactical behaviors (flanking, telegraphing, dodging) instead of simple pursuit.

## Problem
- **Lack of Impact**: Hits feel "floaty" with no clear visual/audio confirmation or physical weight.
- **Monotonous Combat**: NPCs blindly rush the player, turning combat into a stat check rather than a tactical engagement.
- **Visual Clarity**: It's hard to distinguish successful hits, blocks, or whiffs.

## Solution

### 1. Feedback System ("The Juice")
- **Hit Stop**: Global time freeze (0.05s-0.15s) on impact to sell the "weight" of the hit.
- **Visual Feedback**:
    - **Flash**: Sprites flash white/red on hit.
    - **Particles**: Directional blood/sparks based on impact angle.
    - **Floating Text**: Damage numbers with critical hit styling.
- **Screen Shake**: Dynamic camera trauma based on damage magnitude.
- **Audio**: Layered sounds for swing, hit (flesh/armor), and kill.

### 2. Tactical NPC AI
- **State Machine**: Refactor `BaseNPC` to use a strict FSM (Idle, Patrol, Alert, Flank, Attack, Stagger).
- **Behaviors**:
    - **Telegraph**: Visual/Audio cues before attacks to allow player reaction.
    - **Flanking**: Enemies try to surround the player or keep distance if ranged.
    - **Self-Preservation**: Dodging or blocking when the player initiates a heavy attack.

### 3. Combat Mechanics
- **Stamina System**: Resource management for attacks and dodges to prevent button mashing.
- **Input Buffering**: Smoother combo execution.

## Risks
- **Performance**: Excessive particle instantiation could cause stutter (use object pooling).
- **Complexity**: AI state machines can become hard to debug if not visualized.
- **Balance**: Stunlocking the player with Hit Stop or screen shake can cause motion sickness or frustration.

