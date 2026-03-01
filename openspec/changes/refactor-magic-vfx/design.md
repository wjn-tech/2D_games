# Design: Magic System Refactor (Pixel Juice)

## Architecture

### 1. `MagicProjectileVisualizer`
Responsible for the 3 lifecycles of a projectile's visual:
1.  **Spawn (Muzzle Flash)**: Instantiates a short-lived `AnimatedSprite2D` at the caster's location.
2.  **Flight (Loop)**:
    - **Core**: An `AnimatedSprite2D` (not `Line2D`) representing the physical bullet.
    - **Trail**: A `GPUParticles2D` emitting *pixel-art* shards, ensuring distinct separation from the background.
    - **Aura**: A `PointLight2D` with a high-contrast texture (not just a soft circle).
    - **Motion**: Procedural bobbing/scaling (Sine wave on Scale) to simulate "pulsing energy".
3.  **Death (Impact)**: Spawns a dedicated explosion scene matching the element.

## Bespoke Visual Definitions

The `MagicProjectileVisualizer` will not use a generic "Line + Particles" template. Instead, it will look up a specific `PackedScene` or `Configuration` for each `special_behavior`.

### 1. `spark_bolt` (The Zapper)
- **Concept**: A erratic, crackling electric spark.
- **Core**: No sprite.
- **Main Visual**: `Line2D` with `LightningShader` (Jitter amplitude high, frequency high).
- **Color**: `Color(1.0, 5.0, 50.0)` (Blinding Blue).
- **Juice**: Instant flash spawn, lingering electrical arcs on impact.

### 2. `magic_bolt` (The Classic)
- **Concept**: A condensed sphere of pure mana.
- **Core**: `AnimatedSprite2D` (Spinning 8-bit energy ball, 16x16).
- **Trail**: `GPUParticles2D` (Heavy stardust, slow decay).
- **Color**: `Color(20.0, 1.0, 50.0)` (Magenta/Purple).
- **Juice**: Sine-wave scale pulsing (breath) during flight.

### 3. `bouncing_burst` (The Ricochet)
- **Concept**: A high-energy rubber projectile.
- **Core**: `Sprite2D` (Round, glowing orb).
- **Motion**:squash_and_stretch` applied based on velocity change (elongates on flight, flattens on bounce).
- **Color**: `Color(40.0, 40.0, 2.0)` (Neon Yellow).
- **Impact**: Spawns a "Ripple" ring effect on bounce points.

### 4. `chainsaw` (The Ripper)
- **Concept**: A physical manifestation of cutting force.
- **Core**: `AnimatedSprite2D` (Spinning sawblade, blurred by speed).
- **Trail**: Directional sparks jetting *backwards* (opposite velocity).
- **Color**: `Color(100.0, 100.0, 100.0)` (White Hot).
- **Juice**: Screen shake on spawn (small).

### 5. `tri_bolt` (The Formation)
- **Concept**: Three orbiting motes.
- **Visual**: A central empty node with 3 small `Sprite2D` orbs rotating around the center point.
- **Color**: `Color(0.1, 50.0, 10.0)` (Teal).
- **Trail**: Three distinct helix spirals interlacing.

### 6. `magic_arrow` (The Hunter)
- **Concept**: A construct of seeking energy.
- **Core**: `Sprite2D` (Arrowhead shape, distinct orientation).
- **Trail**: "Feather" particles emitting from the tail.
- **Color**: `Color(8.0, 1.0, 12.0)` (Deep Purple).

### 7. `energy_sphere` (The Nuke)
- **Concept**: Unstable mass.
- **Core**: Large `Shader` sphere (Voronoi noise distortion).
- **Juice**: Camera shake increases as it travels (proximity).
- **Color**: `Color(2.0, 6.0, 6.0)` (Cyan).

### 8. `cluster_bomb` (The Frag)
- **Concept**: A cracked crystal ready to shatter.
- **Core**: `Sprite2D` (Crystal shard cluster).
- **Flicker**: High frequency opacity modulation.
- **Color**: `Color(10.0, 5.0, 0.2)` (Golden).

### 9. `homing` (The Seeker)
- **Concept**: Sentient wisp.
- **Core**: `GPUParticles2D` only (Head) + Long trail. No solid body.
- **Motion**: "Snakelike" movement (visual offset from actual physics path).
- **Color**: `Color(1.5, 1.0, 0.3)` (Pale Yellow).

### 10. `explosive_bounce` (The Grenade)
- **Concept**: Ticking time bomb.
- **Core**: Pulsing red/orange orb.
- **Visual Feedback**: Pulses get faster with lifetime/bounces.
- **Color**: `Color(3.0, 1.0, 0.1)` (Lime/Orange mix).

### 11. `tnt` (The Heavy)
- **Concept**: Box of doom.
- **Core**: `Sprite2D` (Pixel art TNT box or red cylinder).
- **Trail**: Smoking fuse particle (black/grey smoke + spark).
- **Color**: `Color(100.0, 10.0, 0.1)` (Volcanic Red).

### 12. `blackhole` (The Void)
- **Concept**: Absence of light.
- **Core**: Inverted circle shader (Screen reading shader that distorts/darkens background).
- **Aura**: Purple accretion disk particles sucking INWARDS.
- **Color**: `Color(0,0,0)` core + Purple rim.

### 13. `teleport` (The Glitch)
- **Concept**: Reality error.
- **Core**: Character sprite ghost (if possible) or Glitched rectangle.
- **Trail**: chromatic aberration particles (RGB split).
- **Color**: `Color(0.2, 100.0, 100.0)` (Cyan Jitter).

## Architecture Changes
- `MagicProjectileVisualizer` will utilize a `Dictionary` mapping behavior strings to `PackedScene` (for complex ones like Blackhole/Chainsaw) or `ShaderResources`.
- **Gradient Mapping**: Use `CanvasModulate` or specific Shaders on the projectile to force colors to "pop" against the sky brightness.
- **Outline**: Add a 1px contrasting outline (Shader) to projectiles to separate them from the background.

## Data Flow
`ProjectileBase` -> calls `visualizer.set_element("fire")` -> Visualizer loads `res://assets/visuals/projectiles/fire_core.tres`.

