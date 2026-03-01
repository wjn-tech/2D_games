# Design: Modern RPG HUD V3

## Visual Style "Modern RPG"
The target aesthetic is clean, readable, but visually rich.
- **Colors:** Deep semi-transparent backgrounds (Black/Dark Grey #CC000000) for panels to ensure text readability against game world.
- **Borders:** Crisp minimal borders (1px-2px) with accent colors (Gold/White).
- **Typography:** Clear sans-serif font (already in use), potentially with outlining/shadows for contrast.

## Layout Strategy

### 1. Status Area (Top-Left)
- **Anchor:** Top-Left (0,0)
- **Composition:**
    - **Health Bar:** Top row, thick red gradient.
    - **Mana Bar:** Bottom row, slightly thinner blue gradient.
    - **Portrait/Level:** (Optional) Circle or Square container to the left of bars.
- **Assets:**
    - `assets/ui/icons/icon_mana.svg` for Mana indicator.
    - Procedural Heart/Cross for Health if no asset found.

### 2. Hotbar (Bottom-Center)
- **Anchor:** Bottom-Center `(0.5, 1.0)` with vertical offset.
- **Composition:**
    - Horizontal `HBoxContainer`.
    - 9 Slots keybound 1-9.
    - "Active Slot" highlight: Brighter border + scale effect.
- **Behavior:**
    - Always visible.
    - Shows item counts.

### 3. Attribute Panel (Modal)
- **Anchor:** Center or Right-aligned.
- **Behavior:**
    - State managed by `HUD` script.
    - Toggled via `Input.is_action_just_pressed("toggle_character_sheet")` (Default: C).
    - Pauses game? **Decision: No**, real-time overlay as per "Modern RPG" fluid UI.

## Technical Constraints
- Continue using `StyleBoxFlat` where possible for performance and resolution independence, but use `TextureRect` for icons.
- Ensure `EventBus` signals (`stats_changed`, `inventory_updated`) drive all UI updates (Passive View pattern).
