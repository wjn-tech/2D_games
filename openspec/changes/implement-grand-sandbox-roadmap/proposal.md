# Proposal: 15-Project Grand Sandbox Roadmap Implementation

## Meta
- **Change ID**: `implement-grand-sandbox-roadmap`
- **Status**: Draft
- **Author**: GitHub Copilot (Gemini 3 Flash (Preview))
- **Date**: 2026-01-22

## Problem Statement
The project has a massive 14-point RPG vision, but currently lacks a structured roadmap. While "Weather" and "Chronometer" systems are mostly complete, other core pillars like Lineage, Industry, and Multi-layer Combat exist as fragmented pieces or are entirely missing. A unified 15-sub-project roadmap is needed to bridge the gap between the current prototype and the grand vision.

## Proposed Solution
Implement a modular, phased roadmap consisting of 15 sub-projects. Each sub-project focuses on a specific capability, ensuring vertical slices of gameplay are delivered incrementally. 

### Task Completion Policy
To maximize efficiency between the AI and the User:
- **AI (Copilot)**:
    - Responsible for all **GDScript logic** and back-end systems.
    - Creating and configuring **Resources** (item data, NPC stats).
    - Manipulating `.tscn` files for node hierarchies and property settings.
    - Implementing **EventBus** integrations and UI logic scripts.
- **User (Manual)**:
    - **Visual Fine-tuning**: Finalizing UI layouts in the Godot Editor (anchors, offsets).
    - **Art & Animation**: Importing and assigning sprites to `AnimatedSprite2D`, setting up animation frames.
    - **Physical Mapping**: Painting collision masks on `TileMapLayer` or complex `CollisionShape2D` vertex editing.
    - **SFX/VFX**: Importing audio and setting up `AudioStreamPlayer` nodes.

## Scope
- **Phase 01-05: Stabilization & Core Mechanics** (Chronometer, Weather VFX, Layering, Stats UI).
- **Phase 06-10: Social & Genealogy** (NPC Interaction, Breeding, Inheritance).
- **Phase 11-15: Industry & Advanced Systems** (Crafting, Circuits, Settlement management).

## Non-Goals
- Real-time multiplayer networking.
- 3D asset integration.
- Professional voice acting or music production.

## Architecture
See `design.md` for the modular architecture details involving the `EventBus` and `Manager` pattern.
