# Design: NPC Housing and Settlement System

## Algorithm: Single-Chunk Flood Fill
由于房屋限制在单个区块（64x64），检测算法将针对单个区块的 TileMap 数据进行。

1. **种子点扫描**：从玩家点击点或 NPC 站立点开始。
2. **约束条件**：
    *   **Passable**: 空气 (Layer 0, 1 无瓦片), 平台 (特定 Tile ID)。
    *   **Blocker**: Layer 0 上的实心块。
    *   **Boundary**: 区块边界 (64x64) 视为天然墙壁（不计入有效房屋，仅作为搜索截断）。
3. **连通性**：采用 4/8 方向泛洪，记录所有内部坐标。
4. **属性检查**：
    *   **背景墙 (Layer 2)**：统计内部坐标中 Layer 2 的瓦片覆盖率，允许最大 4x4 的空洞。
    *   **家具检测**：利用 Godot 群组 (`housing_light`, `housing_comfort`, `housing_table`, `housing_door`) 检测位于内部区域内的 Node2D 实体。

## Data Structures

### TileItemData (Resource)
继承自 `ItemData`，用于定义可摆放的瓦片物品。
*   `target_layer`: 目标图层 (0: 实心, 2: 背景墙)。
*   `tile_atlas_coords`: 在 TileSet 中的坐标。
*   `placement_rules`: 标志位，如 `requires_neighbors` (背景墙专用)。

### HousingInfo (Resource)
```gdscript
class_name HousingInfo
var chunk_coord: Vector2i
var interior_cells: Array[Vector2i]
var owner_uuid: int = -1
var is_valid: bool = false
var last_check_time: float
```

## Placement Logic Pipeline

1. **输入阶段**：玩家选择 `TileItemData` 物品，`BuildingManager` 进入监听状态。
2. **距离检查**：计算鼠标位置与玩家中心的距离，超过 `reach_limit` (默认 160 像素) 则不触发放置。
3. **图层自动切换**：若物品 `target_layer == 2`，预览及放置操作自动导向背景墙层。
4. **合法性验证**：
    *   **实心块 (L0)**: 目标格子必须为空。
    *   **背景墙 (L2)**: 目标格子必须为空，且相邻 4 格内必须有已存在背景墙或 Layer 0 的实心块（防止“凭空悬挂”）。
5. **执行放置**：扣除物品数量，调用 `InfiniteChunkManager.record_delta`。
6. **连续摆放**：按住左键移动鼠标时，若跨越至新网格单元，自动重复验证与执行步骤。

## Hammer & Destruction
*   **锤子工具**：点击背景墙（Layer 2）时触发移除。
*   **掉落规则**：调用 `InfiniteChunkManager` 的 `remove_tile` 时，根据该格子的 ID 查找 `ItemDatabase`，在世界中生成一个 `Pickup` 实体。

### NPC Settlement Persistence
NPC 的住所信息存储在 `CharacterData` 中，记录 `house_pos` (世界坐标)。当区块加载时，若该坐标对应有效房屋，NPC 会尝试归巢。

## NPC Respawn Logic
1. 系统维护一个 `DeadNPCRegistry` 列表。
2. 每隔 2-3 个游戏日，随机抽取一个已故非子嗣 NPC 职位。
3. 创建新的 `CharacterData`（随机姓名，原职业），并将其加入 `NPCSpawner` 的待产列表。

## Pylon Activation Logic
1. 聚落定义：半径 120 格内有 2 名以上已入住 NPC。
2. 快乐度计算：
    *   地形偏好：当前区块的 Biome 类型。
    *   社交：半径 120 格内的其他已入住 NPC UUID。
3. 传送点：满足快乐度阈值后，玩家放置的晶塔建筑图标变亮，开启传送。
