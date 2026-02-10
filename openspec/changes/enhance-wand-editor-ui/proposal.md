# Proposal: Enhance Wand Editor UI (Modern Magic Industry)

## Goal
Transform the Wand Editor UI into a high-fidelity "Modern Magic Industry" interface. This involves a shift from default Godot styles to a cohesive, translucent blue/cyan sci-fi aesthetic using dynamic `StyleBox` components and SVG-based iconography.

## Capabilities
- **Sci-Fi Theme**: A project-wide `Theme` resource featuring translucent dark-blue panels, cyan borders, and subtle "energy" glows.
- **Dynamic StyleBoxes**: All UI elements (Panels, Buttons, Tooltips) will be styled via `StyleBoxFlat` with programmatic border and shadow properties to avoid external asset dependencies.
- **Integrated Iconography**: Use SVG-based placeholders for stats (Mana, Speed, Level) to improve readability and visual interest.
- **Full-Screen Immersion**: Retain the full-screen layout but with improved layout balance (margins, spacing) to create a focused workspace.

## User-Confirmed Constraints
- **Style**: Modern Magic Industry (translucent blue light/sci-fi).
- **Implementation**: Dynamic `StyleBox` (code/resource-driven).
- **Display**: Continuous full-screen mode.
- **Assets**: Temporary SVG icons (procedural or standard Godot icons).

## Proposed Spec Deltas
- `specs/ui-theme`: Project-wide theme definition for sci-fi components.
- `specs/wand-editor-layout`: Specific visual and structural enhancements for the editor.
