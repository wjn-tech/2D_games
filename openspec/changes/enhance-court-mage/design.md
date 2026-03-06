# Technical Design - Enhance Court Mage

## Architecture
-   **Scene Structure (`court_mage.tscn`)**:
    -   `Node2D` (Root)
        -   `Visuals` (Node2D) - container for sprite to allow local floating offset independent of root position.
            -   `Sprite2D` - The character art.
            -   `AuraParticles` (CPUParticles2D) - Idle magical glow.
        -   `TrailSystem` (Line2D/CPUParticles2D) - Shows movement path.
    
-   **Script (`court_mage.gd`)**:
    -   `_process`: Updates the `Visuals.position.y` using `sin(time * speed) * height` for floating effect.
    -   `_process`: Checks `global_position` delta to determine if moving. If moving > threshold, enable trail/run animation.

## Considerations
-   **CinematicDirector Interaction**: The director tweens the `global_position` of the Root. The floating effect must be applied to a *child* node (Visuals) to avoid conflict.
-   **Facing**: The script should automatically flip the `Sprite2D` based on movement direction (`velocity.x`).

## Assets
-   We will need a sprite. If none exists, we will use a "Pixel Art Wizard" style placeholder or a generated asset.
