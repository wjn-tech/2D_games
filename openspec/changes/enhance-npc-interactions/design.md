# Design: Friendly NPC Interaction System

## Architecture Overview

The system introduces a new `NPCInteractionManager` (or `InteractionSystem`) likely as a component on `Player` or a global manager, but given the current ECS-lite approach, we will integrate it into the existing `BaseNPC` and `UIManager` flow while keeping logic decoupled.

### 1. Visual Cues & Progressive Disclosure
Instead of a monolithic manager, each `BaseNPC` will handle its own proximity checks (or via a shared `ProximityDetector` component) to determine the "Disclosure Level".

*   **Level 0 (Far)**: No UI.
*   **Level 1 (Noticeable)**: `MinimalistEntity` shows basic type/alignment color.
*   **Level 2 (Approach)**: Floating Nameplate + Occupation Icon.
*   **Level 3 (Interactable)**: Action Prompt (E) + Speech Bubble Preview.

**Component**: `VisualCueComponent` (Node2D) attached to NPC scene.
*   Managed by `BaseNPC.gd`.
*   Connects to `MinimalistEntity` to draw overlays (rings/badges).
*   Manages child Control nodes for prompts.

### 2. Contextual Interaction System
We will refactor the simple "Press E" logic into a `ContextPrompt` system.
*   `BaseNPC` will expose a `get_available_interactions(player)` function returning list of valid actions `{ key: 'E', label: 'Talk', type: 'primary' }`.
*   **Context Evaluator**: Checks conditions like `is_night`, `has_shop`, `relationship_level`.

### 3. Feedback System
A dedicated `FeedbackManager` (part of `UIManager`) to spawn transient effects.
*   `show_feedback(type, position, value)`
*   Spawns pooled `FloatingText` or `ParticleEffect` nodes.

### 4. Trading UI
A new `TradeWindow.tscn` managed by `UIManager`.
*   **Data Flow**: `NPC (Inventory)` -> `TradeManager` (Calculate prices/discounts) -> `TradeWindow`.
*   **Persistence**: Discounts and relationship changes persist in `CharacterData`.

## Integration Points

- **`BaseNPC.gd`**:
    - Add `_process` or `Area2D` signals to track Player distance.
    - Update `VisualCueComponent` state.
- **`MinimalistEntity.gd`**:
    - Add methods to draw "Accessories" (e.g., an apron rect) and "Mood/Relationship Rings" (conic gradients or simple arcs) using `_draw`.
- **`UIManager.gd`**:
    - Register new windows (`TradeWindow`).
    - Expose `Feedback` API.
- **`CharacterData.gd`**:
    - Ensure `relationship` data structures support the new logic (`last_interaction_time`, `liked_items` history).

## Data Structures

```gdscript
# In CharacterData
var affinity_data = {
    "level": 0, # 0-100
    "history": [],
    "last_seen": 0
}
```

## Accessibility (Options)
Global settings in `SettingsManager` will control:
- `visual_cue_intensity`: Scale of icons/rings.
- `high_contrast`: Force distinct colors in `MinimalistEntity`.
