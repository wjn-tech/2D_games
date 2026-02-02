# Capability: Global Vision

The high-level roadmap and architectural vision for the game.

## ADDED Requirements

### Requirement: Roadmap Adherence
The project SHALL be developed following the 15-sub-project roadmap defined in the master plan.
#### Scenario: Checking progress
- GIVEN the current development phase
- WHEN inspecting the completed change IDs
- THEN they MUST align with the sequential roadmap order (01 through 15).

### Requirement: System Decoupling
All major game systems MUST communicate via the `EventBus` to ensure modularity.
#### Scenario: Environmental reaction
- GIVEN a weather change occurs
- WHEN the `WeatherManager` emits a signal
- THEN independent systems like `NpcBehavior` MUST respond without direct references to the `WeatherManager`.
