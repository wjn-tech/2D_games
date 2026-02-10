# Visual Conveyance System

## ADDED Requirements

#### Scenario: Progressive Disclosure by Distance
Given the player approaches an NPC
When the distance is > 10 units
Then no UI elements should be visible
When the distance is between 5 and 10 units
Then a floating icon representing the NPC's occupation should appear
When the distance is < 5 units (Interaction Range)
Then the full Nameplate and Context Prompt (e.g. "E to Talk") should appear

#### Scenario: Relationship Ring Visualization
Given an NPC with a Relationship Level of 80 (Friendly)
When the `MinimalistEntity` is drawn
Then a green (Friendly color) arc or ring should be drawn around the entity
And the ring's completeness should represent the exact level (80%)

#### Scenario: Occupation Badge
Given an NPC is a Merchant
When the `MinimalistEntity` is rendered
Then a small "Bag" or "Coin" icon/badge should be drawn overlaying the entity shape
