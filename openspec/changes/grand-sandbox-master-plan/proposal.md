# Proposal: Grand Sandbox Master Plan

Re-architect the project into a comprehensive 2D sandbox RPG featuring world exploration, city-building, lineage survival, complex industry, and tactical combat.

## Why
The previous scope was focused on specific voxel/cellular mechanics (Noita style). The new vision expands this into a "Life Simulation Sandbox" where character legacy, social structures, and large-scale automation form the core gameplay loop.

## Proposed Changes: The 15-Step Roadmap

### Phase 1: Foundation (Systems 1-3)
1.  **[01-universal-physics-layer-system]**: Standardized physics layers for 3-depth world collision & interaction (Surface, Underground, Deep).
2.  **[02-character-attribute-engine]**: Core attributes (Strength, Charisma, Lifespan) with a backend for stat scaling.
3.  **[03-world-chronometer-and-weather]**: Global time progression (Calendar) and weather system integration (Rain, Thunder, Snow).

### Phase 2: Agency & World Interaction (Systems 4-6)
4.  **[04-npc-behavior-and-factions]**: AI personality framework supporting Hostile, Neutral, and Allied states.
5.  **[05-resource-gathering-and-ecology]**: Tool-based harvesting (Minable rocks, Choppable trees) and ecological regrowth.
6.  **[06-trading-and-economy]**: Barter system with merchant NPCs and dynamic item pricing.

### Phase 3: Manufacturing & Construction (Systems 7-9)
7.  **[07-crafting-forging-alchemy]**: Production stations for specialized gear, medicines, and ammunition.
8.  **[08-building-and-city-blueprint]**: Modular building system allowing players to establish and name their own City-States.
9.  **[09-layer-combat-mechanics]**: Tactical 2D combat utilizing "Layer Doors" to switch between foreground/background depths.

### Phase 4: Social & Lineage (Systems 10-12)
10. **[10-social-marriage-system]**: Relationship affinity system (Friendship -> Marriage) for eligible NPCs.
11. **[11-heredity-and-breeding]**: Offspring system where children inherit genetic traits and require physical training.
12. **[12-succession-and-legacy]**: Transition mechanic where player control shifts to a chosen child upon natural death.

### Phase 5: Advanced Automation & Tactics (Systems 13-15)
13. **[13-tactical-formation-arrays]**: Area-of-effect "Arrays" (阵法) triggered by specific tile patterns or ritual items.
14. **[14-industrial-circuit-logic]**: Conductive logic signals (Redstone style) for complex city automation.
15. **[15-ecosystem-equilibrium]**: Final integration of wildlife migrations, resource exhaustion, and biome shifts.

## Impact
- **Gameplay**: Infinite replayability through dynasty management and creative engineering.
- **Narrative**: Emergent stories created by NPC interactions and city growth.

## Acceptance Criteria
- [ ] Each of the 15 sub-projects is defined with its own OpenSpec Change Proposal.
- [ ] Systems interact through a unified EventBus (Decoupled architecture).
