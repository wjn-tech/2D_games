# Design: Design Beautiful Glow Cursors

## Architectural Reasoning
The goal is to transition from system-style icons to a custom aesthetic that matches the *Aether-Punk* (Magical Industrial) atmosphere of the shipwreck tutorial and the main survival-crafting world.

### System Components

#### 1. Asset Aesthetic
- **Default (Arrow)**: Stylized as a "Mana Shard" with a core highlight and a blue outer aura.
- **Hover (Talk/Interact)**: A "Hand Silhouette" or "Open Eye" with a green/emerald outer aura.
- **Target (Crosshair)**: A "Magical Sigil" with four inner pointers and a red/focused aura.

#### 2. Visual Optimization
- **Glow Baking**: Using pre-baked PNG glows instead of real-time shaders to maintain the **Hardware Cursor** performance (OS-level low latency). Real-time shaders on custom cursors are not supported by Godot's `Input.set_custom_mouse_cursor` without falling back to a "Software Cursor" sprite (which would feel floaty).
- **High Resolution**: 64x64 PNGs allow for smooth anti-aliased edges and visible glow gradients.

### Performance & Latency
- **Decision**: Reject software-sprite cursors for gameplay actions (movement, targeting). Retain Hardware Cursors to ensure zero input lag.

### Trade-off Discussion
- **Static vs Animated**: Animating hardware cursors requires rapid texture switching which can cause subtle OS-level flickering.
- **Decision**: Use a single high-quality static frame with a "pulsing glow" baked into the texture (strong inner core, soft outer fade) to provide the "Glow" feel without the risk of driver-level flickering.
