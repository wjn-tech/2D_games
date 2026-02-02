# Design: Modular Sandbox Framework

## Overview
The architecture follows a **Manager-Component-Bus (MCB)** pattern. Each gameplay system (Weather, Combat, Breeding) is a standalone "Manager" that exposes its state via an `EventBus` and consumes data via `Resource` files.

## High-Level Breakdown (The 15 Sub-Projects)

1.  **World Chronometer & HUD**: (Completed Logic) Year/Day/Hour tracking.
2.  **Environment Sync (Weather VFX)**: Particles and Lighting synced to the Chronometer.
3.  **Physical Depth Layers**: Finite depth shifting (Surface, Underground, Deep) using bitmasking.
4.  **Attribute Engine & UI**: Strength, Agility, Lifespan with real-time UI bars.
5.  **Gathering & Economy**: Basic looting, interaction logic, and merchant pricing.
6.  **Genealogy & Lifespan**: Breeding logic, stats inheritance, and character aging/death.
7.  **NPC Social System**: Factions, marriage proposal logic, and relationship values.
8.  **Voxel-lite Digging**: 2D tile-based destruction for mining.
9.  **Settlement Foundation**: Building placement, territory claiming.
10. **Industrial Logic (Conveyors)**: Items moving automatically between containers.
11. **Circuits & Power**: Logic gates (AND/OR) and power consumers.
12. **Multi-layer AI**: NPCs that can navigate between depth layers.
13. **Forging & Crafting**: Recipe-based item creation with quality variants.
14. **Combat Formations**: Squad-based movement and layered combat encounters.
15. **Save/Load Migration**: Ensuring the complex world state (including time and lineage) persists.

## Data Flow
1.  **Chronometer** emits `minute_passed`.
2.  **WeatherManager** updates state, emits `weather_changed`.
3.  **UI/HUD** catches signals and updates labels.
4.  **Particles** (Managed by User via Editor) respond to weather states.

## Trade-offs
- **Pros**: Highly decoupled; easy to test individual systems in isolation.
- **Cons**: High initial boilerplate for each new manager; dependent on `EventBus` singleton.
