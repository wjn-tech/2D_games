# Beautify Main Menu Design

## Visual Structure

- **Theme**: "Arcane & Magical" – Deep purples/blacks with glowing accents, glassmorphism panels, and rune particles.
- **Background**: Re-use `DynamicBackground.tscn`, but overlay with floating particles (`MagicParticle`), runes (`FloatingRune`), and rings (`MagicCircle`) via a new `MenuEffects.tscn`.
- **Layout**:
  - **Center Container**: Retains the existing `CenterContainer` structure.
  - **Glass Panel**: A `PanelContainer` with a custom `blur_shader.gdshader` background.
  - **Title**: A `RichTextLabel` with gradient effects (`[color]` tags or shader) and drop shadow.
  - **Buttons**:
    - **Normal**: `StyleBoxFlat` with slight transparency border.
    - **Hover**: Gradient border animation, inner glow, scale tween.
    - **Active/Presed**: Brighter glow, pushed state.
    - **Icons**: Lucide-style SVG icons (`sword.svg`, `scroll.svg`, `settings.svg`, etc.) placed inside `Button` via `icon` property or custom texture rect.

## Component Architecture

- **`MenuEffects.tscn`**:
  - `MagicCircle`: A rotating textured sprite or shader-based circle.
  - `FloatingRunes`: A `GPUParticles2D` system emitting rune textures.
  - `StarParticles`: Simple `GPUParticles2D` for sparkles.

- **`GlassTheme.tres`**:
  - Defines the global look for `Panel`, `Button`, `Label`.
  - Uses `StyleBoxFlat` for base shapes (border radius, blur hinting via transparency).
  - Uses `ShaderMaterial` for advanced blur if needed (Godot 4 `canvas_item` screen texture read).

- **`GradientLabel`**:
  - A custom scene/script wrapping `Label` and applying a shader that uses `SCREEN_TEXTURE` or a secondary `GradientTexture2D` to color the text.

- **Menu Refactor**:
  - `MainMenu.tscn`: Add `MenuEffects` instance, wrap content in `GlassPanel`.
  - Sub-menus (Settings, Load): Apply the same theme and container structure.

## Technical Considerations

- **Blur Shader**: Real-time blur can be expensive. For low settings, fallback to semi-transparent dark overlay.
- **Resource Management**: Preload icon SVGs.
- **Tweening**: Use `create_tween()` for button hover animations (scale, color modulation).

