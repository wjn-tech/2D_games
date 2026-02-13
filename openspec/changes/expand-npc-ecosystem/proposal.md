# Proposal: Expand NPC Ecosystem

## Problem Statement
The current NPC ecosystem is functional but feels sparse. Most NPCs share similar skeletal behaviors, and variety is limited to a few types (Slime, Skeleton, generic Villager). To make the world feel alive and reactive, we need a significant increase in both the quantity of NPCs and the distinct roles/behaviors they exhibit.

## Proposed Changes
1.  **Variety Expansion (Hostile & Friendly)**:
    - **Hostile**: Introduce Ranged units (Archers), Fast/Flyers (Bats), and Tank/Heavy units.
    - **Friendly**: Introduce standard Roles: `Guard` (combat capable), `Merchant` (trade), `Wizard` (magical services/combat), and `Peasant` (background flavor).
2.  **Visual Distinction (Minimalist Accessories)**:
    - Add simple geometric accessories to identify roles: Shields for guards, packs for merchants, and staves/hats for wizards.
3.  **Spawner Scaling**:
    - Increase `area_capacity` and implement biome-aware density scaling.
    - Add "Herd Spawning": Allowing specific species to spawn in clusters of 3-5.
    - All NPCs (including guards/wizards) will spawn naturally in appropriate biomes.
4.  **Performance Optimization (AI LoD)**:
    - Implement a "Level of Detail" system for AI: NPCs far from the player will switch to a lightweight simulation mode to save CPU.

## Expected Outcome
A more vibrant and dangerous world where towns feel populated with diverse NPCs and wilderness areas present varying challenges through different group combinations and combat styles.
