# Ultimate Spell Visuals Overhaul

## What changes
We will fundamentally upgrade the visual identity and rendering techniques of all spells to reach an "ultimate gorgeous" tier. This involves transcending simple additive particle blobs:
1. **True Darkness for Black Hole**: Implementing sub-blending (`BLEND_MODE_SUB`) and Screen-Reading shaders (`BackBufferCopy` with distortion) to create a terrifying, light-devouring void with gravitational lensing.
2. **Lightning & Arcs for Spark Bolt**: Adding dynamic `Line2D` branching lightning bolts that rapidly jitter, coupled with a 500%+ increase in particle density for chaotic electrical discharges.
3. **Continuous Godot Particle Trails**: Utilizing GPUParticles2D built-in `trail_enabled` capabilities and `Line2D` ribbons to ensure high-speed spells (Magic Bolt, Magic Arrow) look like connected, cohesive energy beams rather than disconnected dots.
4. **Sub-emitters & Physics Reactions**: Employing Godot 4 particle collisions with sub-emitters so spells like `bouncing_burst` and `slime` splash viscous droplets around upon hitting walls, while `fireball` leaves a burning soot path.
5. **Differentiated Emission Shapes and Materials**: Mixing Custom Shaders, Subtractive/Mix Blending Modes, and extreme particle counts to guarantee no two spells can be mistaken for one another.

## Why
The previous update transitioned sprites to pure particles but relied almost entirely on `BLEND_MODE_ADD` and simple gradients. This resulted in several spells still looking "plain", too sparse (like spark bolt), or fundamentally incapable of representing their concept (Black Hole cannot be "dark" when rendered with additive light). The user wants a spectacular, magical visual tier comparable to legendary VFX-heavy games. To achieve that deep oppression and magical resonance, we must combine shaders, Line2D arcs, dense sub-emitters, and mixed blend modes.

## Scope
Major extensions to `src/systems/magic/visuals/magic_projectile_visualizer.gd`, introducing `Line2D` nodes, specialized shaders (`ShaderMaterial`), and heavily modified GPUParticles2D material configurations.
