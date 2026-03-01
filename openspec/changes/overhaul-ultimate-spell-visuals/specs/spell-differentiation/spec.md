# Spell Differentiation Strategy

## ADDED Requirements

### Requirement: Archetype-Based Visual Differentiation
All spells MUST be strictly categorized into one of five baseline visual archetypes (Energy, Fluid, Plasma, Electric, Void), which dictates their blend mode, node structure (e.g., Line2D vs GPUParticles2D), and baseline physics (gravity vs. linear).
#### Scenario: Observing varied spell archetypes
When the user tests different spells side-by-side, they MUST exhibit non-overlapping structural rules. For example, Slime (Fluid) MUST use opaque mix-blending with heavy gravity, while Magic Bolt (Energy) MUST use additive continuous trails with strictly linear zero-gravity movement.

### Requirement: Unique Signature Parameters Within Archetypes
Spells belonging to the same archetype MUST implement distinct signature parameters (e.g., color gradients, scale curves, particle density, or sub-emitter configurations) to ensure no two spells look identical.
#### Scenario: Distinguishing Magic Bolt from Magic Arrow
When Magic Bolt and Magic Arrow (both Energy archetypes) are fired simultaneously, Magic Bolt MUST appear as a thick, dense cyan-white comet, whereas Magic Arrow MUST appear as a razor-thin, highly elongated, and faster violet needle.

### Requirement: Comprehensive Projectile Coverage
Every instantiable `projectile_id` mapped in the game data MUST have a bespoke entry in the `MagicProjectileVisualizer`'s differentiation matrix. Fallbacks (`_`) MUST NOT be used for any named game spells.
#### Scenario: Firing a newly introduced spell
When the user casts any supported logic spell like `tri_bolt`, `energy_sphere`, or `cluster_bomb`, the visualizer MUST load a specific, visually unique profile for it rather than defaulting to generic white particles.