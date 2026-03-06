# Proposal: Design Beautiful Glow Cursors

## Problem Context
The current cursor system uses static, standard icons. To match the game's "Magical Shipwreck/Fantasy Industrial" aesthetic (characterized by glowing mana, dark spaceship interiors, and magical constructs), the mouse cursor should feel like a part of the magical UI.

## Proposed Solution
Replace the placeholder cursors with a custom-designed set that features an outer glow pulse effect. Instead of complex animations, we will use a distinct "Glow Outline" and shape changes to indicate different game states.

### Characterizing Game Style:
- **Style**: *Aether-Punk / Magical Industrial*.
- **Visual Cues**: Deep blues, emerald greens, and metallic dark grays with neon-like mana glows.
- **Cursor Themes**: Magical energy condensed into functional shapes.

### Key Features:
- **Beautiful Outlines**: Each cursor will have a soft, pulsing outer glow (implemented via texture or hardware cursor frames).
- **Distinct Shapes**:
  - **DEFAULT**: A magical shard/arrow with a blue mana glow.
  - **HOVER/TALK**: An open eye or hand silhouette with a yellow/green glow.
  - **PICKUP/GRAB**: A closed hand or a magnet-like icon with a white pulse.
  - **TARGET**: A circular magical sigil/crosshair with a focused red/purple glow.
- **Hardware Cursor Performance**: Continue using `Input.set_custom_mouse_cursor` for zero-latency feel.

## Performance & Security
- Cursors will be kept at standard 32x32 or 64x64 sizes.
- Static PNG frames with baked glow effects will be used initially for maximum compatibility.

## Architecture & Design
- Integrated into the existing `CursorManager`.
- Updates to `CURSOR_CONFIG` to point to the new asset paths.
- Hotspot adjustments to ensure pixel-perfect interaction.
