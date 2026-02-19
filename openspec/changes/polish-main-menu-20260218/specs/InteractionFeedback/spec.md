## ADDED Requirements

1. Requirement: Buttons must provide hover and pressed feedback

#### Scenario: Hover feedback
- Given the pointer hovers over a button
- When the pointer is stationary over the button
- Then the button displays a soft glow (tinted by current palette accent), and a subtle upward translation (<= 4 px) or scale (<= 1.02x).

#### Scenario: Press feedback
- Given the player clicks a button
- When the input press occurs
- Then the button instantly shows a pressed state (darker fill or inner shadow) and a brief tactile animation (scale down to 0.98x over 80ms).

2. Requirement: Accessible contrast

#### Scenario: Low-vision check
- Given the chosen palette
- When contrast is measured (WCAG AA target for UI text)
- Then all button labels and primary CTAs meet at least AA contrast ratio against their immediate backgrounds.
