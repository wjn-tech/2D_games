## ADED Requirements: Placement System

### Requirement: Layer-Aware Building
摆放系统必须能根据物品属性自动作用于正确的图层。

#### Scenario: Placing Wood Wall
*   **Given**: 玩家手持 ID 为 `wood_wall` 的 `TileItemData`（其 `target_layer` 为 2）。
*   **When**: 玩家将鼠标悬停在空白区域。
*   **Then**: 预览阴影显示在背景层（Layer 2）。
*   **And**: 如果目标点距离玩家超过 160 像素，预览显示为红色且禁止操作。

### Requirement: Continuous Placement
玩家可以像刷墙一样连续摆放瓦片。

#### Scenario: Painting a Room
*   **Given**: 玩家按住鼠标左键并移动。
*   **When**: 鼠标移动到新的坐标点。
*   **Then**: 只要该点满足摆放规则且在射程内，系统自动放置瓦片并消耗 1 个物品。

### Requirement: Proximity Constraint
背景墙不能凭空出现。

#### Scenario: Valid Wall Placement
*   **Given**: 目标点相邻有一块实心砖块。
*   **When**: 玩家点击放置背景墙。
*   **Then**: 放置成功。

#### Scenario: Invalid Wall Placement
*   **Given**: 目标点四周 4 格内没有任何背景墙或实心块。
*   **When**: 玩家点击放置。
*   **Then**: 放置失败，预览显示红色禁止标志。
