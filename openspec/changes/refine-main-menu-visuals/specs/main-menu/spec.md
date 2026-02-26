# Main Menu UI Spec

## ADDED Requirements

### Requirement: Minimalist Visual Style
The Main Menu MUST adopt a minimalist, "Arcane-inspired" visual style. The menu list MUST NOT have a visible solid background panel. Text should appear floating directly over the background. The primary action (e.g., "Start Game") MUST be visually distinct from secondary actions.

#### Scenario: Menu Appearance
-   Given the game is running and Main Menu is visible
-   Then the menu buttons ("Start", "Options", etc.) appear as text over the animated background without a box around them.

#### Scenario: Start Button
-   Given the User looks at the menu
-   Then the "Start Game" button appears slightly larger or brighter than "Exit".

### Requirement: Interactive Feedback
The Main Menu buttons MUST provide rich feedback. Buttons MUST react to mouse hover with a transformation (scale or position) or brightness change, not just a colored box overlay.

#### Scenario: Hovering
-   Given the User moves the mouse over "Options"
-   Then the text gently scales up (e.g., 1.1x) or increases in brightness.
-   When the mouse leaves, it returns to normal.

### Requirement: Center Layout
The Main Menu layout MUST be centered horizontally on the screen.

#### Scenario: Layout alignment
-   Given the resizing of the window
-   Then the menu column remains exactly in the horizontal center of the viewport.
