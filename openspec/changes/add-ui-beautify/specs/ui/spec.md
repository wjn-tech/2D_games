## ADDED Requirements

### Requirement: Global UI Theme
The project SHALL include a reusable Godot `Theme` resource that defines base colors, a DynamicFont, and control styleboxes for panel and button widgets.

#### Scenario: Apply to WandEditor
- **WHEN** the `theme_default.tres` is set on the `WandEditor` root `Control` node
- **THEN** major panels and buttons use the defined colors, font and style (rounded corners, padding) and no controls break layout.

### Requirement: WandEditor Quick Beautify
`WandEditor` SHALL, when the theme is applied, show the following visual improvements: updated font, rounded panel backgrounds (StyleBoxFlat), and hover/pressed visual transition on primary buttons.

#### Scenario: Visual sanity check
- **WHEN** a reviewer opens `WandEditor` after theme applied
- **THEN** reviewer can capture Before/After screenshots and confirm buttons visibly change on hover and panel background displays rounded corners and consistent padding.

### Requirement: Non-goal – No Logic Changes
This change MUST NOT alter game logic, input handling, or scene node structures beyond assigning `theme` and adding font assets.

#### Scenario: Regression-free
- **WHEN** the theme is applied and user performs core interactions (dragging logic nodes, testing spell, opening wand selector)
- **THEN** all interactions behave identically to pre-change behavior (no errors, no missing nodes)
