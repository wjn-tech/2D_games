## ADDED Requirements

### Requirement: Menu Background Visuals
The system SHALL provide a configurable menu background that renders a layered starfield with animated concentric rings and a subtle nebula effect.

#### Scenario: Background animates on menu open
- **WHEN** the `MainMenu` scene becomes visible
- **THEN** the background shader SHALL animate rings and stars continuously
- **AND** the shader SHALL expose `star_density`, `ring_count`, `nebula_strength`, and `use_noise` parameters for runtime tuning

#### Scenario: Low quality fallback
- **WHEN** the system detects low frame time budget or shader compile failure
- **THEN** the menu SHALL switch to a low-quality preset with reduced `star_density` and `use_noise=false`

### Requirement: Button Visuals and Behavior
Buttons in the menu SHALL present multi-layer visuals: an outer soft glow, a primary StyleBox for body, an inner shader-based highlight, and a subtle bottom shadow.

#### Scenario: Hover and press feedback
- **WHEN** the pointer hovers a button
- **THEN** the button SHALL animate to hover state within 0.18–0.28 seconds (scale, glow alpha, color modulation)
- **WHEN** the button is pressed
- **THEN** the button SHALL transition to pressed state within 0.08–0.12 seconds and provide a stronger depth cue (shadow/scale)

### Requirement: Icon Placement and Clipping
SVG icons used in menu buttons SHALL be children of their corresponding `Button` node as `TextureRect` nodes and SHALL be clipped by the button's content area.

#### Scenario: Icon is hidden when menu obscured
- **WHEN** another UI panel overlays the menu or the menu is hidden
- **THEN** the icon SHALL NOT be visible above the overlay (icons must not float)

### Requirement: Animated Text Gradient
Text elements for title, welcome label, and button text SHALL support an animated gradient shader with a `time` parameter; the animation SHALL be controllable and have configurable noise strength.

#### Scenario: Gradient animates
- **WHEN** `MainMenu` is active
- **THEN** title and designated text elements SHALL update their shader `time` parameter each frame to animate the gradient

### Requirement: Godot 4 Compatibility
All script changes SHALL use Godot 4 APIs: properties like `custom_minimum_size` instead of removed `rect_min_size`, avoid removed methods like `add_theme_style_override`, and do not reference removed constants (e.g., `Button.ICON_*`).

#### Scenario: No deprecated API usage
- **WHEN** running static analysis or loading scenes in Godot 4.5
- **THEN** there SHALL be no runtime errors caused by deprecated properties or missing members used by the changes
