## ADED Requirements: Hammer Tool

### Requirement: Selective Background Removal
锤子工具应能专门移除背景墙而不破坏主结构。

#### Scenario: Breaking Walls
*   **Given**: 玩家手持“木锤”工具。
*   **When**: 玩家在背景墙（Layer 2）上点击左键或按键。
*   **Then**: 背景墙被移除并掉落对应物品。
*   **And**: 同位置的 Layer 0 实体砖块保持不受损。
