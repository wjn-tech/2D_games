# Design: Staged Liquid Simulation and Elemental Interactions

## Context
当前项目已经在朝“大世界沙盒”方向前进，但液体仍然几乎停留在概念层。对于这个类型的游戏，液体不是可有可无的视觉细节，而是同时影响：

- 地形可读性与世界生成
- 玩家移动与生存压力
- 建造与设施布局
- 采集、挖掘、陷阱与刷怪玩法
- 后续的元素反应扩展

如果这里一开始选错建模方式，后续成本会非常高。尤其是本项目已经有 chunk streaming、世界生成、持久化和查询系统雏形，液体必须能接到这些结构上。

Terraria 和附件 demo 刚好分别提供了两个互补但不应混为一谈的启发：

- Terraria 说明了“规则层”该怎么做：部分填充、沉降、不同液体身份、方块交互、视觉型 liquidfall 分层。
- 附件 demo 说明了“表现层”能怎么做：局部高保真液滴/液面轮廓和 shader 融合。

因此，这个 design 的核心是分层，而不是追求某一种单一“最真实”算法。

## Goals / Non-Goals

### Goals
- 建立一个适用于 chunked sandbox world 的权威液体模型。
- 保证液体状态可生成、可流动、可沉降、可存档、可重载。
- 让不同液体拥有玩家能感知到的明确身份差异。
- 让液体能与地形、实体、工具和基础元素反应形成稳定契约。
- 为未来更复杂的元素系统预留反应表接口，但不要求首版做成全元素沙盒。
- 允许近景液体表现单独演进，而不绑死主模拟实现。

### Non-Goals
- 不在首版做整图逐粒子流体仿真。
- 不要求把所有液体都建成真正的压力模拟或 Navier-Stokes 风格求解。
- 不要求首版完成 Terraria 全量液体特性、所有工具、所有特殊方块和全部合成用途。
- 不要求首版完成完整火生态、烟雾、蒸汽、导电网络等高级元素链。

## Decisions

### Decision: Use an authoritative cell-fill liquid model, not a global rigid-body droplet sim
功能性液体采用基于 tile 或 sub-tile 填充量的权威数据模型。每个液体单元至少需要：

- liquid_type
- fill_amount
- active or sleeping flag
- optional source or settled hint

Reasoning:
- 这类模型更适合 chunk streaming、体积保存、世界生成、查询和混合反应。
- 附件里的刚体液滴方案一旦放大到大地图，会在性能、同步、存档和规则一致性上迅速失控。

Alternatives considered:
- 全局刚体粒子模拟。视觉效果强，但不适合作为沙盒世界的权威层。
- 只用真假贴图或预制体。实现简单，但无法支撑玩家真正改造世界。

### Decision: Separate worldgen settling from runtime active-frontier simulation
液体需要两个不同阶段：

- worldgen settling: 世界创建后对预放置液体做若干轮整理，消除明显悬空和未稳定状态。
- runtime simulation: 仅对活跃 chunk 和活跃边界做增量更新。

Reasoning:
- Terraria 的“settling liquids”经验很重要。玩家第一次看到世界时，液体应该已经像一个成立的地貌结果，而不是刚开始从空中往下掉。
- 运行时如果每帧扫全图，成本和 streaming 复杂度都会失控。

### Decision: Model liquid identity through per-type profiles, not conditionals scattered everywhere
不同液体应由 profile 描述，而不是在代码里不断写 if water / if lava：

- flow_speed
- lateral_spread_bias
- minimum_visible_fill
- damage or drowning behavior
- movement_modifier
- light or opacity hint
- reaction tags

Reasoning:
- 水、熔岩、蜂蜜、特殊转化液体的差异是玩法核心，不是贴图差异。
- profile 化后更容易扩展新液体并接入调试工具。

### Decision: Keep the first playable milestone narrow
首个可玩里程碑只强制要求：

- Water
- Lava
- 基础灭火/固化/伤害或窒息规则
- 最基础的放液/吸液接口

第二阶段再补：

- Honey
- 更复杂的 biome 绑定液体口袋
- 更丰富的放液工具

第三阶段才考虑：

- Shimmer-like 转化液体
- 更复杂的 decrafting 或 transmutation 行为

Reasoning:
- 当前项目还没有液体基础设施，直接把 honey、shimmer、火焰生态、泵网路一次性塞进首版，风险过高。

### Decision: Treat liquidfalls and drips as presentation-capable, optionally non-authoritative features
瀑流、滴落、飞溅、边缘黏连轮廓可以不等价于真实体积守恒液体。它们可由权威液体触发，但可以走更便宜或更华丽的渲染路径。

Reasoning:
- Terraria 的 liquidfall 是非常强的设计经验：玩家看到了连续液体视觉，但系统不必为每一段瀑流都承担同等级模拟成本。
- 这也给附件 demo 的 shader/粒子思路一个正确位置。

### Decision: Encode tile openness and reaction metadata explicitly
液体不是只和“空/非空”交互。提案需要为 tile 或材料引入明确元数据，例如：

- blocks_liquid
- allows_liquid_fallthrough
- supports_partial_fill
- flammable
- heat_resistant
- liquid_reaction_surface

Reasoning:
- 这能支撑半砖、斜坡、格栅、特殊通道、耐火材料等后续扩展。
- 也能避免把液体规则散落进挖掘、建造、渲染和实体代码里各写一份。

### Decision: Keep fire as a reaction system riding on the same metadata, not as a co-equal first milestone
change id 保留 elemental chemistry 的命名，但本轮实现中心是液体。火焰系统首版只要求与液体共享元数据和反应表能力，例如：

- water extinguishes fire
- lava ignites flammable materials or entities
- heated blocks can react into different states later

Reasoning:
- 这保留了“元素化学”的扩展方向，同时避免 proposal 因为范围过大而无法真正落地。

## Architecture

### 1. Authoritative Liquid State
建议每个活跃 chunk 拥有独立液体数据层，而不是把液体直接编码进可见 TileMap：

- liquid grid aligned to world cells
- fill amount stored per cell with fixed precision
- optional dirty rects or active frontier queue
- serialization payload for modified chunks

Visible tiles or overlays then read from this state.

### 2. Simulation Loop
推荐的更新顺序：

1. gather active chunks near player or active events
2. step active liquid cells from bottom to top or by stable frontier ordering
3. resolve vertical fall first
4. resolve lateral equalization second
5. resolve inter-liquid and liquid-material reactions
6. mark cells as sleeping when settled

The exact solver is not mandated, but the result must be deterministic for a given seed and input history.

### 3. Worldgen and Settling
世界生成不应只是“顺手放一点水”。建议的职责：

- choose biome and depth appropriate liquid reservoirs
- carve reservoir container shape or reuse cave topology
- stamp initial liquid volumes
- run offline settling pass or equivalent stabilization step
- mark decorative falls or drips separately when needed

This lets the player discover ponds, cave lakes, lava basins, and biome-linked liquid pockets as authored world features.

### 4. Interaction Layer
液体交互至少分四类：

- terrain interaction: 与实心块、半开口块、斜坡、格栅、特殊通道的关系
- liquid-liquid interaction: 如 water + lava solidifies, later honey or shimmer reactions
- entity interaction: 伤害、窒息、减速、游泳、增益、特殊状态
- tool interaction: bucket, pump, scripted structure, world event

这些交互不应该散在多个系统随意判断，最好走统一 reaction or query layer。

### 5. Presentation Layer
表现层建议拆成三档：

- baseline: 基于 fill amount 的液面和颜色表现
- enhanced: 泡沫、波纹、发光、热雾、边缘高光
- local high-fidelity: 角色附近飞溅、入水、瀑流边缘的粒子或 shader 融合

附件 demo 最适合作为第三档的参考实现，而不是第一档的前提。

### 6. Persistence and Streaming
液体状态必须成为 chunk delta 的一部分：

- generated but untouched chunks can lazily reconstruct from seed plus worldgen rules
- modified chunks must serialize liquid deltas
- sleeping liquid cells should be cheap to reload
- simulation resumes only when a chunk becomes relevant again

## Risks / Trade-offs
- 部分填充模型会增加渲染与存档复杂度。
  Mitigation: 首版限制固定精度和有限液体类型，不做任意高精度体积。

- 如果 reaction 设计过宽，首版就会变成“半个 Noita”。
  Mitigation: 先做水/熔岩的硬规则，再把其余液体做成 profile 扩展。

- 如果把附件 demo 直接引入主模拟，性能与确定性会变差。
  Mitigation: 明确其仅用于局部表现增强。

- 世界生成和运行时模拟若规则不一致，会出现首见世界与重载后世界不一致的问题。
  Mitigation: worldgen settling 与 runtime solver 必须共用同一套基础流动规则。

## Migration Plan
1. 定义液体 profile、tile openness metadata 与 reaction schema。
2. 引入按 chunk 存储的权威液体数据层，并打通最小序列化通路。
3. 实现 Water/Lava 的活跃区模拟与沉降规则。
4. 将世界生成接入液体储层放置和生成后沉降。
5. 接入基础实体效果与工具接口。
6. 最后再接入 liquidfall、splash 和局部高保真表现增强。

## Validation Strategy
- 对代表性 seed 验证：地表/地下能稳定生成可识别的水体与熔岩体，不会大量悬空。
- 对运行时验证：液体在活跃区域流动、停滞、重载后的结果一致。
- 对交互验证：water 与 lava 至少能产生不同的实体效果和至少一种稳定反应结果。
- 对 streaming 验证：玩家远离后再返回，液体状态不会明显错乱或回滚。
- 对表现验证：visual-only liquidfall 存在时，不会要求真实液体源同步耗尽。

## Open Questions
- 首版 fill amount 采用 4 档、8 档还是更高固定精度更合适。
- bucket/pump 接口是否在首版直接落到玩家工具，还是先通过 debug/world event 打通。
- Honey 是否应等待对应 biome/structure 更完整后再进入第二阶段。