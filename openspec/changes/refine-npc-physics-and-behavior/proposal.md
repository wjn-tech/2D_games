# Proposal: Refine NPC Physics and Behavior

## 1. Problem Statement
Currently, NPCs in `BaseNPC.gd` have very basic movement logic that doesn't account for gravity or consistent physics with the player. Additionally, NPCs wander aimlessly across the map, and their "Neutral" personality doesn't have distinct behavior, leading to a lack of world stability and character depth.

## 2. Proposed Solution
- **Physics Consistency**: Implement gravity and floor detection in `BaseNPC.gd` to match the player's physical presence in the world.
- **Tethered Wandering**: Introduce a `spawn_position` and `wander_radius` to ensure most NPCs stay within a specific area (e.g., near their camp or spawn point).
- **Neutral Personality Logic**: Refine the AI to ensure "Neutral" NPCs (neither Brave nor Timid) remain passive unless provoked, and prioritize staying near their tether point.

## 3. Scope
- `src/systems/npc/base_npc.gd`: Update physics and AI state logic.
- `src/systems/lineage/character_data.gd`: Ensure personality types are well-defined.

## 4. Dependencies
- `CharacterData` resource for personality checks.
- `WorldGenerator` for setting the initial spawn position.
