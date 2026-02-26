# Spec: Main Menu Experience Polish

## ADDED Requirements

### Requirement: Atmospheric Visuals & Layout
The Main Menu visual hierarchy MUST be updated with a unified sci-fi color palette, distinct visual emphasis on the primary action, and atmospheric background elements to create an immersive experience.

#### Scenario: Visual Hierarchy
-   Given the Main Menu is visible
-   Then the "Start Game" button uses a distinct Gold/Cyan color compared to other blue/white buttons.
-   And the icons match the text color (no black silhouettes).
-   And a Nebula/Glow layer is visible behind the menu list.

### Requirement: Entrance Animation
The Main Menu elements MUST animate into view upon scene load to reduce visual abruptness.

#### Scenario: Staggered Entrance
-   Given the game starts or returns to the Main Menu
-   Then the Title and Buttons fade in and slide up slightly one by one.
-   And the total animation takes approximately 1.0 second.

