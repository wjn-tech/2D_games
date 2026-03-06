# Requirements

## ADDED Requirements

### Requirement: Visual Tutorial Overlay
The system MUST provide a comprehensive overlay to highlight UI elements.

#### Scenario: Highlighting a Specific Palette Item
Given the player is in the Tutorial Sequence and has opened the Wand Editor
When the dialogue instructs "Drag the TRIGGER component"
Then a dimming overlay appears (darkening non-essential UI)
And the "Trigger" palette button is **highlighted** (bright, pulsing border)
And a label "Drag to Grid" appears near the button.

#### Scenario: Connecting Logic Nodes
Given the player is in the "Program Wand" phase
When the dialogue instructs "Connect them"
Then the **output port** of the Trigger node and **input port** of the Projectile node are highlighted
And an animated arrow points from Trigger -> Projectile.

## MODIFIED Requirements

### Requirement: Tutorial Flow
The tutorial sequence MUST validate user actions and provide correction.

#### Scenario: Failing to Connect Correctly
Given the player connects Trigger -> Trigger (invalid loop)
When the connection is made
Then a **warning tooltip** appears: "Invalid Connection: Connect Trigger -> Projectile!"
And the highlight remains on the correct ports.
