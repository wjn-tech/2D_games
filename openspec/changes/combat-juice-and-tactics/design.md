# Design: Combat Architecture

**Change ID**: `combat-juice-and-tactics`

## Architecture Overview

### 1. The Feedback Bus (Decoupling "Effect" from "Cause")
Instead of hardcoding particle instantiation inside `Projectile.gd` or `Sword.gd`, we introduce an Event-Driven architecture.

**Pattern**: Observer / Global Signal Bus
- **Source**: `ProjectileBase` calls `CombatBus.hit_occurred(target, info)`
- **Listener**: `FeedbackManager` (Autoload) connects to `hit_occurred`.
    - Spawns VFX.
    - Triggers Screen Shake.
    - Calls `HitStop.freeze()`.
    - Spawns Floating Text.

**Reasoning**:
- Allows easily adding new feedback (e.g., sound) without touching projectile code.
- Centralizes performance tuning (e.g., limit max particles in Manager).

### 2. NPC State Machine (Explicit States)
We move from `_process` based "if-else spaghetti" to a strict Finite State Machine.

**Structure**:
```
NPC (CharacterBody2D)
└── StateMachine (Node)
    ├── Idle (State)
    ├── Chase (State)
    ├── Attack (State)
    └── Stagger (State)
```

**Tactics Implementation**:
- **Flanking**: `Chase` state calculates a `target_position` that is NOT `player.global_position`, but `player.global_position + offset.rotated(angle)`.
- **Telegraphing**: `Attack` state has `enter()` -> play animation -> `timer` -> activate hitbox.

### 3. Poise & Stamina Components
Using Composition over Inheritance.
- `StaminaComponent`: Manage regen/decay.
- `PoiseComponent`: Manage stagger threshold.
Any entity (Player or Boss) can have these by adding the node.
