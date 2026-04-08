# Design: Gameplay Guide System

## UI Layout & Structure

### Guide Button

```
┌─────────────────────────────────────────────────────────┐
│ [?]  HUD Elements (Health, Mana, Inventory Slots, etc)  │ ← GuideButton at top-left
└─────────────────────────────────────────────────────────┘
```

**Button Spec**:

- Size: ~40x40 pixels (small, unobtrusive).
- Position: Anchored to top-left, with small margin (e.g., 10px).
- Text: Large "?" character or icon.
- Hover Effect: Slight scale increase or color tint.
- Tooltip (optional): "Guide (H)" or "Help".

### Gameplay Guide Window

```
╔═══════════════════════════════════════════════════════════╗
║  Gameplay Guide                                        [X] ║  ← Header with close button
╠═══════════════════════════════════════════════════════════╣
║  ▼ Movement & Camera                                       ║  ← Collapsible section header
║    • Keyboard Controls: WASD or arrow keys                 ║  ← Subsection (initially hidden)
║    • Mouse Camera: Move mouse to rotate view               ║
║    • Jump: Spacebar                                        ║
║                                                             ║
║  ▶ Inventory & Equipment                                  ║  ← Collapsed section
║  ▶ Combat Basics                                          ║
║  ▶ Crafting & Forging                                     ║
║  ▶ Mining & Resources                                     ║
║  ▶ NPC Interactions                                       ║
║  ▶ Building & City Planning                               ║
║  ▶ Magic & Wand System                                    ║
║  ▶ World Mechanics & Progression                          ║
║                                                  [scroll ▼] ║
╚═══════════════════════════════════════════════════════════╝
```

**Window Spec**:

- Type: Modal CanvasLayer-based Control with semi-transparent background overlay.
- Position: Centered on screen.
- Size: ~600px wide × 500px tall (responsive; adjust for mobile).
- Background: Semi-transparent dark overlay (dim the game world).
- Content: Scrollable VBoxContainer with section items.
- Close: X button in header + ESC key integration.

### Collapsible Section & Content

```
Section (Collapsed):
├─ Header Button: "▶ Movement & Camera"
└─ Content Area (hidden): [empty]

Section (Expanded):
├─ Header Button: "▼ Movement & Camera"
└─ Content Area (visible):
    ├─ Subsection 1: "Keyboard Controls"
    │  ├─ Image (if provided): [PNG/JPG texture displayed]
    │  └─ Content: "Use WASD or arrow keys to move. Hold Shift to run."
    ├─ Subsection 2: "Mouse Camera"
    │  ├─ Image: [Texture shown here]
    │  └─ Content: "Move your mouse to rotate the camera around the player."
    └─ Subsection 3: "Jump"
       ├─ Image: [Optional - not all subsections need images]
       └─ Content: "Press Spacebar to jump."
```

**Subsection Item Layout**:

- Title at top (Label).
- **Image area** (TextureRect) - Shows image if image_path is set, hidden otherwise.
- Content text below (RichTextLabel).
- **Image proportions**: Maintain aspect ratio, max width ~500px (scrollable if needed).

## Data Structure

### GuideSectionData (Resource)

```gdscript
class_name GuideSectionData extends Resource

@export var section_id: String = "movement"
@export var title: String = "Movement & Camera"
@export var icon: Texture2D  # Optional
@export var subsections: Array[GuideSubsectionData] = []
```

### GuideSubsectionData (Resource)

```gdscript
class_name GuideSubsectionData extends Resource

@export var subsection_id: String = "keyboard_controls"
@export var title: String = "Keyboard Controls"
@export var content: String = "Use WASD or arrow keys to move..."  # Supports BBCode
@export var image: Texture2D  # Optional - image to display alongside text
```

### Guide Content Organization

```
res://data/guide/
├── movement.tres              (GuideSectionData)
├── inventory.tres             (GuideSectionData)
├── combat.tres                (GuideSectionData)
├── crafting.tres              (GuideSectionData)
├── mining.tres                (GuideSectionData)
├── npc_interaction.tres       (GuideSectionData)
├── building.tres              (GuideSectionData)
├── magic.tres                 (GuideSectionData)
└── world_mechanics.tres       (GuideSectionData)
```

## Script Components

### GuideDataManager (Singleton/Autoload)

```gdscript
class_name GuideDataManager extends Node

var sections: Dictionary = {} # { section_id: GuideSectionData }

func _ready() -> void:
    _load_all_guide_resources()

func _load_all_guide_resources() -> void:
    # Load all .tres files from res://data/guide/ directory
    var dir = DirAccess.open("res://data/guide/")
    if dir:
        dir.list_dir_begin()
        while true:
            var file = dir.get_next()
            if file.is_empty():
                break
            if file.ends_with(".tres"):
                var resource = load("res://data/guide/" + file)
                if resource is GuideSectionData:
                    sections[resource.section_id] = resource

func get_all_sections() -> Array[GuideSectionData]:
    return sections.values()

func get_section(section_id: String) -> GuideSectionData:
    return sections.get(section_id)
```

### GameplayGuideWindow (Modal Scene & Script)

```gdscript
class_name GameplayGuideWindow extends Control

@onready var close_button = %CloseButton
@onready var section_container = %SectionContainer
@onready var background_overlay = %BackgroundOverlay

var is_open: bool = false

func _ready() -> void:
    close_button.pressed.connect(_on_close_pressed)
    _populate_sections()

func _populate_sections() -> void:
    var sections = GuideDataManager.get_all_sections()
    for section_data in sections:
        var section_item = create_section_item(section_data)
        section_container.add_child(section_item)

func create_section_item(section_data: GuideSectionData) -> Control:
    # Instantiate GuideSectionItem scene and populate with data
    pass

func open() -> void:
    if is_open:
        return
    is_open = true
    show()
    _pause_game()
    _animate_in()

func close() -> void:
    if not is_open:
        return
    is_open = false
    _animate_out()
    _unpause_game()
    hide()

func _pause_game() -> void:
    get_tree().paused = true  # Or call PauseManager.pause()

func _unpause_game() -> void:
    get_tree().paused = false  # Or call PauseManager.unpause()

func _animate_in() -> void:
    # Fade in animation (modulate.a from 0.0 to 1.0)
    pass

func _animate_out() -> void:
    # Fade out animation (modulate.a from 1.0 to 0.0)
    pass

func _on_close_pressed() -> void:
    close()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        close()
        get_tree().root.set_input_as_handled()
```

### GuideSectionItem (Collapsible Item)

```gdscript
class_name GuideSectionItem extends Control

@onready var header_button = %HeaderButton
@onready var content_container = %ContentContainer

var section_data: GuideSectionData
var is_expanded: bool = false

func _ready() -> void:
    header_button.pressed.connect(_on_header_pressed)

func set_section_data(data: GuideSectionData) -> void:
    section_data = data
    header_button.text = "▶ " + data.title
    _populate_content()

func _populate_content() -> void:
    for subsection in section_data.subsections:
        var subsection_item = create_subsection_item(subsection)
        content_container.add_child(subsection_item)

func create_subsection_item(subsection_data: GuideSubsectionData) -> Control:
    # Instantiate GuideSubsectionItem scene
    pass

func _on_header_pressed() -> void:
    toggle_expand()

func toggle_expand() -> void:
    is_expanded = !is_expanded
    header_button.text = ("▼ " if is_expanded else "▶ ") + section_data.title
    content_container.visible = is_expanded
```

### GuideSubsectionItem (Content Display with Image Support)

```gdscript
class_name GuideSubsectionItem extends Control

@onready var title_label = %TitleLabel
@onready var image_rect = %ImageRect
@onready var content_label = %ContentLabel

var subsection_data: GuideSubsectionData

func _ready() -> void:
    pass

func set_subsection_data(data: GuideSubsectionData) -> void:
    subsection_data = data
    title_label.text = data.title
    content_label.text = data.content

    # Handle image display
    if data.image != null:
        image_rect.texture = data.image
        image_rect.show()
    else:
        image_rect.hide()
```

## Pause & Input Handling

### Pause Integration

- When guide window opens, set `get_tree().paused = true`.
- When guide window closes, set `get_tree().paused = false`.
- Ensure ESC key closes the guide (prioritize guide window closing over pause menu if both are open).

### Input Events

- **Click GuideButton**: Open guide window.
- **Click Header**: Expand/collapse section.
- **Click Close Button (X)**: Close guide window.
- **Press ESC**: Close guide window.
- **Keyboard Navigation (Future)**: Arrow keys to navigate sections, Enter to expand/collapse.

## Content & Localization

### Guide Content Format

Each subsection's content should support:

- Plain text
- BBCode formatting (bold, italic, color, alignment)
- Line breaks and spacing
- Example: `"Use [b]WASD[/b] or [color=yellow]arrow keys[/color] to move."`

### Localization Hook

For future i18n support, content should reference translation keys:

```gdscript
@export var content_key: String = "guide.movement.keyboard_controls"
# In script: content = tr(content_key)
```

## Visual Styling

### Colors & Theme

- **Section Headers**: Slightly darker or accent color (e.g., white or light yellow text).
- **Content Text**: White or light gray.
- **Background Overlay**: 70–80% opacity dark color.
- **Modal Window Background**: Slightly transparent dark panel (e.g., #1a1a1a with 90% opacity).
- **Hover Effects**: Slight color tint or background highlight.

### Animations

- **Open**: Fade-in duration ~0.3s; optional slight scale-up.
- **Close**: Fade-out duration ~0.2s.
- **Section Toggle**: No animation by default (instant expand/collapse); optional subtle height animation.

## Edge Cases & Fallbacks

### Missing Guide Content

- If a section's `.tres` file is missing, log warning and skip that section.
- Ensure game remains playable even if guide data fails to load.

### Missing Images

- If a subsection's `image` field is not set or the texture file is missing, the TextureRect is automatically hidden.
- Content text will display normally without the image.
- No errors should occur in the console.

### Image Sizing & Scaling

- Images are displayed using TextureRect with `expand_mode = IGNORE_SIZE` or custom aspect ratio control.
- Maximum image width: ~500px (or ~80% of window width).
- Images automatically scale to fit container while maintaining aspect ratio.
- Very large images will be truncated by scrollbar (user can scroll to see full image).

### UI Clipping

- For very long content, ensure scrollbar is visible and functional.
- Test on resolutions down to 1024×768.

### Keyboard Navigation

- Ensure focus/outline is visible when using keyboard to navigate sections.
- Provide visual feedback when hovering over clickable elements.

## Files to Create/Modify

### New Files

- `scenes/ui/guide_button.tscn` + `guide_button.gd`
- `scenes/ui/gameplay_guide_window.tscn` + `gameplay_guide_window.gd`
- `scenes/ui/guide_section_item.tscn` + `guide_section_item.gd`
- `scenes/ui/guide_subsection_item.tscn` + `guide_subsection_item.gd`
- `src/systems/guide_data_manager.gd` (or similar path)
- `data/guide/*.tres` (guide content resources)
- `data/guide/images/` (directory for storing guide images/textures)

### Modified Files

- `scenes/ui/hud.tscn`: Add GuideButton.
- `scenes/ui/hud.gd`: Add methods to open/close guide window.
- `project.godot`: Register `GuideDataManager` as Autoload (if using singleton pattern).

## Content Editing Guide for Users

### How to Edit Guide Content

1. **Open a guide section resource** (e.g., `res://data/guide/movement.tres`) in the Godot inspector.
2. **For each subsection**:
   - **Title**: Edit the subsection title text.
   - **Content**: Edit the content text (supports BBCode formatting like `[b]bold[/b]`, `[color=yellow]colored text[/color]`).
   - **Image**:
     - Drag and drop a PNG/JPG texture from `res://data/guide/images/` into the `image` field.
     - Or click the folder icon and select an image file.
     - Leave blank if you don't want to display an image for this subsection.

3. **To add a new subsection**:
   - Click "+ Add Element" in the subsections array.
   - Set title, content, and optionally an image.

4. **Image preparation**:
   - Store images in `res://data/guide/images/` folder.
   - Supported formats: PNG, JPG.
   - Recommended size: 400-600px wide (will be scaled proportionally).
   - Use descriptive names (e.g., `movement_wasd_keys.png`).

5. **BBCode formatting reference** (for content text):
   - `[b]...[/b]` — Bold
   - `[i]...[/i]` — Italic
   - `[color=yellow]...[/color]` — Colored text
   - `[center]...[/center]` — Center alignment
   - `[br]` — Line break
   - Example: `"Press [b]WASD[/b] or [color=yellow]arrow keys[/color] to move."`

## Success Criteria (MVP)

1. ✓ Guide button visible in top-left HUD corner.
2. ✓ Clicking button opens modal window.
3. ✓ Window shows at least 3 expandable sections.
4. ✓ Toggling sections expands/collapses content.
5. ✓ **Subsections display text + image (if image_path is set).**
6. ✓ **Images are properly scaled and maintain aspect ratio.**
7. ✓ **Missing images are gracefully handled (TextureRect hidden if no image).**
8. ✓ Closing guide unpauses the game.
9. ✓ ESC key closes guide window.
10. ✓ Guide content (text + images) is readable and well-formatted.
11. ✓ Content is editable via `.tres` Resource files (no code changes needed).
