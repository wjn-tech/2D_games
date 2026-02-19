## ADDED Requirements

1. Requirement: Provide a shared palette resource and replace inline color literals

#### Scenario: Palette usage
- Given `assets/ui/palette.tres` exists and MainMenu scene is open
- When the scene is loaded in editor
- Then UI color properties (gradients, button fills, glow colors) reference the palette resource instead of inline hex literals.

2. Requirement: Replace purple with approved blue tokens

#### Scenario: Theme substitution
- Given existing theme contains purple tokens
- When the palette is applied
- Then all purple occurrences used by MainMenu are replaced with corresponding blue tokens and visual regression images are produced for comparison.
