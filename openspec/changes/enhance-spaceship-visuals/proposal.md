# Proposal: Enhance Spaceship Visuals & Environmental Storytelling

## Summary
Upgrade the tutorial spaceship scene (`spaceship2.tscn`) from basic `Polygon2D` placeholders to a polished, atmospheric environment using detailed tilemaps, dynamic lighting, and particle effects. The environment will react dynamically to the narrative progression (e.g., system failures, hull breaches, crash impact).

## Motivation
The current spaceship scene relies on simple geometric shapes and basic particles, which fails to convey the urgency and atmosphere of a "critical failure" scenario. To improve player immersion during the tutorial, the environment needs to visually support the narrative stakes—showing the ship falling apart in real-time.

## Proposed Solution
1.  **Visual Overhaul**: Replace `Polygon2D` walls/floors with a detailed **Industrial Gritty** Sci-Fi Tileset (High-quality sprite assets with rust/damage). Add decorative props (consoles, pipes, wires).
2.  **Dynamic Lighting**: Implement 2D lighting (`PointLight2D`) for emergency alarms, sparking wires, and console glows. **Lighting Strategy**: Keep the environment relatively bright/visible to aid navigation, using the flashing Red Alarms to create urgency rather than extreme darkness.
3.  **Environmental States**: Enhance `ShipEnvironmentController` to support distinct visual states:
    *   **CRITICAL**: Red flashing lights, sparks, steam.
    *   **FAILING**: Lights flickering, momentary dimming.
    *   **BREACH**: Hull damage visuals, debris suction, intense camera shake, and **Camera Rotation** to sell loss of gravity/orientation.
4.  **Parallax Background**: Improve the window view with a scrolling starfield to simulate uncontrolled descent.

## Risks & Mitigation
-   **Performance**: Excessive lights/particles on low-end devices.
    -   *Mitigation*: Use a limited number of shadow-casting lights; rely on texture emission where possible.
-   **Asset Availability**: Need a suitable Industrial Sci-Fi tileset.
    -   *Mitigation*: **Procedurally generate** or create a custom "Industrial Gritty" pixel-art tileset as part of the implementation tasks.


## Alternatives Considered
-   **Keep Polygon2D**: Refine the geometry deeply.
    -   *Cons*: Hard to achieve "gritty" sci-fi look purely with vectors without complex shaders.
-   **Full 3D Background**: Too heavy and stylistically inconsistent with the 2D game.
