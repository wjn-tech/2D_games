# Spec: Weather & Ecology

## Capability: Environmental Modulation
The world environment must respond to weather cycles, affecting visibility, visuals, and character stats.

### ADDED Requirements

#### 1. Weather State Cycling
- Requirement: The system alternates between SUNNY, RAINY, SNOWY, and THUNDERSTORM.
- #### Scenario: Random Weather Change
    - Given the `weather_timer` reaches 0
    - When a new weather is selected
    - Then the `CanvasModulate` color must shift to reflect the mood (e.g., Blue-grey for Rain).

#### 2. Physical Effects
- Requirement: Weather must impact gameplay mechanics.
- #### Scenario: Rain Friction
    - Given it is RAINY
    - When the player is movement-enabled
    - Then their `SPEED` must be reduced by 10%.
