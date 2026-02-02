# Design: Digging and Camera Enhancements

## 1. Physical Loot System
Instead of direct inventory injection, `DiggingManager` will instantiate a `LootItem` scene at the tile's global position.
- **LootItem**: A simple `Area2D` with a `Sprite2D`. It will have a small "pop-out" animation using a `Tween`.
- **Collection**: When the player enters the `LootItem`'s area, it will be added to the inventory and queue for deletion.

## 2. Continuous Mining & Cracking
Tiles will have a `hardness` value (time in seconds to break).
- **Focus Logic**: `player.gd` tracks the current tile under the mouse. If the left button is held, it increments a `mining_progress` timer.
- **Cracking Effect**: A separate `Sprite2D` or a shader overlay on the `TileMap` will display cracking frames (0-3) based on `mining_progress / hardness`.
- **Reset**: If the mouse moves off the tile or the button is released, `mining_progress` resets to 0.

## 3. Camera Zoom
The `Camera2D` zoom will be dynamic.
- **Input**: `_unhandled_input` in `player.gd` will listen for `MOUSE_BUTTON_WHEEL_UP` and `MOUSE_BUTTON_WHEEL_DOWN`.
- **Range**: Zoom will be clamped between `1.5` and `4.0` to ensure the character remains prominent without breaking the layout.

## 4. Tile Metadata
We will use Godot's `TileSet` custom data layers to store:
- `drop_item`: Path to the `BaseItem` resource.
- `mining_power`: Minimum power required to break.
- `hardness`: Time in seconds required to mine.
