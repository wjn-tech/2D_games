## MODIFIED Requirements: NPC Settlement Behavior

### Requirement: Homeless NPC Settlement
游荡 NPC 应当在发现空房时自动入住。

#### Scenario: Evening Settlement
*   **Given**: 地图上有一个未分配房屋的商人 NPC。
*   **And**: 附近有一个已认证合格的空房屋。
*   **When**: 游戏时间变为夜晚。
*   **Then**: 商人 NPC 直接“传送”入房屋内部，并在房屋中心显示其旗号。

### Requirement: NPC Respawn
非玩家后代 NPC 死亡后应能重生成为新人。

#### Scenario: Merchant Death and Rebirth
*   **Given**: 商人 NPC 已死亡。
*   **When**: 经过 3 个游戏日。
*   **And**: 地图上有合格空房且满足金币拥有条件。
*   **Then**: 一个具有新名字的商人 NPC 在地图边缘生成并移向空房。
