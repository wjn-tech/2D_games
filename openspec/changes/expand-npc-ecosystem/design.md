# Design: NPC Ecosystem Expansion

## Architecture

### 1. Unified NPC Classification
We will extend `npc_type` strings:
- **Friendly**: `villager_peasant`, `villager_guard`, `villager_merchant`, `villager_wizard`.
- **Hostile**: `mob_melee`, `mob_ranged`, `mob_fast`, `mob_tank`.

### 2. Visual Accessories (Minimalist Style)
New simple geometries will be drawn in `MinimalistEntity.gd` based on the role:
- **Guard**: A small vertical rectangle on one side (Shield).
- **Merchant**: A small rectangle on the back (Pack).
- **Wizard**: A floating triangle above the head (Hat) or a thin line (Staff).
- **Peasant**: No accessories, just base colors.

### 3. Spawner Refinement (`npc_spawner.gd`)
-   **Density Control**: Add `biome_density_multiplier` to adjust population limits.
-   **Natural Spawning**: All roles (inc. Functional NPCs) will be part of the `SpawnTable` and appear in appropriate biomes (e.g., Wizards in "Forest" or "Towers", Guards in "Village").

### 4. AI Behavioral Modules & LoD
-   **Wizards**: Will use spell-casting logic. They can attack hostiles or offer unique magic interactions.
-   **AI LoD (Level of Detail)**:
    - **Active (>1500px away)**: Disable `BTPlayer` and `HSM`. 
    - **Simulation Mode**: Use simple `_physics_process` only for gravity and basic avoid-wall steering, updating at half frequency.

### 5. Data-Driven Visuals (`CharacterData.gd`)
-   Integrate random name generation.
-   Apply dynamic scaling (e.g., `0.9` to `1.2`) to individuals.

### 5. Interaction UI
-   **Occupation Labels**: Display the NPC's role (e.g., "Guard", "Tool Merchant") in the nameplate for quick identification.

## Scalability
Moving `SpawnRules` from a hardcoded list to a registry of `Resource` files (`.tres`) in a later phase would be ideal, but for now, we will significantly expand the `_build_registry()` method.
