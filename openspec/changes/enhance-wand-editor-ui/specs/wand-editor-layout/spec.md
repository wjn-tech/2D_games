# Spec: Wand Editor Layout Enhancements

## MODIFIED Requirements

#### Requirement: Balanced Full-Screen Workspace
The editor layout must be restructured to provide focus on the workspace (Grid/Board) while keeping information panels legible.

#### Scenario: Spacing & Padding
- All top-level UI containers inside `WandEditor` must have a minimum padding of `20px` from screen edges.
- The `StatsPanel` must have a fixed minimum width of `250px` to prevent text truncation in the "Modern Magic Industry" style.

#### Scenario: Grid Visuals
- The `VisualGrid` background should display a subtle cyan blueprint grid pattern.
- The `LogicBoard` (GraphEdit) must have its grid color adjusted to `RGBA(51, 204, 255, 26)` for a high-tech circuit feel.
