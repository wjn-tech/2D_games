# Capability: Climate Simulation

A synchronized system for world time and weather events.

## ADDED Requirements

### Requirement: Chronometer Logic
The world time MUST advance linearly and notify listeners of hour/day changes.
#### Scenario: Midnight Event
- GIVEN the time is 23:59
- WHEN 1 minute passes
- THEN the `day` MUST increment
- AND a `day_started` signal MUST be emitted.

### Requirement: Weather Logic
The weather SHALL transition between states based on weighted probability tables.
#### Scenario: Transition to Rain
- GIVEN a `Clear` weather state
- WHEN the `WeatherManager` triggers a roll
- THEN there MUST be a 20% chance (per probability table) to transition to `Rain`.
