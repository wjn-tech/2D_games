# Requirements

## ADDED Requirements

### Requirement: Cinematic Atmosphere
The environment MUST react to the narrative state with escalating danger cues.

#### Scenario: Waking on the Crashing Ship
Given the player starts the tutorial
When the scene initializes
Then the **screen** shakes violently (screenshake level 3)
And **red emergency lights** flash (Alert Level 2)
And **spark particles** emit from random points on the walls.

#### Scenario: The Court Mage's Struggle
Given the player approaches the Court Mage
When dialogue starts
Then the Court Mage plays a **straining animation** (holding a barrier)
And a visible **magical shield** extends from the Mage to the Hull Breach point.

## MODIFIED Requirements

### Requirement: Wand Editor Focus Mode
The game world MUST calm down to facilitate learning when complex UIs are open.

#### Scenario: Programming amidst Chaos
Given the ship is in **Critical Alert** (screenshake, loud alarms)
When the player opens the Wand Editor
Then the **screen shake** reduces to near-zero (Focus Mode)
And the **ambient sound** becomes muffled (Low-pass filter)
And the **lighting** shifts to a calm blue/purple vignette.

#### Scenario: Leaving Focus Mode
Given the player closes the Wand Editor
When the UI vanishes
Then the **screen shake** and **alarms** instantly resume at full intensity.
