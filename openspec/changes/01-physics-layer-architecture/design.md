# Design: Physics Layer Architecture

## Layer Assignments

| ID | Name | Role |
| :--- | :--- | :--- |
| 1 | World | Static terrain, houses (walls). |
| 2 | Player | The main player character. |
| 3 | Entities_Hard | Bosses or obstacles that must block movement. |
| 4 | Entities_Soft | Standard NPCs. Use this for the requested phasing. |
| 5 | Debris | RigidBody2D fragments from destruction. |
| 6 | Logic | Sensor areas for redstone/logic tiles. |

## Collision Matrix Rules

- **Layer 4 (Soft)**: 
    - Mask: 1 (World), 2 (Player).
    - Ignore: 4 (Self).
- **Layer 5 (Debris)**:
    - Mask: 1 (World).
    - Ignore: 2, 3, 4 (Prevents debris from snagging on actors).
