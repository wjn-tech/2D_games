# Design: Wand Decoration & Handling Architecture

## Key Concepts

### 1. The 16x16 Pixel Grid
The Wand is conceptually a 16x16 pixel-art image where each pixel corresponds to a physical component.
-   **Storage**: `WandData.visual_grid` stores `Display(Vector2i) -> BaseItem (Resource)`.
-   **Visuals**: We don't render 256 individual `Sprite2D` nodes in-game. Instead, we generate a single `ImageTexture` at runtime.
    -   **Resolution**: 16x16 raw pixels.
    -   **Scaling**: The sprite is rendered with `texture_filter = NEAREST` to maintain sharp pixel art when scaled up (e.g., in UI or World).

### 2. Texture Generation Pipeline
When a `WandData` is loaded (e.g., Inventory UI open or Player Equip):
1.  **Input**: `visual_grid` (Dictionary).
2.  **Process**:
    -   Create `Image` of size 16x16.
    -   Iterate grid keys. Get `BaseItem` for each cell.
    -   Read `BaseItem.wand_visual_color`.
    -   `image.set_pixel(x, y, color)`.
    -   Create `ImageTexture.create_from_image(image)`.
3.  **Output**: A transient `Texture2D` used by UI Icons and Player Weapon Sprite.
    -   *Optimization*: Cache generated textures by `WandData` instance ID or hash content to avoid rebuilding every frame.

### 3. Player Holding Mechanics
 The user specified a "Pivot" mechanic distinct from standard rotation.

**Geometry Definitions**:
-   **Grid Space**: 0..16 on X/Y.
-   **Tail Center**: Local `(0, 8)` (Middle of left edge).
-   **Head Center**: Local `(16, 8)` (Middle of right edge).
-   **Sprite Origin**: To simplify rotation, we set the Sprite's `offset` or `pivot_offset` such that `(0, 8)` aligns with the node's `(0,0)`.

**Holding Logic**:
-   **Anchor**: `Player.position` (Center).
-   **Target**: `Mouse.position`.
-   **Vector**: `V = Mouse - Anchor`.
-   **Rotation**: `V.angle()`.
-   **Flip**: If `mouse.x < player.x`, the sprite should flip vertically (`scale.y = -1`) to keep the "Top" of the wand up, OR we simply rotate 180 degrees.
    -   *Decision*: Standard top-down shooter style logic: Rotate freely. If `angle` is in left quadrants, set `flip_v = true` so the drawing isn't upside down, or just rely on the pixel art being symmetric enough?
    -   *Refinement*: User said "Head direction is Mouse - Tail". Tail is at Player Center. So the wand simply rotates around the Player Center.

### 4. Spell Emission Origin
-   **Logic**: Spells spawn at the "Head".
-   **Calculation**:
    -   `HeadOffset = Vector2(16, 0)` (Assuming sprite is 16px wide and centered vertically, or 1 unit wide).
    -   `SpawnPos = PlayerPos + HeadOffset.rotated(angle)`.
    -   This guarantees spells leave from the visual "tip" of the wand's bounding box.

## Architecture

#### `WandTextureGenerator` (Autoload / Static Util)
```gdscript
static func generate_texture(data: WandData) -> ImageTexture
```

#### `WandEditor`
-   **Grid**: Uses `ColorRect` or `TextureRect` cells.
-   **Interaction**: Click/Drag with "Brush" (Item).
-   **Preview**: Shows the generated `ImageTexture` in real-time.

#### `Player`
-   **Nodes**: `Marker2D (Hand)` -> `Sprite2D (WandSprite)`.
-   **Script**: In `_process` or `_physics_process`:
    ```gdscript
    var mouse_pos = get_global_mouse_position()
    var direction = (mouse_pos - global_position).normalized()
    wand_sprite.rotation = direction.angle()
    # Optional: Flip logic if needed for asymmetry
    ```
