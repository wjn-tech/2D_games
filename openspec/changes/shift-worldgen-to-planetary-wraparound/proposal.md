# Change: Shift Worldgen to Planetary Wraparound

## Why
当前世界生成已经具备可玩的区块流式、噪声地形、洞穴、矿物和少量地标，但它仍然建立在“横向无限、纵向可无限延伸、宏观结构主要靠局部噪声拼出来”的前提上。这个前提和新的目标已经发生了根本冲突：

- 设定上世界是一个星球，玩家持续向东或向西前进时，必须最终回到原处。
- 玩法上希望世界更接近 Terraria 式的“有整体身份的单个世界”，而不是无尽平铺的局部片段。
- 生成上需要世界级规划，确保出生区、主生物群系、大型地标、深度进程和资源层次具有稳定的相对关系。
- 现有 change expand-exploration-terrain-and-hostiles 明确不替换无限区块架构，因此它无法承接这次拓扑级需求。

## What Changes
- 将世界拓扑从“横向无限”调整为“有限周长、东西向环绕”的行星式世界。
- 为新世界引入明确的 world size 预设档位，使周长、出生区宽度、主要 biome 弧段和地标预算可以随档位稳定缩放，而不是继续依赖隐含的无限扩展。
- 新增基于 seed 的世界级宏观布局，在完整周长上预先规划出生区、主生物群系带、海岸/过渡带、关键地标和特殊区域。
- 为新角色定义可控的出生安全带，保证初始落点位于温和 surface biome、基础资源可达、且不会紧贴世界接缝或高危地标。
- 将地下从“可无限向下扩展的局部噪声洞穴”演进为“有明确深度层次和终局区域的地下进程”，并限制垂直连接结构，避免无止境坠落和失控通道。
- 保留区块流式加载与差分存档，但将其改造成支持环绕坐标、接缝邻接和规范化 chunk key 的版本。
- 将地图、刷怪、结构查询和存档元数据统一到 topology-aware world query 之上，避免 seam 逻辑在多个系统里重复分叉。
- 定义新旧世界拓扑的兼容策略，避免旧的无限世界存档被静默映射到错误的行星世界上。

## Detailed Scope
- 新世界拓扑采用 planetary_v1 模式；旧世界保留 legacy_infinite 兼容语义，二者不得混读。
- 初始实现提供离散 world size 预设而不是任意自由输入，便于控制内容密度、验证成本和 UI 表达。
- 宏观 world plan 至少要显式规划：出生安全带、主 biome 弧段、过渡带、海岸或世界边界风格区域、唯一地标槽、区域级地下变体标签。
- 地标按三类处理：全局唯一地标、区域级稀有地标、局部装饰类 landmark；只有前两类进入 world plan 预留逻辑。
- 深度进程至少要定义稳定的深度带顺序、相邻带连接规则、最深终局带或边界条件，以及与宏观 biome 的组合修饰。
- 验证必须覆盖多个 seed、多个 world size 和 seam 两侧交互，而不仅是单次生成观感。

## Current Baseline
- WorldGenerator 和 InfiniteChunkManager 按 chunk 坐标局部确定性生成地形，缺少完整世界的宏观规划数据。
- 结构、资源和洞穴大多由局部噪声或 chunk hash 决定，不能保证世界级唯一性与稳定相对位置。
- 世界保存当前只稳定记录单个 world_seed，区块 delta 也依赖无界 chunk_x/chunk_y 路径命名，横向坐标默认无界，不存在“接缝另一侧其实很近”的空间语义。
- 当前地下虽然已经增强了可达性和防坠落保护，但整体深度模型仍然偏向无限世界思路。

## Impact
- Affected specs: planetary-world-topology, macro-world-layout, geological-progression, world-streaming-and-persistence
- Affected code: src/systems/world/world_generator.gd, src/systems/world/infinite_chunk_manager.gd, src/systems/world/world_chunk.gd, src/systems/world/layer_manager.gd, scenes/player.gd, src/core/save_manager.gd, minimap/world query consumers, save/load flow, world selection or new-world creation flow
- Affected data: world metadata, seed/topology persistence, landmark reservation data, biome-region planning data, compatibility flags for legacy saves
- Relationship to existing changes: 这是一个更高层的世界拓扑迁移提案。它不替代 expand-exploration-terrain-and-hostiles 的内容扩充目标，但会为后续探索内容提供新的行星世界基础。