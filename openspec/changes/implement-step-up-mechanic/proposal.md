# Proposal: Implement Step-Up Mechanic

## 1. Problem Statement
The player currently gets stuck on 1-tile high obstacles (e.g., small ledges or stairs), requiring a manual jump to proceed. This interrupts the flow of movement. The user wants the character to automatically "step up" onto 1-tile high blocks but remain blocked by 2-tile high obstacles.

## 2. Proposed Solution
- **Step-Up Logic**: Modify `player.gd` to detect when the character is blocked by a wall while moving horizontally.
- **Height Check**: When a wall is hit, perform a "test move" at a higher elevation (e.g., 18-20 pixels up, assuming 16px tiles) to see if the space is clear.
- **Automatic Elevation**: If the higher space is clear, adjust the player's position to "step up" onto the ledge.
- **Limit**: Ensure the step height is limited to approximately 1 tile height (16-20 pixels) so that 2-tile high walls (32px+) still block movement.

## 3. Scope
- `scenes/player.gd`: Update `_physics_process` to include step-up detection and handling.
- `src/systems/npc/base_npc.gd`: Update `_physics_process` to include step-up detection for NPCs.

## 4. Dependencies
- `CharacterBody2D` physics properties.
