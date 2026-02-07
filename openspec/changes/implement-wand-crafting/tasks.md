# Tasks: Implement Wand Crafting

## Core Data & Logic
- [x] Define `WandEmbryo` Resource (Level, Capacities). <!-- id: 1 -->
- [x] Define `WandData` Resource (Visuals, Logic, Stats). <!-- id: 2 -->
- [x] Implement `SpellPayload` class to store attack state (dmg, speed, modifiers). <!-- id: 3 -->
- [x] Implement `spell_processor.gd` to run the logic chain. <!-- id: 4 -->

## Backend Systems
- [x] Create `WandRenderer` scene (SubViewport setup) to generate textures from `WandData`. <!-- id: 5 -->
- [x] Create Material definitions for Logic Parts (e.g., "Fire Ruby" = Add Fire). <!-- id: 6 -->

## UI Implementation
- [x] Create `WandEditor` main layout (Toggle between Visual/Logic). <!-- id: 7 -->
- [x] Implement `VisualGrid` (Click to place blocks). <!-- id: 8 -->
- [x] Implement `LogicBoard` (Slots for circuit). <!-- id: 9 -->
- [x] Implement `MaterialSelector` (UI to pick items from inventory). <!-- id: 10 -->

## Integration
- [x] Update `Player` scene to hold a `WandSprite`. <!-- id: 11 -->
- [x] Connect `Player` attack input to `spell_processor.gd`. <!-- id: 12 -->
- [x] Add keybind 'C' to open `WandEditor`. <!-- id: 13 -->

## Validation
- [ ] Test: Craft a wand, draw a shape, see it in hand. <!-- id: 14 -->
- [ ] Test: Add "Projectile" logic, fire it. <!-- id: 15 -->
- [ ] Test: Add modifiers, verify damage change. <!-- id: 16 -->
