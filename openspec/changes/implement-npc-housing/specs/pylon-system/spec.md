## ADED Requirements: Pylon System

### Requirement: Pylon Teleportation
玩家可以通过晶塔实现远距离瞬时移动。

#### Scenario: Pylon Activation
*   **Given**: 在沙漠生物群落有两个快乐度 > 80 的 NPC 入住。
*   **And**: 玩家在附近放置了“沙漠晶塔”。
*   **When**: 玩家打开地图并点击该晶塔图标。
*   **Then**: 玩家瞬移至该晶塔位置，扣除少量魔力。
