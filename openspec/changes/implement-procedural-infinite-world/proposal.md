# Proposal: Procedural Infinite World

受到《Noita》启发，实现基于 Chunk (区块) 的无限程序化生成世界。系统将结合 "Wang Tiles" (王瓷砖) 宏观骨架、FastNoiseLite 微观细节以及差分保存机制。

## Problem Statement
目前的 `WorldGenerator` 是基于固定宽高的静态生成，不支持玩家远距离探索。此外，缺乏宏观地形结构（如特定形状的洞穴、据点），仅仅依靠纯噪声生成地形显得单调。

## Proposed Changes
1.  **无限区块管理 (Chunk Management)**:
    - 将世界划分为 64x64 瓦片的区块。
    - 根据玩家位置动态加载/卸载区块。
    - 使用全局 `seed` + `chunk_coord` 的哈希值作为局部种子，确保确定性生成。
2.  **双层生成算法 (Hybrid Generation)**:
    - **宏观层 (Wang Tiles)**: 预制 64x64 的地形模板（王瓷砖），基于邻接规则自动拼接，形成世界的基础骨架（如：垂直矿井、大型空腔、遗迹中心）。
    - **微观层 (Density Functions)**: 在模板基础上叠加 Perlin/Simplex 噪声，增加边缘细节、矿石分布及自然侵蚀效果。
3.  **差分保存机制 (Delta Persistence)**:
    - 仅保存玩家炸毁、挖掘或放置的瓦片（Delta 数据）。
    - 原始内容在进入视距时实时重新生成，从而实现极小的存档体积。
4.  **性能优化**:
    - 区块生成任务移至后台线程（使用 WorkerThreadPool 或线程池）。
    - 采用 LRU 缓存管理已生成的区块。

## Acceptance Criteria
- 玩家向任意方向持续移动，地形会源源不断生成。
- 相同种子在相同坐标生成的区块完全一致。
- 被玩家挖掘后的区域，在离开并重新返回后，破坏状态得以保留。
- 生成过程不应引起明显的帧率抖动（Stuttering）。

## Clarification Questions (Resolved)
1.  **物理粒度**: 维持目前的 Tile 级物理（16x16），但在挖掘和爆炸时增加大量“装饰性粒子（Fragments）”以模拟《Noita》的破碎感。
2.  **纵向深度**: 无限地图包含 Y 轴（向下无限挖掘）。
3.  **多层同步**: 所有深度的 Layer (0/1/2) 均执行无限同步生成。`ChunkManager` 将同时管理三个维度的区块数据转换，确保图层穿梭时的无缝衔接。
