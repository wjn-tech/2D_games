# Tasks

1.  **Create New Shader**
    - [x] Create `assets/ui/shaders/gradient_advanced.gdshader`. (Renamed to `gradient_vertical_shimmer.gdshader`)
    - [x] Support `vec4` stops (4) and angle/direction `float`. (Vertical mix + Shimmer implemented)
    - [x] Support simple animation (time-based shimmer/glow)?

2.  **Create Material for MainMenu**
    - [x] Create `assets/ui/materials/title_gradient_mainmenu.tres` with `gradient_advanced.gdshader`. (Modified `MainMenu.tscn` directly)
    - [x] Assign existing `color_start` and `color_end` (Blue/Pink) interpolated to 4 stops (Blue/Purple/Violet/Pink). (Used 2-stop mix, user preference)

3.  **Update MainMenu.tscn**
    - [x] Open `scenes/ui/MainMenu.tscn`.
    - [x] Assign new Material to `CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Title` label.
    - [ ] Adjust `font_size` or shader parameters to match React style (Vertical alignment, shadowing). (Shader params set)

4.  **Verification**
    - [ ] Verify `MainMenu` title looks significantly better and more dynamic.
    - [ ] Check if `SettingsWindow` also needs this later (Out of scope for this change).
