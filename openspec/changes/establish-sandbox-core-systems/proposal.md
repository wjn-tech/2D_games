# Proposal: Establish Sandbox Core Systems

## Problem
The current project has basic movement and UI but lacks the deep, interconnected systems required for a full sandbox experience. To fulfill the vision of a "living world," we need to implement 14 core systems ranging from procedural generation and settlement building to lineage and industrial automation.

## Proposed Changes
This proposal establishes the architectural foundation and initial implementation for 14 core sandbox systems. These systems are designed to be modular, data-driven, and visually interactive.

### Core Systems to be Implemented:
1.  **World Exploration & NPCs**: Procedural world with dynamic NPC alignments, dialogue, and quest systems.
2.  **Settlement Building**: Recruitment of NPCs, job assignments, and magnet-based item pickup.
3.  **Layered Combat**: Physical parallel planes accessible via doors, with cross-layer enemy AI.
4.  **Marriage & Lineage**: Relationship building, weighted attribute inheritance, and child training.
5.  **Attribute System**: Comprehensive stats (Str, Agi, Int, Con) and a lifespan system affected by actions.
6.  **Inheritance**: Reincarnation into offspring with attribute bonuses and equipment retention.
7.  **Crafting & Alchemy**: Station-based manufacturing for gear, medicine, and ammo.
8.  **Gathering & Trading**: Resource collection and economic interaction with merchants.
9.  **Weather & Ecology**: Environmental impacts on gameplay and a simple biological food chain.
10. **Formations & Industrial Circuits**: Tactical combat buffs/defenses and Factorio-style automation with energy requirements.

## Impact
- **Architecture**: Introduces a robust "Component-based" approach for NPCs and Buildings.
- **Data**: Extensive use of `Resource` files for items, recipes, and NPC profiles.
- **Gameplay**: Transitions the game from a platformer to a complex sandbox RPG.

## Verification Plan
- **Manual**: Each system will have a dedicated test scene (e.g., `CombatTest.tscn`, `IndustrialTest.tscn`).
- **Integration**: A "Vertical Slice" scene combining gathering, crafting, and building.
