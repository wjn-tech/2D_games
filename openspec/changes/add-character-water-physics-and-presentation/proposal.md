# Change: Add Character-Water Physics and Presentation

## Why
The current runtime has authoritative liquid simulation, but characters still move as if they are in air/ground-only physics. This creates a perception gap: visual water exists, yet entering water does not change movement, jump, combat readability, or feedback.

Without an explicit interaction contract, future tuning can diverge between player, NPC, and visual layers, causing inconsistent behavior and regressions.

## What Changes
- Define a character-water interaction contract for movement, buoyancy, drag, and state transitions.
- Define presentation requirements for splash/ripple/audio and waterline readability tied to interaction events.
- Define compatibility rules for existing movement/combat systems so water behavior remains deterministic and maintainable.
- Add validation scenarios for entry, submerged movement, surface transitions, and recovery to dry-state physics.

## Tech Stack
- Engine: Godot 4.5
- Language: Typed GDScript
- Runtime systems (planned integration points):
  - scenes/player.gd movement loop
  - src/systems/world/liquid_manager.gd runtime liquid query surface
  - src/core/audio_manager.gd and VFX hooks for water feedback
  - NPC CharacterBody2D controllers (phase-gated compatibility)

## Scope Boundaries
- In scope:
  - Character movement response in water (horizontal drag, vertical buoyancy, jump modulation).
  - Water entry/exit state transitions.
  - Core audiovisual presentation for water interaction.
- Out of scope:
  - Full fluid force simulation on rigid bodies.
  - Rewriting liquid solver topology or save format.
  - Multiplayer sync semantics.

## Impact
- Affected specs: character-water-interaction
- Affected code (planned):
  - scenes/player.gd
  - src/systems/world/liquid_manager.gd
  - src/core/audio_manager.gd
  - selected NPC controller scripts (compatibility pass)
- User-visible impact:
  - Movement in water has clear and consistent physical feel.
  - Entry/surface/submerged states have clear visual and audio feedback.
  - Water interaction behavior is testable and regression-resistant.
