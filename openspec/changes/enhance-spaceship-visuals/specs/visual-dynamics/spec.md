# Spec: Spaceship Visual Dynamics

## Overview
This spec defines the requirements for the high-fidelity spaceship environment and its dynamic reactivity.

## ADDED Requirements

### Requirement: Industrial Sci-Fi Environment
The spaceship textual representation MUST be replaced with detailed graphical assets.

#### Scenario: Tile-based Structure
> **Given** the tutorial scene loads,
> **Then** the spaceship walls, floor, and ceiling should be rendered using a `TileMapLayer` with a Sci-Fi tileset.
> **And** `Polygon2D` placeholders should be removed (except for specific dynamic blockers if needed).

#### Scenario: Decorative Props
> **Given** the player wakes up,
> **Then** they should see a "Cryo Pod" sprite near the spawn point.
> **And** a "Main Console" sprite near the Court Mage.
> **And** various "Exposed Wires" and "Pipes" along the walls.

### Requirement: Dynamic Lighting & Atmosphere
The environment lighting MUST change to reflect the ship's critical status.

#### Scenario: Emergency Lighting (Red Alert)
> **Given** the ship is in `CRITICAL` or `RED` alert level,
> **Then** the global light (`CanvasModulate`) should initially remain relatively bright (`#808080`) to ensure player visibility.
> **And** Red emergency lights should flash/rotate vigorously to provide contrast.
> **And** Key interactive objects (Consoles) should have their own local glow.

#### Scenario: Power Failure Flickering
> **Given** the ship is in `FAILING` state (or during transitions),
> **Then** the lights should randomly flicker (toggle visibility or energy) to simulate power instability.

### Requirement: Dynamic Background (Starfield)
The view outside the ship MUST convey movement/descent.

#### Scenario: Window View
> **Given** the ship structure has windows,
> **Then** a starfield should be visible through them.
> **When** the ship "spirals out of control" (Combat/Crash phase),
> **Then** the starfield background should scroll or rotate rapidly to visually sell the motion.

### Requirement: Interactive Environmental Effects
Particles and physics effects MUST enhance the feeling of destruction.

#### Scenario: Hull Breach (Crash)
> **Given** the "Crash Sequence" begins,
> **Then** visual debris particles should fly horizontally across the screen (simulating suction/wind).
> **And** the camera shake intensity should be maxed out.
> **And** the camera or the entire ship layer should rotate slightly (~15-30 degrees) to simulate loss of gravity control.

> **And** sparks should emit continuously from "Exposed Wire" props.
