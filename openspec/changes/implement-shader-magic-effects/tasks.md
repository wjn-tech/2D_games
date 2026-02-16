# Tasks: implement-shader-magic-effects

## Phase 1: Infrastructure & Resources
- [ ] Create base shader files for magic effects (`magic_energy.gdshader`, `element_fire.gdshader`).
- [ ] Create common `ParticleProcessMaterial` resources for base elements (Fire, Ice, Slime).
- [ ] Implement `MagicVisualManager` (autoload or static utility) to cache and provide materials.

## Phase 2: Projectile System Upgrade
- [ ] Refactor `ProjectileBase.gd` to use `GPUParticles2D` as the primary visual component.
- [ ] Update `_add_elemental_effect` to apply GPU-based materials.
- [ ] Add `ShaderMaterial` support to the projectile's main visual (Sprite2D or custom Polygon2D).

## Phase 3: "Noita-Style" Effects Implementation
- [ ] Implement turbulence logic in particle shaders to simulate "living" air/movement.
- [ ] Implement energy flow shader with time-based distortion for arcane projectiles.
- [ ] Implement heat distortion (screen-space) for fire-based magic.

## Phase 4: Integration & Tuning
- [ ] Map existing spell IDs (`projectile_tnt`, `projectile_slime`, etc.) to new high-quality visuals.
- [ ] Optimize particle counts for performance balance.
- [ ] Validate visual consistency in the `WandEditor` simulation.
