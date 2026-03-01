# Requirement: Pixel-Art UI Unification

The user interface currently uses conflicting high-resolution assets (Vectors, Gradients). It must be rebuilt to match the pixel-art gameplay.

## ADDED Requirements

#### Requirement: Pixel-Cosmic Palette
The UI must strictly adhere to the "Star Ocean" color palette:
*   **Backgrounds**: Deep Purple/Cosmic Blue (#1A1A2E, #16213E) with mild transparency (0.9 alpha).
*   **Borders**: Magical Blue (#4361EE) or Gold (#FFD700) pixel lines (no anti-aliasing).
*   **Text**: White/Cyan pixel font with drop shadow (1px offset).
*   **Scenario:** Opening the Main Menu.
    *   **Given** the game launches.
    *   **Then** the background is a pixelated starfield (8x8 blinking stars).
    *   **And** the "Start Game" button is a rounded pixel rectangle with a pulsing blue outline.

#### Requirement: Starfield Background Shader
A GLSL shader must replace static background images for the Main Menu and Paused UI overlays.
*   **Scenario:** Pausing the game.
    *   **Given** the player opens the Inventory.
    *   **When** the UI appears.
    *   **Then** a fullscreen shader renders a slow-moving, pixel-aligned starfield behind the UI panels.
    *   **And** the stars vary in brightness but do not use sub-pixel smooth movement.

#### Requirement: Ark Pixel Font
The UI must use **Ark Pixel Font** (12px variant) for all standard text to ensure crisp rendering at 640x360 and full Simplified Chinese support.
*   **Scenario:** Displaying localized text.
    *   **Given** a quest description in Simplified Chinese.
    *   **When** rendered in the UI.
    *   **Then** the characters must be sharp (no anti-aliasing) and legible at standard UI scale.

#### Requirement: Stylized Node Graph
The Wand Editor's node graph must replace abstract boxes with stylized "Rune Stones" or "Ink Glyphs".
*   **Scenario:** Editing a spell.
    *   **Given** the player drags a "Fireball" node onto the page.
    *   **When** placed.
    *   **Then** it appears as a glowing rune or inked symbol on the paper texture.
    *   **And** connections are drawn as if by quill/ink (rugged lines), not precise vector bezier curves.

#### Requirement: Pixel-Perfect Scaling
The UI must align perfectly with the game's pixel grid.
*   **Scenario:** Resizing the window.
    *   **Given** the game is running at 1920x1080.
    *   **And** the base pixel resolution is 640x360.
    *   **When** the UI scales up (3x).
    *   **Then** every UI element (text, borders, icons) must align to the calculated 3x3 pixel blocks. No sub-pixel blurring.

#### Requirement: Primary Font (Language Support)
The UI must use a font that is legible at low resolutions but supports both English and Chinese characters.
*   **Scenario:** Displaying localized text (Inventory/Quests).
    *   **Given** a quest description in Simplified Chinese.
    *   **When** rendered in the UI.
    *   **Then** the characters must be crisp (bitmap font or well-hinted TTF with antialiasing disabled) and match the pixel aesthetic.

#### Requirement: Diegetic Containers
UI menus such as the "Wand Editor", "Inventory", and "Settings" must be rendered as physical objects (Books, Scrolls, Pouches) within the 640x360 resolution, rather than abstract windows.
*   **Scenario:** Editing a wand spell.
    *   **Given** the player presses the "Edit Wand" key.
    *   **When** the editor opens.
    *   **Then** a fullscreen or large overlay of an open book (Grimoire) appears with paper texture backgrounds.
    *   **And** the node graph is drawn on the page surface (using ink-colored lines/nodes).

#### Requirement: Pixel Bitmap Font (Localized)
The UI must use a specific pixel bitmap font that supports Simplified Chinese and aligns with the 640x360 grid.
*   **Scenario:** Reading item descriptions.
    *   **Given** an item tooltip.
    *   **When** displayed at 3x scale (1920x1080 screen).
    *   **Then** the text glyphs must appear sharp and blocky (no anti-aliasing), preserving the 1:1 pixel look of the base resolution.

#### Requirement: Nine-Slice Sprites
All container backgrounds (panels, buttons, windows) must use 9-slice sprites (NinePatchRect / StyleBoxTexture) instead of vector rectangles.
*   **Scenario:** Creating a flexible window.
    *   **Given** a new inventory window is needed.
    *   **When** instantiated.
    *   **Then** its borders must remain sharp (unblurred) regardless of size, using the defined pixel corner assets.

#### Requirement: Sprite Icons
Vector icons (SVG) must be replaced with sprite-sheet based icons.
*   **Scenario:** Equipping an item.
    *   **Given** an item icon in the hotbar.
    *   **When** displayed.
    *   **Then** it must be a 16x16 or 32x32 pixel sprite, not a scalable vector graphic.

## MODIFIED Requirements

#### Requirement: Wand Editor (Book Style)
The "Wand Editor", previously a floating window with an abstract node graph, must now be integrated into a "Spellbook" or "Grimoire" interface.
*   **Scenario:** Opening the Wand Editor.
    *   **Given** the player has the wand equipped.
    *   **When** they interact with the enchantment table (or press the edit key).
    *   **Then** an open book sprite (approx. 500x300 pixels) appears centered on screen.
    *   **And** the nodes (Spells/Runes) are drawn on the pages, functioning as drag-and-drop elements but styled as magic inscriptions.

#### Requirement: HUD Layout
The HUD elements (Health, Mana, Minimap) must be repositioned/styled to fit the pixel grid.
*   **Scenario:** Viewing the HUD.
    *   **Given** the player is in-game.
    *   **When** looking at the top-left corner.
    *   **Then** the life bars should use pixel art (textures) instead of smooth filled rectangles.
