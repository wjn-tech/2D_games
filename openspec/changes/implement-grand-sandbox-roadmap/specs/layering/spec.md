# Spec: Multi-layer Depth System

## Capability: Depth-based Persistence
The world supports multiple physical layers that exist in the same spatial coordinates but different "depths".

### ADDED Requirements

#### 1. Layer Visibility & Interaction
- Requirement: Objects on different layers should not overlap or collide unless specified.
- #### Scenario: Layer Switching
    - Given the player is on layer 1 (Surface)
    - When they enter a "Layer Door" to layer 2 (Underground)
    - Then their `collision_layer` bit must change.
    - And objects on layer 1 must become transparent or hidden.
