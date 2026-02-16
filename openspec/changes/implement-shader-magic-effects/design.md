# Design: implement-shader-magic-effects

## Overview
The goal is to move from "object-based" visuals to "field-based" or "substance-based" visuals.

## GPU Particle Turbulence
We will use Godot 4.5's `GPUParticles2D` turbulence feature.
- **Fire/Smoke:** High turbulence (0.5 to 1.5), upward gravity, and scale curves that taper off.
- **Magic Trails:** Low turbulence with attraction towards the center-of-path.

## Energy Flow Shaders (CanvasItem)
Projectile cores will use a `ShaderMaterial` with the following features:
1. **Flow Mapping:** Two scrolling noise textures multiplied or added to create "interference" patterns.
2. **Fresnel-like Glow:** Edge-brightening based on distance from center.
3. **Dissolve:** Smoothstep-based erosion for "disappearing" effects.

## Screen-Space Distortions
For powerful spells like "Fireball" or "Blackhole":
- A secondary `BackBufferCopy` and a `Sprite2D` covering the projectile area will apply a distortion shader (Offset UVs by Noise).

## Resource Management
To avoid material duplication:
- We will use `MaterialProperty` overrides or specialized resource singletons to share the heavy shader logic while allowing per-instance color/speed variations.
