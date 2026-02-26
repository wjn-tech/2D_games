# Design Decision: Precision Magitech
## Context
We are implementing a "Precision Magitech" style inventory (Iron Man HUD met Fantasy Magic - Cyan/Silver palette).

## Goals
1.  **Immersive**: Shatter (Close) and Converge (Open) effects from SCREEN EDGES.
2.  **Responsive**: Hover brightening (Grid + Item), Snapping animations.
3.  **Visual Depth**: Hypnotic, slow-flowing background shader (Deep Sea/Space).
4.  **Clarity**: Modern Sans-Serif fonts, distinct rarity indicators (Gold/Glow).

## Decisions
- **Background**: ColorRect + ShaderMaterial (starfield_flow.gdshader) covering the panel.
- **Particles**: CPUParticles2D for "Shatter" (burst) and "Convergence" (emission shape: Points/Box at edges, negative velocity or attraction).
- **Grid Lines**: TextureRect or NinePatchRect with "Circuit" texture, set to low opacity (0.3), modulated brighter (1.0) on hover.
- **Fonts**: Use a clean sans-serif (e.g., Roboto/Inter style or custom pixel-art variant if needed, but request was explicitly "Modern Sans-serif"). We will use Theme overrides.

## Risks
- **Performance**: Many particles + Shader. Mitigation: Limit particle count (<500), simple shader math.
