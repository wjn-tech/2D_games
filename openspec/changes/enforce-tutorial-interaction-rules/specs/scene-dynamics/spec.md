# Spec: Scene Dynamics & Destruction

## Overview
Implement a dynamic system that visually degrades the ship environment as the tutorial progresses.

## ADDED Requirements

#### Scenario: Environmental Destruction (Scene Dynamics)
- **GIVEN** a specific tutorial phase (e.g., `Phase.COMBAT` or `Phase.CRASH`)
- **THEN** script-controlled debris (`TileMapLayer` or `Sprite2D` rubble) must appear.
- **AND** existing "clean" walls/floors at designated coordinates (e.g., Grid(5,5)) must be replaced by "damaged" variants or removed entirely.
- **AND** particle effects (`FireParticles.tscn`, `SparkConfig.tscn`) must spawn at these coordinates.

#### Scenario: Dynamic Lighting (Alert State)
- **GIVEN** `EnvironmentController`
- **WHEN** `GlobalEvent.alert_level` changes (triggered by `TutorialSequenceManager`)
- **THEN** modulatethe `CanvasModulate` color (e.g., from Blue/Teal `Normal` -> Red/Orange `Alert`).
- **AND** activate pulsing alarms (light intensity animation).

#### Scenario: Screen Shake (Impact)
- **GIVEN** a destructive event (e.g., "Explosion")
- **THEN** trigger a randomized `Camera2D.offset` shake for `duration` seconds.
- **AND** intensity should scale with the event type ("Minor tremor" vs "Hull Breach").

## MODIFIED Requirements

#### Scenario: Tile Interaction
- **GIVEN** `Tutorial` scene structure
- **THEN** ensure critical path tiles are distinct layers or groups to allow easy script access for "breaking" them.
