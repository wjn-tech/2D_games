# Design: Refine Terrain Relief and Cave Topology

## Context
当前世界已经具备三个不错的基础：

- 行星式东西环绕拓扑已经存在，世界不再只是无界横向平铺。
- WorldGenerator 已经暴露 surface biome、surface feature 和 cave region 查询，刷怪与探索系统可以读取上下文。
- 地下可达性已经不是纯随机洞，而是有一套保证主路径存在的骨架。

但这套骨架现在太容易被玩家看穿了。地表的主要问题不是“没有装饰物”，而是地形轮廓本身缺少节奏；地下的问题也不是“完全没有洞”，而是空间形态与过渡太单一，且主干洞穴的波形过于明显。用户提出的目标，本质上是把世界从“可运行的噪声地形”提升到“有地貌语言、探索诱因和可读层次的地形系统”。

外部参考对这个方向提供了很稳定的启发。Terraria 的世界生成并不依赖单一地形函数把一切都做完，而是通过多阶段地形塑形、显式 surface-to-underground 入口、具有固定几何轮廓的地下区域，以及跨长距离的地下可达路线来建立探索语言。这个 change 不需要复制其内容清单，但应吸收这些方法论。

另一个必须正面处理的现实约束是资产负担。当前项目的 terrain/material 消费链对 atlas 坐标耦合很重：world_generator、digging_manager、building 预览和部分掉落逻辑都假设少量固定瓦片。如果把这次 change 误解成“每个新地貌都先补一整套新瓦片”，实施量会被放大到远超 worldgen 本身。因此这个 design 需要明确一条低资产优先路线。

## Goals / Non-Goals

### Goals
- 让玩家横向长距离移动时能感知到明显不同的地表轮廓节奏，而不仅是材质换皮。
- 让地下随着深度和地表宏观区域变化，表现出有连续过渡的 strata/biome identity。
- 让洞穴网络看起来像自然形成的探索空间，而不是一条可见的数学曲线外加若干打孔。
- 让地表定期出现“可看见且愿意进入”的自然地下入口，并与教程安全带、出生保护和可达性约束兼容。
- 在不要求完整重做 tileset 的前提下，让 terrain identity 先通过结构、层次和少量重点资产建立起来。
- 保持 deterministic generation、chunk 边界稳定性、delta persistence 和 spawn/query contract 的兼容性。

### Non-Goals
- 不在这个 change 中新增敌人家族、战斗招式或掉落体系。
- 不要求一次性重做所有 surface decoration 的美术资源。
- 不要求为每一种 relief profile、入口家族和地下 archetype 先绘制独立的整套基础瓦片 atlas。
- 不要求彻底改写 world streaming 架构或废弃现有 cave region 查询接口。
- 不要求实现真实地质模拟、液体侵蚀或任意复杂的物理 erosion 系统。

### Decision: Prioritize structure and material-family reuse over one-new-tileset-per-landform
本次地貌改进优先通过以下手段建立差异：

- silhouette 和高差节奏
- 背景层、空腔形状与 openness 差异
- 少量地表/地下装饰簇
- 已有基础材质家族的不同组合与分层
- 少量专用 accent tiles 或 transition tiles

Reasoning:
- 当前代码里大量系统直接判断 atlas 坐标，任何大规模主 tileset 扩张都会把改动范围从 worldgen 扩大到挖掘、掉落、建造和预览。
- Terraria 式可读性本质上更依赖空间形状和生成结构，而不是每个区域都拥有完全独立的基础砖块集。

Alternatives considered:
- 先画完整新 tileset 再做 worldgen。视觉上理想，但以当前代码耦合度看，成本高且会阻塞世界生成验证。

### Decision: Treat new tiles as a scarce accent budget, not the default delivery vehicle
如果某个 surface profile、入口 family 或地下 archetype 需要新增瓦片，应优先限制在：

- 关键边缘过渡瓦片
- 极少量 biome-specific accent tiles
- 更容易被复用的背景/装饰瓦片

而不是整套新的地表、地下、背景、挖掘和掉落材质一起扩张。

Reasoning:
- 这样可以把“世界生成是否有效”与“美术是否全部到位”解耦。
- 也能让第一轮验证先集中在地貌可读性，而不是被资源缺口卡住。

### Decision: Keep terrain material families centralized and additive
当后续确实需要增加材料家族时，应优先走集中式映射和增量元数据，而不是让更多 atlas 坐标分散硬编码到消费方。

Reasoning:
- 当前 material 判断太依赖散落的 atlas 常量；继续扩大会使后续每加一张瓦片都带来多处回归风险。
- 即便本 change 不直接实现重构，proposal 也应把这点记为实施约束。

## Decisions

### Decision: Split surface relief into macro landforms and local detail
地表不再由单一高度函数决定，而应由至少两层含义不同的结构叠加：

- macro landforms: 决定较长距离上的平原、丘陵、山群、谷地、台地或盆地节奏
- local detail: 决定局部起伏、坡顶破碎感、脊线粗糙度和 biome 级微变化

Reasoning:
- 只提高噪声振幅会让地表更抖，但不会形成“这是一片山地”这样的可读 silhouette。
- planetary_v1 已经有 world plan，surface relief 可以借助宏观 region arc 来稳定安排山地和缓坡段，而不是每个 chunk 自己决定。

Alternatives considered:
- 继续沿用单层噪声，只增加 feature decorator。这样能增加视觉点缀，但不能解决地表天际线和路线选择都过于平的问题。

### Decision: Organize terrain shaping as staged responsibilities instead of one monolithic height rule
地表与近地表生成应拆成更清楚的阶段责任，而不是继续把地貌、洞口、局部 landmark 和安全带逻辑都塞进一个高度采样结果里。

Suggested responsibility order:
- macro landform selection
- biome-specific relief shaping
- local breakup and smoothing
- entrance and ravine pass
- landmark or decorator pass

Reasoning:
- 这更接近 Terraria 式的多 pass 生成经验，能避免单条公式承担过多互相冲突的目标。
- 入口、湖盆、山脊、谷地都属于不同层级的问题，绑在同一噪声结果上会让每个目标都变弱。

Alternatives considered:
- 继续在现有 surface height 基础上叠加更多条件分支。短期改动小，但最终会把生成逻辑变成不可维护的阈值堆叠。

### Decision: Keep a traversable starter corridor while allowing stronger relief elsewhere
地表 relief 强化不能破坏出生区和早期探索的可玩性，因此出生安全带仍需保留低坡度、有限落差和基础可见入口。

Reasoning:
- Terraria 风格世界有山有谷，但出生点附近通常不会直接给新手一个连续不可跨越的山墙或深裂谷。
- 现有教程、NPC 落位和基础资源采集都依赖一个温和开局。

### Decision: Model underground variety as layered strata plus regional overrides
地下变化不能只靠“地表 biome 对应一个 underground_biome”这种单跳映射，而应由：

- ordered depth strata
- macro region override
- local cave archetype

共同决定。

Reasoning:
- 玩家希望感知到“越往下越像进入另一个层带”，而不是永远只是石头背景里掏几个洞。
- 这种分层也更适合之后绑定矿物、危险度和探索奖励。

Alternatives considered:
- 仅增加更多 underground_biome 枚举。这样会增加标签数量，但如果没有分层与过渡规则，结果仍然会像随机拼贴。

### Decision: Add shaped subterranean archetype families, not only generic cave tags
地下除了 depth strata 外，还需要一组具有明确几何身份的 archetype family，用来生成玩家能辨认的“区域形状”。

Candidate families:
- long horizontal hall or gallery
- wide-open cavern with ledges
- dense compartment or hive-like cluster
- sink-connected rift descent
- rare shaped pocket complexes

Reasoning:
- Terraria 的 Underground Desert、Granite Cave、Marble Cave、Bee Hive 等区域之所以有记忆点，不是因为标签名字，而是因为空间轮廓本身不同。
- 只扩展现有 Tunnel/Chamber/Pocket 等局部 tag，仍然不足以表达“大区域的形状”。

Alternatives considered:
- 仅通过材质和敌人区分地下区域。这样会让不同区域看起来仍然像同一个洞穴生成器的换皮版本。

### Decision: Replace the single visible cave lane with a network backbone model
当前 _get_cave_lane_y() 形成的正弦式主干有工程价值，但玩家能直接观察到它。新的 cave topology 应改为“主干网络 + 分支 + 腔室 + 局部竖向连接”的骨架模型，或任何等价的非显性方案。

Hard constraints for the new model:
- 不能退化为无规则封闭空腔堆叠
- 不能在 chunk 边界失去连续性
- 不能让出生附近完全没有安全下探路径
- 不能继续暴露单一、连续、易识别的波形主干

Reasoning:
- 玩家不应该看到生成器本体，而应该看到“看起来合理的洞穴系统”。
- 现有 spawn 系统已经依赖 region tag，因此应保留可分类的结果，而不是回到不可解释的纯噪声 carve。

### Decision: Reserve explicit long-form underground routes
地下除了局部可达性外，还应保留至少一种长程可跟随路线家族，用于连接较大的洞穴系统。

Possible forms:
- abandoned mine style corridor
- root or fossil artery tunnel
- rock bridge gallery
- connector chain through multiple caverns

Reasoning:
- Terraria 的废弃轨道提供了一个很实用的启发：玩家需要偶尔遇到可以“沿着走一阵”的地下路线，而不是每个区域都重新找入口和重建方向感。
- 这类路线还能为 landmark、loot、事件和后续敌人分布提供天然挂载点。

### Decision: Treat cave entrances as first-class worldgen outputs
自然洞口不能只是偶发结果，而应作为明确 worldgen 产物来控制数量、位置和类型。

Entrance families may include:
- open cave mouth in hillside
- sinkhole or collapse opening
- cliff-side slit entrance
- shallow ravine leading underground
- funnel pit or burrow-style descent
- zigzag chamber entrance

Reasoning:
- 用户的核心抱怨之一是“看见洞就想进去”的体验缺失。
- 如果入口仍然完全依赖内部 cave carve 偶然撞到地表，结果通常要么太少，要么分布不可读。

### Decision: Preserve existing cave-region query compatibility by extending metadata, not deleting it
spawn 和 encounter 系统当前依赖固定 region tag: Surface, Tunnel, Chamber, OpenCavern, Pocket, Connector, Solid。这个 change 可以重构生成骨架，但不应无准备地推翻消费方接口。

Implementation direction:
- 保留现有基础 region classification 或提供明确兼容映射
- 新增入口类型、 strata id、 relief context、 branch depth 或等价字段时采用 additive metadata

Reasoning:
- 这样可以把 terrain quality 提升与 hostile/ecology 系统解耦，避免 proposal 过度膨胀。

## Architecture

### 1. Surface Relief Stack
建议将地表高度拆分为下列可解释层：

- world-plan relief profile: 当前 macro arc 更偏平原、丘陵、山地、盆地还是过渡带
- biome relief modifier: 同一宏观地貌在 forest/desert/tundra/swamp 下的振幅、坡形和边缘处理不同
- local breakup noise: 小尺度起伏、峰顶粗糙、坡面断裂和微地形
- spawn corridor clamp: 对出生安全带做额外平滑和落差预算限制

Recommended pass-like order:
1. choose macro relief profile from world plan
2. apply biome-specific shaping and silhouette rules
3. add local breakup, cliffs, shelves, and smoothing
4. carve or place eligible entrance families
5. place local decorators and structures that depend on the relief outcome

Key expectation:
- 玩家长距离移动时，应该能识别“正在穿过一段山地或谷地”，而不是只看到高度曲线随机抖动。
- 这类识别应在大量复用现有草、土、石、沙、雪、泥主材质时依然成立，而不是依赖每段 relief 都换一套新瓦片。

### 2. Underground Strata Model
建议把地下至少划分为可读层带，例如：

- shallow entry band
- upper cavern band
- mid cavern band
- dense deep band
- terminal or core-adjacent band

Each band should influence:
- stone/background palette family
- cave openness and connector frequency
- mineral table and hazard weight
- allowed pocket/cavern archetypes
- compatibility with surface macro region overrides

Asset implication:
- 首轮 strata 差异应允许通过背景墙、空腔几何、矿物密度、局部装饰和有限 accent tiles 建立，不要求每层都拥有全新主岩石 atlas。

Strata alone are not enough. Each band should be able to host shaped regional sub-biomes, for example:
- desert-like oval burrow field
- forest-rooted cracked galleries
- ice split caverns with fragile surfaces
- fungal or mossy open pockets

### 3. Cave Backbone and Branching
洞穴生成建议采用“少量强约束主干 + 局部分支 + 稀有大腔室”的方式，而不是一条单独的显性函数。

The design does not mandate one algorithm, but it does require:
- main routes exist and are periodically reconnectable
- branch routes can deviate without collapsing into isolated dead zones
- chamber placement reads as local expansion around a route, not random balloons everywhere
- vertical links are readable and cadence-controlled instead of periodic obvious drilling

Possible implementation families:
- seed-derived polyline or spline backbone sampled per region
- domain-warped corridor fields with anchor nodes
- planned entrance anchors feeding into local branch graphs

Additional expectation:
- at least one long-form traversable route family should periodically bridge multiple larger underground spaces, giving the player a sense of direction beyond purely local cave pockets

### 4. Entrance Placement Layer
入口应独立于纯 cave carve 阈值来规划：

- spawn corridor gets at least one forgiving near-surface descent path within a bounded wrapped distance
- non-spawn regions periodically expose discoverable entrances without making the surface collapse into Swiss cheese
- mountain, cliff, basin and ravine relief profiles can bias entrance family selection

Suggested family mapping:
- basin or desert-like relief prefers funnel, pit, burrow, or chambered entrances
- hill and forest relief prefers cave mouths, root cracks, or shallow ravines
- cliff relief prefers slit entrances or stepped cut descents

Expected player-facing result:
- 玩家在地表巡游时会周期性遇到“明显值得进去”的入口，而不是大多数时候只能原地向下挖。
- 入口的可读性应尽可能先由轮廓、开口形状和局部装饰完成，而不是预设每种入口都必须有一套独立美术包。

### 5. Query and Validation Hooks
为保证后续 hostile/spawn/content 系统能继续使用 terrain metadata，建议保留并扩展如下查询层：

- surface relief category at tile/region
- underground strata id at tile/region
- cave entrance tag and entrance reachability
- existing cave region tag plus richer openness/branch context
- long-route membership or route-role tag when applicable

These hooks should be deterministic and chunk-stable.

## Risks / Trade-offs
- 更强的 relief 可能让移动成本过高，尤其在出生区和教程附近。
  Mitigation: 对出生安全带、关键地标附近和早期 biome transition 设置坡度与落差预算。

- 自然洞口增多后，地表可能显得破碎或资源点过于集中。
  Mitigation: 入口采用预算与最小间距控制，并按 relief profile 选择类型，而不是全图均匀撒点。

- 替换正弦主干后，如果缺少强约束，地下可能重新退化为封闭 pockets 或不可读迷宫。
  Mitigation: 先定义主干连通性、支洞预算和重连规则，再让局部噪声塑形。

- 新增 metadata 容易影响现有刷怪逻辑。
  Mitigation: 保持旧 region tag 的兼容映射，把新增信息作为附加上下文字段暴露。

- 如果默认需要大量新瓦片，变更会被美术吞吐和 atlas 回归成本卡死。
  Mitigation: 将新瓦片预算控制为少量 accent/transition assets，优先验证结构、背景、装饰和材质家族复用是否已足够表达差异。

## Migration Plan
1. 先盘点当前 atlas 耦合点与可复用材质家族，明确哪些视觉差异可以不增加新瓦片先实现。
2. 明确 surface relief category、underground strata 和 entrance metadata 契约。
3. 用新 relief stack 替换单层 surface height 逻辑，同时保留 spawn-safe smoothing。
4. 以兼容方式替换 _get_cave_lane_y 主干模型，先保证查询结果和 reachability 不回退。
5. 加入 shaped subterranean archetype families，并将其绑定到 strata 与 macro region。
6. 接入自然入口层与长程路线层，并调校与 surface relief profile 的关系。
7. 仅在结构和装饰仍不足以表达差异的点位，补最小规模 accent/transition tiles。
8. 最后让 surface features、structures、spawn queries 和验证脚本消费新的 metadata。

## Validation Strategy
- 对多个代表性 seed 验证：地表必须同时出现明显平缓区、丘陵/山地区和低地/谷地过渡，而不是全图同一振幅。
- 对多个代表性 seed 验证：地下层带随深度变化可读，且 surface macro region 会改变局部地下表现。
- 对多个代表性 seed 验证：洞穴网络不再暴露单一连续正弦式骨架，并存在多种可发现的自然入口家族。
- 对多个代表性 seed 验证：至少部分地下区域呈现稳定可识别的成形 archetype，而不是统一噪声空腔。
- 对多个代表性 seed 验证：玩家可以沿至少一类长程路线连续穿越多个地下区域，而不必频繁回到竖井搜索。
- 对代表性 seed 验证：即使只使用现有基础材质家族和少量新增 accent tiles，地貌与地下 archetype 的可读性仍然成立。
- 继续验证 determinism、chunk reload 一致性、spawn-safe corridor、chunk seam 连续性和现有 cave region 查询兼容性。

## Open Questions
- 首轮实现是否要把 entrance family 做成纯 tile carve，还是需要少量 entity/scene 辅助来增强视觉辨识度。
- 是否需要在 minimap 或 debug overlay 中暴露 entrance/relief/strata 元数据，帮助调参和回归验证。
- 首轮允许新增多少 accent/transition tiles 才不会重新滑向“先补整套 tileset”的高成本路径。