# Magic Visuals

## ADDED Requirements

### Requirement: Magic Projectile Core Visuals
The projectile core MUST be rendered exclusively using a dense `GPUParticles2D` system emitting 1x1 or 2x2 individual glowing pixels, and no single static `Sprite2D` MAY be used for the core or halo.

#### Scenario: Observing a flying projectile
- **Given** a projectile is moving through the air
- **When** the camera observes it
- **Then** the core looks like a tight swarm of buzzing/jittering separate pixels rather than a continuous solid shape, and its boundaries dynamically mutate every frame.

### Requirement: Magic Brightness Mechanism
High visibility and "brightness" MUST be achieved strictly through `CanvasItemMaterial.BLEND_MODE_ADD` as numerous individual 1x1 pixel particles from the core and trail emitters overlap in world space.

#### Scenario: Visual intensity varies by density
- **Given** a behavior that creates high particle amounts ("magic_bolt")
- **When** the particles spawn
- **Then** the densely concentrated centers turn bright white due to additive overlapping, while the scattered trailing pixels remain their raw assigned HDR color.
