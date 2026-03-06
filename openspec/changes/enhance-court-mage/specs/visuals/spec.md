## ADDED Requirements

#### Scenario: Floating Idle
-   **Given** the Court Mage is standing still
-   **Then** the character sprite should gently bob up and down (sine wave motion) to simulate hovering/flight.
-   **And** the magical aura particles should be active around them.

#### Scenario: Directional Facing
-   **Given** the Court Mage is moving to the right
-   **Then** the character sprite should face right.
-   **Given** the Court Mage is moving to the left
-   **Then** the character sprite should face left.
