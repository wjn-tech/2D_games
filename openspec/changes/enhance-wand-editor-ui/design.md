# Design: Modern Magic Industry UI

## Architectural Reasoning
The "Modern Magic Industry" look requires a clean, digital aesthetic with high-contrast accents. We will use `StyleBoxFlat` for its flexibility in defining borders, shadows, and content margins without needing external texture files.

## Visual Palette
- **Primary Background**: `Color(0.05, 0.07, 0.1, 0.85)` (Dark Translucent Blue).
- **Accents/Borders**: `Color(0.2, 0.8, 1.0)` (Cyan/Electric Blue).
- **Secondary Text**: `Color(0.6, 0.8, 0.9)` (Light Blue-Grey).
- **Warning/Error**: `Color(1.0, 0.3, 0.3)` (Neon Red).

## Implementation Strategy

### 1. Sci-Fi StyleBoxes
- **Panels**: Thin cyan borders (1-2px) with a subtle shadow glow (`shadow_size: 4`, `shadow_color: cyan_with_low_alpha`).
- **Buttons**: Inverted colors on hover; glow effect on press.
- **Tabs**: Sleek, flat tabs with underline indicators instead of standard chunky buttons.

### 2. SVG Icon Integration
- Create a helper utility or include raw SVG strings for common icons (Level, Mana, Speed, Logic).
- These will be applied to `TextureRect` or `Button` icons in the editor header and stats panel.

### 3. Grid & Board Enhancements
- **Visual Grid**: Add a translucent scanning-line effect or a subtle blueprint-style secondary grid.
- **Logic Board**: Modernize the `GraphEdit` theme to match the cyan/dark-blue palette.

## Technical Details
- **Theme Global Assignment**: Apply to the `WandEditor` root node via code in `_ready()` or via the inspector for the `.tscn`.
- **Procedural Glow**: Use the `shadow` properties of `StyleBoxFlat` to simulate "neon" light emitted from panel edges.
