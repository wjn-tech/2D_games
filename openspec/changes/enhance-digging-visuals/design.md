# Design: Digging Visual Enhancement

## Architecture

### 1. Cracking Overlay Layer
不再使用单个 `Sprite2D` 放置在瓦片中心，而是采取以下策略：
- **方案 A (选择级)**: 在 `DiggingManager` 中维护一个专用的 `TileMapLayer` (CrackingLayer)，用于渲染碎裂效果。
- **优点**: 自动处理 Z-Index，支持同时对多个瓦片进行碎裂显示（如果未来支持范围挖掘）。
- **材质逻辑**: 碎裂效果使用一个具有 10 个 Atlas 坐标的 TileSet 资源。

### 2. Progressive Dust Particles
- **机制**: 在 `mine_tile_step` 每帧（或以固定频率）发射。
- **参数**: 
    - `emission_rate`: 随 `pickaxe_power` 增加。
    - `color`: 调用 `InfiniteChunkManager` 的颜色提取逻辑。
    - `velocity`: 随机散开或向挖掘反方向弹出。

### 3. State Management
- `mining_progress_map` 依然由 `DiggingManager` 维护。
- 每当进度更新时，计算 `frame_index = floor(progress * 10)`。
- 更新投影到目标瓦片上的碎裂层内容。

## Alternatives Considered
- **Shader 方案**: 使用 Shader 在原有瓦片上叠加裂纹。
    - *结论*: 虽然性能好，但对于 TileMap 来说配置较复杂，且难以快速实现“尘土飞扬”的非局部效果。
- **独立 Sprite 池**: 
    - *结论*: 难以管理大量正在挖掘的瓦片（如连锁爆炸/挖掘时）。

## Data Structures
- `CrackingTileSet`: 一个包含 10 种不同程度裂纹的 `TileSetSource`。
