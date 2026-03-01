# Proposal: Unify Art Style to "Pixel-Perfect Fantasy"

## Summary
The current project suffers from a significant visual disconnect:
1.  **Gameplay**: Low-resolution pixel art (Terraria-style).
2.  **UI/HUD**: High-resolution vector graphics, gradients, and modern web-like typography (Poppins, Rounded Corners, Glassmorphism).
3.  **VFX**: High-fidelity particle effects mixed with pixel art.

This proposal aims to unify the visual identity by adopting a **"Pixel-Native UI"** strategy. The UI will be rebuilt to strictly adhere to the pixel grid, using 9-slice textures, pixel fonts, and a limited color palette that complements the gameplay assets.

## Aesthetic Direction
*   **Theme**: Retro Sci-Fi / Fantasy (Cosmic Magic).
*   **Color Palette**: Deep Cosmic Blue/Purple background with Neon Blue/Gold highlights (Star Ocean style).
*   **Resolution**: **Locked to 640x360**. All assets (UI and Game) are drawn at this resolution and integer-scaled to fit the player's screen.
*   **Typography**: **Dedicated Pixel Bitmap Font**. Recommended: **[Ark Pixel Font](https://github.com/TakWolf/ark-pixel-font)** (Open Source, 10px/12px/16px sizes, supports Simplified Chinese).
*   **Containers**: **Diegetic UI (Holographic/Magitech Grimoire)**.
    *   **Style**: Semi-transparent dark blue panels with glowing magical borders.
    *   **Pause Behavior**: Opening large UI elements (Grimoire, Inventory) **fully pauses** the game world, overlaying a dim pixelated starfield.

## Key Changes
1.  **Font Replacement**: Switch global theme font to *Ark Pixel Font* (12px base size).
2.  **Viewport Configuration**: Set Godot project settings to `viewport` stretch mode with a base resolution of 640x360.
3.  **Diegetic Transformation**:
    *   **Wand Editor** -> **Star Chart / Magitech Tablet**: A fullscreen interface.
        *   **Visual Style**: Nodes = "Star Constellations/Runes", Connections = "Energy Beams".
        *   **Interaction**: Mouse-driven drag-and-drop on a cosmic grid.
    *   **Inventory** -> **Quantum Storage**: Grid floating in a starfield.
4.  **Iconography**: Replace `Lucide` vectors with **Kenney's 1-Bit Pack** (recolored to Cyan/Gold) or similar open-source pixel icons.

## Rationale
*   **Cohesion**: Immersion breaks when switching between a retro game world and a modern "App-like" menu.
*   **Visual Harmony**: Deep Blue/Purple backgrounds contrast well with the brighter gameplay elements while fitting the "Star Ocean" narrative.
*   **Performance**: Unified asset pipeline (TextureAtlases) vs mixing TTF/SVG/PNG.

## Open Questions (To Be Clarified)
1.  **"Holographic" vs "Physical" Borders**:
    *   Since we are going for "Star Ocean/Magitech", should the UI borders be:
        *   A. **Solid Pixel Lines** (Retro console style, like SNES RPGs)?
        *   B. **Glowing/Pulsing Shader Effects** (Modern pixel art, using WorldEnvironment glow)?
    *   *(Option B fits "Magic/Cosmic" better but is harder to implement perfectly in pure pixel art without causing blur).*
2.  **Shader Implementation**:
    *   The proposal mentions a "Pixel Starfield Shader" for backgrounds. Do you have an existing shader for this, or should we write a simple GLSL shader to generate pixel-perfect stars behind the UI?
