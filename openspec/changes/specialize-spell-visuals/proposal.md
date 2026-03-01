# Specialize Spell Visuals

## What changes
We will fundamentally differentiate the aesthetic behavior, color curves, and physics properties of each spell type's particle emitters in `MagicProjectileVisualizer`. Instead of simply tweaking speeds and scales of white particles, we will introduce customized `color_ramp` gradients that transition from bright HDR cores to deeply saturated, distinct base colors (e.g., deep orange for fireballs, bright neon green for bouncing bursts). We will also introduce unique emission shapes, tangential accelerations (for spiraling/erratic movement), and distinct gravity/damping properties so that each spell "feels" like a different state of matter (gas, plasma, solid sparks, slime).

## Why
Currently, because all spells utilize extremely high HDR brightness (`Color(x, y, z)` with values > 1.0) combined with additive blending, the differences in particle spread and speed are overshadowed by the fact that they all clip to "pure white" on the screen. The user describes the result as "just white particles moving at different speeds". In order to convey the intended Noita-like spell variety, we must ensure the core can be bright, but the dissipating trails and surrounding halo pixels exhibit strong, distinct chromatic identities and physical behaviors (e.g., smoke rising vs. slime dripping).

## Scope
Affects `src/systems/magic/visuals/magic_projectile_visualizer.gd` and `src/systems/magic/visuals/magic_particle_factory.gd`. No changes to hitboxes, projectile logic, or game data.