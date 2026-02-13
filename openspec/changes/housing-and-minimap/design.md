# Design: Housing & Minimap Core Architecture

## Housing Manager UI Structure

### `HousingMenu` Node (scenes/ui/housing_menu.tscn)
- `Sidebar`: 垂直排列的按钮组。
- `NPCPanel`: 展开式面板，显示所有可用 NPC 列表。
- `WorldOverlay`: 一个特殊的 `Control` 节点，当房屋管理模式激活时，在世界坐标上覆盖图标（Icon）。

### NPC Assignment Logic
- `HousingManager.assign_npc_to_house(npc_id, house_id)`
- 发出信号：`npc_reassigned(npc_id, old_house_id, new_house_id)`
- NPC 行为树（LimboAI）检测到住所变更后，更新其“回家”行为的目标位置。

## Minimap Implementation

### Map Data Source
- 监听 `InfiniteChunkManager` 的分块加载与块变更（Tile change）。
- 使用一个低位深度的 `Image` 对象（例如每 16x16 像素对应地图 1 像素）存储地形颜色概况。

### Fog of War (FOW)
- **Data**: `BitMap` 或 `Image` (Format `L8`)。
- **Update**: 每帧或每隔一定位移，清除以玩家为中心半径 $R$ 内的 FOW。
- **Shader**: 小地图纹理与 FOW 纹理相乘，决定可见度。

### Minimap UI (scenes/ui/minimap.tscn)
- `MarginContainer`
    - `ColorRect` (Background)
    - `TextureRect` (The actual map texture generated from chunks)
    - `MarkersContainer` (Dynamic icons for NPCs/Player)
    - `FOWOverlay` (Applying the fog texture)

## File Additions
- `src/systems/world/minimap_manager.gd` (Singleton or component of Player)
- `src/ui/housing/housing_manager_ui.gd` (Main UI logic)
- `src/ui/minimap/minimap_ui.gd` (Rendering logic)
- `scenes/ui/housing_indicator.tscn` (Floating icon over houses in UI mode)
