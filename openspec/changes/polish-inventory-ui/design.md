# Inventory Redesign

## Visual Style

### 1. Glassmorphism & Atmosphere
*   **Background**: Instead of solid `Color(0.1, 0.1, 0.1)`, use a dark, semi-transparent panel (`Color(0.05, 0.05, 0.1, 0.85)`) with a subtle border.
*   **Shader**: Optional blur effect for the window background if performance allows (using `TextureRect` with blur shader or Godot's `Panel` style).

### 2. Item Slots (Grid)
*   **Shape**: Rounded corners (8px).
*   **States**:
    *   *Normal*: Darker glass background.
    *   *Hover*: Scale up (1.05x), border glow increases.
    *   *Empty*: Faint outline or empty socket icon.
*   **Rarity**: The border color and inner glow intensity will be determined by item Rarity.
    *   *Common*: Slate/Gray
    *   *Uncommon*: Green
    *   *Rare*: Blue
    *   *Epic*: Purple
    *   *Legendary*: Gold/Orange

### 3. Layout Structure
*   **Left Column (Navigation)**:
    *   Tabs: [All], [Weapons], [Armor], [Consumables], [Materials].
    *   Styled as vertical pills or sidebar icons (Lucide-style icons from the example).
*   **Center Area (Grid)**:
    *   `GridContainer` with a scrollable are (`ScrollContainer`).
    *   Auto-sizing slots.
*   **Right Column (Details)**:
    *   Item Icon (Large).
    *   Item Name (Colored by rarity).
    *   Stats List (e.g., "Damage: +50").
    *   Description Text.
    *   Action Buttons (Equip, Drop, Use).

## Data Integration Strategy

Since the user confirmed `rarity` and `category` fields are currently missing, we will implement this by updating the `ItemData` resource or creating a `ItemVisuals` helper:
```gdscript
# ItemData extension
@export var rarity: String = "common" # common, uncommon, rare, epic, legendary
@export var type: String = "material" # weapon, armor, consumable, material
```

This ensures we have a dedicated place for visual logic without cluttering the core if preferred, but ideally, it lives on the `Item` resource.

## Interactions

*   **Hover**: Uses `Tween` to animate `scale` and `modulate`.
*   **Click**: Selects the item, populating the **Right Column (Details)**.
*   **Drag & Drop**: Implements Godot `_get_drag_data`, `_can_drop_data`, `_drop_data` specific to `ItemSlot`.
    *   *Visuals*: Generates a "Ghost" texture of the item while dragging.
    *   *Logic*: Allows swapping items between slots.

## Crafting Panel Polish

The improved `CraftingPanel` will adopt a split-view:
*   **Recipe List**: Scrollable list on the left with small icons.
*   **Blueprint View**: Large central display showing:
    *   Result Item (Big Icon + Name).
    *   Ingredients Grid (Required items vs Owned).
    *   "Craft" Button (Gold/Cyan style, disabled if insufficient materials).

