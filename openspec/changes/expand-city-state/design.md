# Design: City-State and Settlement Expansion

## 1. Settlement UI
The UI will be a tabbed interface:
- **Overview**: Shows Population (Current/Max), Food Production, Defense, Prosperity, and Level.
- **NPCs**: List of recruited NPCs, their jobs, and assigned houses.
- **Buildings**: List of all buildings in the settlement.

## 2. Territory and Influence
- Each building has an `influence_radius`.
- The "Settlement Territory" is the union of all building influence areas.
- `BuildingManager` will draw a circular overlay (using `_draw` or a shader) to show the current territory during building mode.
- Certain buildings (like `Farm`) must be placed within the territory.

## 3. NPC Housing Logic
- `SettlementManager` will maintain a mapping of `NPC -> HouseNode`.
- When a `House` is built, it adds `population_bonus` slots.
- When an NPC is recruited, they are automatically assigned to the nearest house with an empty slot.
- NPCs will have a `home_pos` property updated by `SettlementManager`.

## 4. New Building Resources
- **Wall**: High defense, low cost, no population bonus.
- **Storage**: Small population bonus, provides a `Chest` interaction.
- **Well**: Increases food production of nearby farms.

## 5. Prosperity and Leveling
- Prosperity = `Buildings * 10 + Population * 5 + Food * 2`.
- Level 1: 0-100 Prosperity.
- Level 2: 100-500 Prosperity (Unlocks Stone buildings).
- Level 3: 500+ Prosperity (Unlocks Castle/Keep).
