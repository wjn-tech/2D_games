# Spec: World Chronometer

## Capability: Time Management
The system must track global simulation time and provide calendar-based milestones.

### ADDED Requirements

#### 1. Global Calendar Logic
- Requirement: The system tracks Minutes, Hours, Days, and Years.
- #### Scenario: Time Advancement
    - Given the game is running
    - When 60 real seconds pass (default `time_scale`)
    - Then the system must increment 1 game hour.
    - And emit a `hour_passed` signal via `EventBus`.

#### 2. HUD Integration
- Requirement: Current game time must be visible to the player.
- #### Scenario: UI Sync
    - Given the `WorldInfoUI` is active
    - When the `Chronometer` updates the date
    - Then the Label text must update to "Year X, Day Y - HH:MM".
