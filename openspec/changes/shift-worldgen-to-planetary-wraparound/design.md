# Design: Shift Worldgen to Planetary Wraparound

## Context
项目当前的世界系统已经解决了三个关键基础问题：按需加载、局部确定性和差分保存。这些能力非常适合原型阶段，也能支撑一般性的无尽探索。但是这套系统天然偏向“任意方向都可以继续延展”的无限世界，而不是“一个有完整身份的星球”。

这次需求不是再给现有无限世界多加一些装饰，而是把世界的宏观语义改成以下模型：

- 横向是有限周长。
- 东西向移动是连续的，不通过传送门伪装。
- 世界必须有完整宏观布局，而不是只在玩家附近即时决定一切。
- 地下需要有明确层次和终局区域，而不是默认继续向下延展。

因此，这个 change 关注的是世界拓扑、宏观规划、深度进程和流式系统的重新约束。

## Goals / Non-Goals

### Goals
- 提供真正的东西向环绕拓扑，让玩家绕世界一圈后回到起点区域。
- 保持 chunk streaming 和 delta persistence，不退回整张地图一次性生成。
- 为整个世界周长建立稳定的宏观布局，包括出生区、主生物群系、过渡带和关键地标槽位。
- 让地下深度成为有设计意图的 progression 轴，而不是无限噪声深井。
- 让世界查询、刷怪、地图、存档和结构放置都理解“接缝两侧相邻”的空间关系。

### Non-Goals
- 不实现真正球面投影、重力朝球心变化或南北极系统。
- 不在本 change 中一并完成 boss、剧情、经济或完整液体模拟改造。
- 不要求一次性重做所有探索内容资源，美术和敌人扩充仍可由后续 change 继续推进。
- 不要求旧的无限世界自动无损迁移为行星世界；允许采用显式兼容模式或仅对新世界启用新拓扑。

## Decisions

### Decision: Use cylindrical topology instead of a fully spherical simulation
世界在玩法上采用“横向环绕、纵向深度推进”的圆柱式拓扑。

Reasoning:
- 它直接满足“东西走回原处”的核心需求。
- 它保留现有 2D 横版视角、重力方向和大部分控制逻辑。
- 它避免把问题升级为整套球面坐标、曲率渲染和朝向重写。

Alternatives considered:
- 保持无限世界，只在远端做传送折返。这个做法无法提供统一世界身份，且会让宏观规划继续碎片化。
- 完整球面模拟。收益远小于实现成本，不适合当前阶段。

### Decision: Introduce a world-plan layer above chunk generation
新增“世界规划层”，在 seed 确定后先生成整个世界周长上的宏观布局，再由 chunk 生成读取该规划层来做局部落地。

The world plan should include:
- 世界周长和 chunk 数量。
- 出生经线或出生区域锚点。
- 主生物群系弧段与过渡弧段。
- 关键世界地标或唯一结构的保留槽位。
- 与深度带联动的地下区域标签。

Reasoning:
- 仅靠局部噪声无法保证“这个世界右边是雪原，再过去是海，再过去回到出生森林”这种整体秩序。
- 世界级地标和罕见区域必须先占位，才能避免重复、缺失或随机贴边。

### Decision: Standardize initial world sizes as presets
初始版本使用离散 world size 预设，而不是允许任意自定义周长。

Initial direction:
- Small: 256 chunks circumference
- Medium: 384 chunks circumference
- Large: 512 chunks circumference

Reasoning:
- 这能让 biome arc、landmark budget 和验证矩阵稳定下来。
- 当前项目的 save/load 和 UI 仍然偏原型，先做预设比开放自由输入更稳妥。

Alternatives considered:
- 任意输入周长。灵活但会让内容预算、spawn 安全带和验证成本迅速失控。

### Decision: Reserve a spawn-safe temperate corridor
每个 planetary world 都要在 world plan 中预留一个出生安全带，而不是完全把出生质量交给局部生成碰运气。

Minimum guarantees:
- 出生区位于温和 surface biome 或等价新手区域。
- 出生区与世界接缝保持最小 wrapped distance。
- 出生区附近必须存在基础采集材料、可下探入口和有限敌对压力。
- 全局唯一高危地标不能直接贴在出生安全带上。

Reasoning:
- 如果世界已经从“无限试错”转向“单个有身份的星球”，出生体验就必须可预期。
- 这也让后续教程、定居点和 NPC 初始布局更容易稳定落位。

### Decision: Keep streaming chunks, but canonicalize wrapped coordinates
不预生成整张世界，而是保留流式加载；不过所有横向坐标都要经过规范化映射。

Key rules:
- 逻辑世界 X 可以继续使用连续数值做运动和渲染。
- 生成、查询、刷怪、保存使用规范化后的 wrapped chunk index 和 wrapped tile position。
- 所有横向距离比较都使用最短环绕距离，而不是简单的绝对值差。

Reasoning:
- 这能保留已有流式系统的性能优势。
- 它将“接缝”从特殊例外变成统一的坐标规则。

### Decision: Replace infinite-depth assumptions with bounded progression bands
地下不再默认是无限纵深，而是改为多个有意图的深度带，例如浅层、地下、洞穴层、深层、终局层或核心边界。

Design consequences:
- 垂直连接结构只能连接相邻深度带，不能形成无止境纵井。
- 稀有资源、危险环境和特殊生态要由深度带和宏观区域共同决定。
- 玩家保护逻辑仍然保留，但它应成为异常兜底，而不是世界设计的主逻辑。

Reasoning:
- 有终点的深度进程更符合行星世界和 Terraria 式世界认知。
- 地下体验需要“越往下越明确地进入别的层级”，而不是单纯更深。

### Decision: Make topology versioning explicit in persistence
存档必须记录 world topology metadata，例如 topology_version、circumference_in_chunks、world_plan_seed 或等价标识。

Reasoning:
- 旧存档若没有这些字段，不能假定它们属于新行星世界。
- 不显式版本化会导致 seam、landmark 和 delta key 在读取时出现隐性错误。

Alternatives considered:
- 让旧存档静默套用默认周长。风险太高，容易把原有世界错读成另一种地形。

### Decision: Use explicit topology modes in save/load flow
存档和新建世界流程都应显式区分 topology_mode，而不是只依赖是否存在某几个字段推断。

Initial modes:
- legacy_infinite
- planetary_v1

Reasoning:
- 当前 SaveManager 只稳定保存 world_seed，这不足以描述行星世界。
- 显式模式字段能让 UI、存档、调试和后续迁移脚本共享同一个判断入口。

## Architecture

### 1. World Metadata
新增世界元数据层，至少包含：
- topology_version
- topology_mode
- horizontal_circumference_in_chunks
- chunk_size
- world_size_preset
- spawn_anchor
- spawn_safe_band
- world_plan hash 或生成参数摘要

Recommended persisted fields for new worlds:
- primary_seed
- topology_mode
- topology_version
- circumference_in_chunks
- world_size_preset
- spawn_anchor_chunk
- spawn_safe_radius_chunks
- world_plan_revision
- legacy_compatibility flag when applicable

这些数据应在新建世界时生成，在存档时持久化，在载入时优先于运行时默认值。

### 2. World Plan
WorldGenerator 不再只接收当前 chunk 坐标，而是先可查询完整的世界规划：
- 指定某段周长属于哪类主 biome
- 指定哪些 longitude arc 预留给唯一地标
- 指定地下子 biome 如何随着 surface arc 和 depth band 组合变化

Suggested plan structure:
- global anchors: spawn region, tutorial-safe corridor, seam reference points
- major arcs: forest/plains/desert/tundra/swamp or equivalents
- transition arcs: shorter buffers that soften abrupt biome switches
- landmark slots: unique landmarks and regional rare landmarks with minimum wrapped spacing
- underground overlays: region tags that modify cave style, hazards, ore tables, and special pockets by depth band

Chunk 生成仅负责把 world plan 在局部展开为 tile、背景墙、结构、矿物、实体与装饰。

### 2.1 Landmark Budget Model
为了避免“全局唯一”和“局部随机装饰”混在一起，world plan 应明确区分：
- unique landmarks: 每个世界最多一次，影响地图身份与长线导航
- regional rare landmarks: 每个宏观区域有限次数出现，提供探索奖励
- local decorations: 不进入 world plan，只在 chunk 层按局部规则生成

Each category should define:
- minimum wrapped spacing
- allowed macro biome arcs
- allowed depth bands
- whether it can appear near spawn_safe_band

### 3. Wrapped Spatial Utilities
需要统一的空间工具函数：
- wrap_chunk_x
- wrap_tile_x
- shortest_wrapped_distance
- canonical_chunk_key
- seam-safe neighborhood iteration

Additional expected consumers:
- spawn proximity checks
- minimap reveal and icon placement
- landmark nearest-neighbor queries
- save/load delta resolution
- player return-to-origin validation and debug tooling

这些函数要成为世界、玩家、刷怪、地图和保存系统的共享基础，避免每个系统自己处理接缝。

### 4. Seam-Safe Streaming
InfiniteChunkManager 的职责会变化：
- 继续按玩家位置流式加载 chunk
- 但横向索引在固定周长内循环
- 在接缝附近加载邻接 chunk 时，不得出现“东端和西端互相看不见”的断层

Streaming-specific expectations:
- seam 两侧不能生成两个逻辑上不同、物理上等价的 chunk container
- delta 重放必须以 canonical chunk key 为准
- 玩家、实体、投射物和查询逻辑要能接受“视觉 x 连续，逻辑 key 已 wrap”的状态

### 5. Geological Progression
地层、矿物和危险环境要从“局部深度阈值”升级为“世界进程结构”：
- 深度带定义基础材料、洞穴密度、资源层次和环境危险度
- 宏观 biome 改写局部深度带表现，形成雪原地下、沙漠地下、腐化带等差异
- 特殊区域可覆盖普通规则，但必须在世界规划层中先占位

Suggested first-pass depth band model:
- Surface band: 开阔、低风险、教程友好
- Shallow underground band: 基础矿物、短竖井、低级洞穴群
- Mid cavern band: 主要横向洞穴网络、区域特色加强
- Deep band: 高危材料、特殊 hazard、收紧通道密度
- Terminal band: 星球深部终局带、核心边界或等价终点语义

Connector rules should prefer:
- 相邻深度带之间的可读连接
- 固定最大纵向落差预算
- 定期出现可站立或转向的中继区域

### 6. System Touch Points
除 WorldGenerator 和 InfiniteChunkManager 外，以下系统也必须理解 topology_mode:
- SaveManager: 保存/读取 topology metadata，并区分 legacy_infinite 与 planetary_v1
- new-world or save-selection flow: 让新存档显式选择或显示 world size / topology
- MinimapManager: 接缝两侧应共享连续发现语义，而不是把两端当作互不相干区域
- spawn/query consumers: 最近地标、最近 biome 边界、最近危险区都必须使用 wrapped distance
- player recovery/debug helpers: 验证绕世界一周回到原点时不能被 seam 逻辑误判

## Risks / Trade-offs
- 有限周长会降低“永远有新地形”的感觉。
  Mitigation: 用更高质量的世界身份、地标和深度进程替代无尽长度带来的伪丰富度。

- 宏观 world plan 会增加生成复杂度，并引入更多跨系统依赖。
  Mitigation: 将 plan 设计为只读查询层，避免局部生成代码反向修改它。

- seam 处理若不统一，最容易在刷怪、查询、保存和导航上产生边界 bug。
  Mitigation: 把 wrapped coordinate helpers 做成底层唯一真相，禁止各系统自行拼接 x 坐标语义。

- 旧存档兼容可能带来额外维护成本。
  Mitigation: 明确声明新拓扑优先用于新世界；旧世界采用 legacy 模式或阻止进入不兼容流程。

## Migration Plan
1. 先引入 topology metadata 和 wrapped coordinate utilities，但暂时不改全部内容分布。
2. 定义 world size 预设、spawn_safe_band 和 topology_mode 持久化字段，使新建世界与存档入口先有稳定契约。
3. 在流式系统稳定支持接缝后，再接入 world plan 驱动的 surface biome arc 和 landmark reservation。
4. 随后重构地下深度带、垂直连接规则和资源/危险环境分布。
5. 最后梳理刷怪、地图、存档兼容和新世界创建流程。

## Validation Strategy
- 对每个 world size 至少验证多个代表性 seed，检查 biome 顺序、出生带安全性和地标去重。
- 执行完整的 eastbound/westbound 环绕测试，验证人物、刷怪、地图显示和 delta 持久化都没有 seam 伪影。
- 验证在接缝两侧修改同一物理区域时不会产生双份 chunk 存档或丢失 delta。
- 验证 legacy_infinite 存档会进入显式兼容路径，而不是被当作 planetary_v1 读取。

## Open Questions
- 旧的无限世界是否需要只读 legacy 兼容模式，还是直接标记为不能用于新 topology 功能。
- 液体系统在本阶段是只做静态储层/危险区分布，还是为后续完整模拟预留接口。