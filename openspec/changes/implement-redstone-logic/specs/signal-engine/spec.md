# Capability: Signal Engine

The core simulation for logic propagation across tiles.

## ADDED Requirements

### Requirement: Wire Conductivity
Wires MUST conduct signals to adjacent wire tiles.
#### Scenario: Powering a line
- GIVEN a lever next to a wire
- WHEN the lever is turned ON
- THEN the wire MUST become energized.
- AND the signal SHALL propagate to the end of the line.

### Requirement: Logic Processing
Logic gates SHALL correctly process signals based on truth tables.
#### Scenario: Using a NOT gate
- GIVEN a NOT gate with an input of 1
- THEN it MUST emit a signal of 0.
