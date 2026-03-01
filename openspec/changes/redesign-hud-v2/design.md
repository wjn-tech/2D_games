# Design: HUD Architecture

## Visual Style Guide (Programmatic)

Since we may lack custom assets, we will use `StyleBoxFlat` to approximate the look.

- **Panels**: Dark semi-transparent background (`#1a1a1acc`), distinct border (`#333333` or Accent Color), rounded or chamfered corners (pixel style prefers chamfered or sharp).
- **Colors**:
    - **HP**: `#e74c3c` (Flat Red) or `#2ecc71` (Flat Green) -> Pixel art often uses distinct bands.
    - **Mana**: `#3498db` (Flat Blue).
    - **Text**: White with Outline (Constant 1px outline black) for readability against game world.
    - **Selection**: `#f1c40f` (Gold) or `#ffffff` (White) border glow.

## Component Breakout

Current `HUD.tscn` is a monolithic Control. We will modularize logical groups:

1.  **StatusWidget**: Top-left. HP, Mana bars. Avatar face (optional).
2.  **GameInfoWidget**: Top-right. Minimap, Date/Time, Weather.
3.  **HotbarWidget**: Bottom-center. (Currently managed by `Inventory`, need to ensure it overlays HUD correctly or is part of HUD layout).
4.  **UtilityBar**: Bottom-right or Side. Buttons for Menu, Inventory, Help.
5.  **Notifications**: Center-top or Right-side list. Quests, Item pickups.

## Interaction Logic

- **Tweening**: Use `create_tween()` for lightweight, non-blocking animations on UI state changes.
- **Signals**: HUD should listen to global signals (`EventBus`, `GameState`) and update components independently.
