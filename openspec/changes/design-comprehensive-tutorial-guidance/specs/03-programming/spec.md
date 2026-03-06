# Spec: Wand Programming Guidance

## ADDED Requirements

### Requirement: Wand Editor Interaction
The tutorial system MUST guide the player through the complex task of wand programming with step-by-step visual cues.

#### Scenario: Open Editor Prompt
-   **Given** the tutorial state is `wait_editor`.
-   **When** the player must open the Logic Interface.
-   **Then** the "K" key icon should appear and pulse on screen.
-   **And** the "Wand Logic" HUD button (if visible) should be highlighted.

#### Scenario: Component Highlighting
-   **Given** the editor is open and the step is `place_trigger`.
-   **When** the pallete contains a **Trigger Component**.
-   **Then** the **Trigger Button** in the palette MUST pulse with a high-contrast border.
-   **And** a **Ghost Cursor** MUST animate dragging from the palette button to grid cell (2, 2).

#### Scenario: Connection Guidance
-   **Given** both Trigger and Projectile nodes are placed.
-   **When** the step advanced to `connect_nodes`.
-   **Then** a **Ghost Wire** MUST animate repeatedly drawing a line from the Trigger's output port to the Projectile's input port.
-   **And** a pulsing tooltip "Connect Ports" MUST float near the connection path.

#### Scenario: Immediate Success Feedback
-   **Given** the connection is required.
-   **When** the player makes a valid connection (Trigger -> Projectile).
-   **Then** the tutorial manager should IMMEDIATELY show a "Configuration Validated" success banner.
-   **And** advance the tutorial sequence without delay.
