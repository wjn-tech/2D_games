# Tasks: Procedural Infinite World

- [x] **基础框架建立**
    - [x] 创建 `res://src/systems/world/infinite_chunk_manager.gd` (Autoload)。
    - [x] 实现 `WorldChunk` 资源类，包含图层数据和 Delta 缓存。
    - [x] 在 `project.godot` 中配置新单例。
- [x] **生成管线逻辑**
    - [x] 实现 `local_seed` 生成算法（Morton 码或 2D 哈希）。
    - [x] 将已有的 `WorldGenerator` 逻辑封装为 `ChunkFactory.generate_cells(coord)` (使用 `generate_chunk_cells`)。
    - [x] 接入 `FastNoiseLite` 实现跨区块的平滑噪声地形。
- [x] **动态加载与优化**
    - [x] 在 `Player` 脚本中增加距离感知逻辑。
    - [x] 实现区块的异步生成（使用 `WorkerThreadPool`）。
    - [x] 实现距离基础的卸载策略。
- [x] **反馈与持久化**
    - [x] 在 `DiggingManager.gd` 挖掘逻辑中增加对 `InfiniteChunkManager.record_delta` 的调用。
    - [x] 实现破坏时的“碎片粒子预览”系统。
    - [x] 实现存档/读取接口 (tres Resource 序列化)。
- [x] **王瓷砖 (Wang Tiles) 扩展 (可选，视进度决定)**
    - [x] 实现基础结构生成器 (矿井/遗迹)。
