# Tasks: Polish Main Menu Experience

## Preparation
- [ ] Locate `scenes/ui/MainMenu.tscn` and `src/ui/main_menu.gd`.
- [ ] Identify or create a "Nebula" noise texture (can use a gradient or noise resource).

## Implementation
- [x] **Scene Structure**:
    - [x] Add `TextureRect` (Nebula) to `MainMenu.tscn` background.
    - [x] Configure `CanvasItemMaterial` (Blend Mode: Add) for the Nebula if needed.
- [x] **Theming**:
    - [x] Adjust `StartButton` modulation to Gold (`#FFD700`).
    - [x] Adjust other buttons to Cyan (`#00E5FF`).
    - [x] Set Button Icon modulation to match text.
- [x] **Scripting (`main_menu.gd`)**:
    - [x] Create `play_entrance_animation()` function.
    - [x] In `_ready()`, set initial clear alpha for UI elements.
    - [x] Call `play_entrance_animation()` effectively.
- [x] **Refinement**:
    - [x] Tweaking spacing in VBoxContainer.
    - [x] Verify hover scaling works with new entrance positions.
