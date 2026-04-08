# Tasks: Gameplay Guide System

## Phase 1: Infrastructure & Data

### Core Systems

- [ ] Create `Pause Manager` integration or extend existing pause state to support guide window pause.
  - [ ] Ensure Guide Window pause does not conflict with existing Pause Menu.
  - [ ] Add method to pause game for guide without triggering pause menu UI.
  - [ ] Restore game state when guide is closed.

- [ ] Create guide content data structure.
  - [ ] Define `GuideSectionData` class (Resource) with fields: title, description, icon, subsections.
  - [ ] Define `GuideSubsectionData` class (Resource) with fields: title, content text, **image_path (Texture2D reference)**.
  - [ ] Create `.tres` resource files for each guide section with proper image reference fields.

- [ ] Create `GuideDataManager` singleton or service.
  - [ ] Load all guide section resources at game start.
  - [ ] Provide method `get_all_sections() -> Array[GuideSectionData]`.
  - [ ] Provide method `get_section(section_id: String) -> GuideSectionData`.

## Phase 2: UI Components

### Guide Button & Window

- [ ] Design & implement `GuideButton` scene/script (`scenes/ui/guide_button.tscn`).
  - [ ] Small "?" button in top-left corner.
  - [ ] Setup anchors to fix position at top-left.
  - [ ] Add `pressed` signal handler to show guide window.
  - [ ] Optional: Add tooltip text "Guide (H key)" or similar.

- [ ] Design & implement `GameplayGuideWindow` modal scene (`scenes/ui/gameplay_guide_window.tscn`).
  - [ ] Root is CanvasLayer (high z-index) + Control with margin anchors for modal centering.
  - [ ] Header with "Gameplay Guide" title and close button (X).
  - [ ] Main content area with scrollable section list.
  - [ ] Close button calls `close_guide()` method.
  - [ ] Setup animations for fade-in/fade-out on open/close.

### Guide Section List

- [ ] Design & implement `GuideSectionItem` scene/script (`scenes/ui/guide_section_item.tscn`).
  - [ ] Expandable button/header for section title.
  - [ ] Icon display (optional).
  - [ ] VBoxContainer for subsections (initially hidden/collapsed).
  - [ ] When expanded, show subsections as a list.

- [ ] Design & implement `GuideSubsectionItem` scene/script (`scenes/ui/guide_subsection_item.tscn`).
  - [ ] Subsection title (Label).
  - [ ] **Image display area (TextureRect) with support for PNG/JPG textures**.
  - [ ] Content text area (RichTextLabel) with support for BBCode (for formatting).
  - [ ] **Layout**: Image on top or left, text flows beside/below.
  - [ ] **Image fallback**: Gracefully handle missing images (hide TextureRect if no image_path set).
  - [ ] Optional: Back/Up button to collapse parent section.
  - [ ] Optional: Zoom/scale controls for large images (future enhancement).

## Phase 3: Integration & Logic

### HUD Integration

- [ ] Add `GuideButton` to existing HUD scene (`scenes/ui/hud.tscn`).
  - [ ] Position in top-left corner.
  - [ ] Connect `pressed` signal to open guide window.
  - [ ] Ensure it doesn't overlap with critical gameplay elements (health, mana, etc.).

- [ ] Update `hud.gd` script.
  - [ ] Add `open_guide()` method to instantiate and show `GameplayGuideWindow`.
  - [ ] Add `close_guide()` method to hide/delete guide window.
  - [ ] Emit signal when guide is opened/closed (for pause/unpause coordination).

### Pause & State Management

- [ ] Integrate guide window with game pause state.
  - [ ] When guide opens, pause the game (call `PauseManager.pause()` or set global pause flag).
  - [ ] When guide closes, unpause the game.
  - [ ] Ensure ESC key can close both guide and pause menu gracefully.

- [ ] Implement `GameplayGuideWindow.gd` script.
  - [ ] `_ready()`: Load guide sections from `GuideDataManager`.
  - [ ] `open()`: Show window and apply pause.
  - [ ] `close()`: Hide window and unpause.
  - [ ] Handle section expand/collapse logic.
  - [ ] Optional: Keyboard navigation (arrow keys, ESC to close).

## Phase 4: Content Creation

### Guide Content

- [ ] Write guide content for each section:
  - [ ] **Movement & Camera**: Keyboard controls (WASD, arrow keys), mouse camera control, jump (Space).
  - [ ] **Inventory & Equipment**: Opening inventory (I key), dragging items, equipping to hotbar.
  - [ ] **Combat Basics**: Attacking (left-click or weapon key), targeting, dodging.
  - [ ] **Crafting & Forging**: Accessing crafting menus, recipes, required materials.
  - [ ] **Mining & Resource Gathering**: Tools, techniques, material types.
  - [ ] **NPC Interactions & Trading**: Talking to NPCs, dialogue choices, trading goods.
  - [ ] **Building & City Planning**: Placing buildings, resource requirements, settlement management.
  - [ ] **Magic/Wand System**: Wand assembly, spell components, casting, mana.
  - [ ] **World Mechanics & Progression**: Day/night cycle, weather, environment hazards, game progression.

- [ ] Create `.tres` Resource files for each section.
  - [ ] Format consistent with defined `GuideSectionData` and `GuideSubsectionData` classes.
  - [ ] Include icons (optional, can be added later).

- [ ] Populate initial guide content for at least 3–4 main sections (MVP).
  - [ ] Remaining sections can be filled in iteratively post-MVP.

## Phase 5: Polish & Refinement

### Visual & UX

- [ ] Test responsive UI layout on different screen resolutions.
- [ ] Add animations/transitions for section expand/collapse.
- [ ] Ensure scrollbar appears correctly for long content.
- [ ] Add hover effects and focus states for keyboard navigation.
- [ ] Design/refine visual styling (colors, fonts, spacing).

### Testing

- [ ] Test open/close guide window via button click.
- [ ] Test pause/unpause coordination with gameplay.
- [ ] Test ESC key closes guide without breaking pause menu.
- [ ] Test section expand/collapse and content display.
- [ ] Verify guide content is readable and well-formatted.

### Documentation

- [ ] Update project README or internal wiki with guide content structure.
- [ ] Document how to add new guide sections (for future updates).
- [ ] Add comments to guide-related scripts.

## Implementation Notes

- **Content Format**: Consider using JSON or `.tres` Resource files. JSON is more portable; `.tres` is Godot-native and easier to edit in editor.
- **Localization**: If planning multi-language support, ensure guide content supports translation keys (e.g., `tr("guide.movement.title")`).
- **Pixel-Perfect UI**: Given the minimalist art style, ensure button and window positions are clean and aligned with the HUD grid.
- **Keyboard Shortcut**: Consider assigning a default hotkey (e.g., `H` or `?`) to open guide alongside the button click.
