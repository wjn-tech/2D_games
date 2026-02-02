# Design: NPC Spawning and Ecology

## Overview
The system moves away from a simplistic periodic timer and uses a mix of spatial and environmental triggers.

## Spatial Spawning
The `NPCSpawner` will subscribe to player movement. Every 1000 units of horizontal/vertical displacement, a "Spawn Wave" is evaluated.
This évaluation checks:
1. Current Mob Count vs Global Cap.
2. Probability based on current Biome/Time.

## Environmental Validation
To ensure NPCs spawn only on open ground:
- The spawner uses a 2D raycast to find solid ground on the Foreground layer (`LAYER_WORLD_0`).
- Once a collision is found, it converts the hit position to map coordinates.
- It verifies that the cell *at/above* the hit position in the Foreground `TileMapLayer` is empty (`source_id == -1`). This prevents spawning inside solid blocks.
- Spawning is invalid if the raycast hits nothing (e.g., in middle of the sky with no background) unless specific "flyer" logic is added later.

## Visual Feedback
Hostile NPCs use `modulate = Color(1.0, 0.4, 0.4)` (Standard red tint) to indicate hostility. This is applied at `_ready` based on `CharacterData.alignment`.
