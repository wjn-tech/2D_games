# Refactor Magic VFX System

## Modification Plan
The current magic VFX system has been criticized for being "disjointed", "low fidelity", and "lacking interaction". The user wants to unify the visual style with the pixel art world while maintaining high-fidelity HDR colors (Glow).
The core issue is that the current implementation (Line2D + loose particles) looks like "vector art floating on top of pixel art" and lacks "juice" (impact, anticipation, trails).

### Constraint: Strict Functional Preservation
- **Zero Logic Changes**: Physics, damage, homing, bouncing, and element application logic will be preserved verbatim.
- **Zero Color Changes**: The specific HDR colors used in the original file will be extracted to `MagicPalette` and reused exactly.
- **Minimal Invasion**: The only change to `ProjectileBase` will be replacing the rendering lines (Line2D/Particles) with `visualizer.update(state)`.

### Goals
1.  **Pixel-Perfect High-Fidelity**: Use Shaders to enforce pixel grid alignment on existing high-fidelity effects.
2.  **Visual Componentization**: Move rendering code to `MagicProjectileVisualizer`.
3.  **Juice**: Add Muzzle Flash and Impact Explosion (purely visual additions).

### Scope
- **New Component**: `MagicProjectileVisualizer`.
- **New Assets**:
    - Pixel-art projectile cores (AnimatedSprite2D frames).
    - Pixel-quantized shaders for trails/glows.
- **Refactor**: `projectile_base.gd` delegates all visuals to the component.

## Style Guidelines
- **Constraint**: All high-res effects (Bloom, Particles) must be rendered or filtered to look like they belong in a pixel-art world (e.g., snapping coordinates, using pixel-art textures for particles).
- **Theme**: "Star Ocean Magic" - Deep blues/purples, high contrast, gradients.
