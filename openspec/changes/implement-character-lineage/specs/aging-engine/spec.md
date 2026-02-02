# Capability: Aging Engine

Track world time and apply physical age to the player character.

## ADDED Requirements

### Requirement: Time Tracking
The `WorldTimeManager` SHALL track game years, where 1 year equals 20 game days.
#### Scenario: Year rolls over
- GIVEN the current day is 20
- WHEN a new day begins
- THEN the `year` SHALL increment by 1.

### Requirement: Natural Death
The player MUST die of old age when their age exceeds a randomized threshold.
#### Scenario: Character expires
- GIVEN a character at age 75 with a death threshold of 75
- WHEN the next year begins
- THEN the game SHALL freeze and trigger the `SuccessionSequence`.
