# Capability: Stabilization Strategy

Guidelines for prioritizing existing code over new features.

## ADDED Requirements

### Requirement: Codebase Leverage
The development SHALL prioritize bringing existing 50%+ modules to 100% before starting 0% modules.
#### Scenario: Choosing next task
- GIVEN a choice between starting "Marriage System" (0%) and finishing "Weather System" (90%)
- THEN the developer MUST choose finishing the "Weather System".

### Requirement: System Interconnectivity
Newly completed modules MUST be registered with the `EventBus` to notify other systems of state changes.
#### Scenario: Weather Change Notification
- GIVEN a weather transition to `Rain`
- WHEN the transition completes
- THEN a global signal MUST be emitted so that `AttributeEngine` can calculate environment-based debuffs.
