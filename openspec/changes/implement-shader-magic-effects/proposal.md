# Proposal: implement-shader-magic-effects

## Problem
The current magic effects in the project are simplistic, using static `ColorRect` visuals and basic `CPUParticles2D`. They lack the "dynamic, living" feel (Noita-style) where substances like fire, smoke, and magical energy have physical presence, turbulence, and complex visual flows.

## Solution
Implement a high-fidelity magic visual system utilizing Godot 4.5's advanced shader capabilities:
1. **GPU Particle Shaders:** Utilize `GPUParticles2D` with turbulence, custom curves, and `ParticleProcessMaterial` to create "breathable" effects for fire, smoke, and elements.
2. **Energy Flow Shaders:** Use `CanvasItem` shaders for projectile cores to implement "liquid" energy, heat haze distortion, and dissolution effects.
3. **Data-Driven Visuals:** Integrate with `ProjectileBase` to select materials based on `element` and `spell_id`.

## Impact
- **Affected Components:** `ProjectileBase`, `SpellProcessor`, `WandData`.
- **Performance:** GPU-based particles are more efficient for high counts than CPU particles.
- **Visuals:** Significantly improved magic "feel" and impact.

## Approval Critiera
- Fire spells produce turbulent fire and smoke trails.
- Magical energy projectiles (e.g., Blackhole, Teleport) have screen-distortion or flow-field shaders.
- The system remains compatible with the existing `WandEditor` logic.
