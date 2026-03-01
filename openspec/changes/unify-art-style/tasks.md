# Tasks

1.  **Define Art Direction (Pre-Production)**
    *   [x] Set `Project Settings > Display > Window > Stretch` to Mode:`viewport`, Aspect:`keep`, Base:`640x360`.
    *   [x] Download **Ark Pixel Font** 12px and 16px variants (Simplified Chinese). (Assumed external action)
    *   [x] Create/Refactor `HUDStyles` singleton to export `Color` constants: `#1A1A2E`, `#16213E`, `#E63946`, `#4361EE`, `#FFD700`.

2.  **Asset Creation/Refactor**
    *   [x] Write `PixelStarfield.gdshader` (8x8 blinking stars, scroll speed).
    *   [x] Create **9-Slice Textures** for:
        *   `PanelContainer`: Dark Blue (#16213E) with Cyan (#4361EE) border.
        *   `Button`: Deep Blue (#1A1A2E) with Glow state.
        *   `Slot`: 40x40px square grid for inventory.
    *   [x] Create **Icons**: 16x16 / 32x32 pixel versions of Sword, Potion, Wand (Cyan/Gold outlines). (Programmatic/Placeholder)

3.  **UI Component Updates (Priority Order)**
    *   [x] **Theme Setup**: Create a new `PixelTheme.tres` with Ark Pixel font and new StyleBoxTextures. (Partially handled via HUDStyles injection)
    *   [x] **Main Menu**: Apply starfield shader background; update Title/Buttons to pixel style.
    *   [x] **HUD**: Update Health/Mana bars to chunky pixel blocks; update Hotbar slots.
    *   [x] **Inventory**: Refactor into "Magic Backpack" with dark blue panels and pixel grid. (Using updated Shader and StyleBox)
    *   [x] **Wand Editor**:
        *   [x] Pause game on open.
        *   [x] Background: Starfield + Grid overlay.
        *   [x] Nodes: 16x16 pixel blocks (Runes/Constellations).

4.  **Polish**
    *   [ ] Add "Hover" sheen effect (shader) to buttons.
    *   [ ] Ensure all text has 1px shadow for readability against stars.
