# Design: Refine Terrain Relief and Cave Topology

## Context
当前世界已经具备三个不错的基础：

- 行星式东西环绕拓扑已经存在，世界不再只是无界横向平铺。
- WorldGenerator 已经暴露 surface biome、surface feature 和 cave region 查询，刷怪与探索系统可以读取上下文。
- 地下可达性已经不是纯随机洞，而是有一套保证主路径存在的骨架。

但这套骨架现在太容易被玩家看穿了。地表的主要问题不是“没有装饰物”，而是地形轮廓本身缺少节奏；地下的问题也不是“完全没有洞”，而是空间形态与过渡太单一，且主干洞穴的波形过于明显。用户提出的目标，本质上是把世界从“可运行的噪声地形”提升到“有地貌语言、探索诱因和可读层次的地形系统”。

最近回传的代表性截图进一步说明，问题已经不是抽象的“变化不够多”，而是存在几种非常具体的坏相：

- 地表轮廓在宽视野下仍然接近一条长平台，只有零散的小型台阶和短促凸起，缺少 Terraria 那种远距离就能读出的丘陵、山坳、断崖或洼地节奏。
- 地下主视图里大量区域由同一种浅色块体和相似背景填满，矿点虽然存在，但还不足以建立层带或子区域身份，导致玩家很难读出“这里和上一段地下有什么本质不同”。
- 洞穴网络反复出现横向带、斜向交叉和孤立竖井，看上去更像生成器画出的笔画，而不是天然形成或值得探索的空间体量。
- 至少在当前截图中，区域切换仍可能表现为过硬的面状分界，而不是宏观分区明确、局部轮廓自然过渡的世界形态。
- 部分视图可见接近固定间距重复的错误图块或重复切口，说明目前仍存在可被玩家识别的周期性伪影。

如果用 Terraria 作为方法论对照，差距主要不在素材数量，而在四类生成语言目前还没真正建立起来：地表 silhouette、地下层带身份、自然入口和具有几何个性的洞穴家族。

如果进一步用 Terraria 实机图做同维度对照，当前工程还有三处更细颗粒的差距：

- Terraria 的入口通常和局部坡体、坑口、水体或侧壁同构；当前入口更像单一 carve 模板叠加在地表上。
- Terraria 的地下过渡常是“宏观分区稳定 + 局部边界自然破碎”；当前更容易出现近似单列切换的垂直硬边。
- Terraria 虽 deterministic 但重复节拍不容易直接看出；当前仍会暴露固定 spacing 驱动的结构节律。

外部参考对这个方向提供了很稳定的启发。Terraria 的世界生成并不依赖单一地形函数把一切都做完，而是通过多阶段地形塑形、显式 surface-to-underground 入口、具有固定几何轮廓的地下区域，以及跨长距离的地下可达路线来建立探索语言。这个 change 不需要复制其内容清单，但应吸收这些方法论。

另一个必须正面处理的现实约束是资产负担。当前项目的 terrain/material 消费链对 atlas 坐标耦合很重：world_generator、digging_manager、building 预览和部分掉落逻辑都假设少量固定瓦片。如果把这次 change 误解成“每个新地貌都先补一整套新瓦片”，实施量会被放大到远超 worldgen 本身。因此这个 design 需要明确一条低资产优先路线。

同样不能回避的还有加载成本。当前 InfiniteChunkManager 会在 `_process()` 里逐个取出待加载区块，并在主线程直接执行 `_build_chunk_on_main_thread()`，后者再串行调用 `generate_chunk_cells()`、结构应用和树木放置。这意味着 terrain/cave 逻辑每加一层复杂度，都可能直接体现为玩家靠近新区块时的帧时间抖动。因此本 change 不能只关注“能否生成出更好看的地形”，还必须约束“这些地形是否能在现有流式加载模型中无明显卡顿地到达屏幕”。

如果把这件事说得更精确一点：当前需要被优化的不是某一个抽象的“世界生成性能”，而是整个地图生成与加载关键路径上的底层算法簇。它们至少包括：surface height 采样、biome 和 depth band 判定、cave carve 与 reachability 判断、矿物和树木分布、入口/feature 选择、结构叠加、chunk metadata 生成、delta 覆盖与最终 chunk 调度。proposal 需要把这些算法簇都视为潜在热点，而不是只盯住队列或线程模型。

## Goals / Non-Goals

### Goals
- 让玩家横向长距离移动时能感知到明显不同的地表轮廓节奏，而不仅是材质换皮。
- 让地下随着深度和地表宏观区域变化，表现出有连续过渡的 strata/biome identity。
- 让洞穴网络看起来像自然形成的探索空间，而不是一条可见的数学曲线外加若干打孔。
- 让地表定期出现“可看见且愿意进入”的自然地下入口，并与教程安全带、出生保护和可达性约束兼容。
- 在不要求完整重做 tileset 的前提下，让 terrain identity 先通过结构、层次和少量重点资产建立起来。
- 让新增地貌复杂度与当前 chunk streaming 架构兼容，不把主线程区块构建推到容易感知的加载卡顿区间。
- 让地图生成与加载关键路径上的底层算法都拥有明确的成本控制策略，避免某个局部热点把整体 streaming 体验拖垮。
- 保持 deterministic generation、chunk 边界稳定性、delta persistence 和 spawn/query contract 的兼容性。

### Non-Goals
- 不在这个 change 中新增敌人家族、战斗招式或掉落体系。
- 不要求一次性重做所有 surface decoration 的美术资源。
- 不要求为每一种 relief profile、入口家族和地下 archetype 先绘制独立的整套基础瓦片 atlas。
- 不要求在本 change 开始前先重写整套 InfiniteChunkManager 线程模型。
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

### Decision: Treat chunk-generation cost as a first-class design constraint
新增的 relief、入口与地下 archetype 不能只以“视觉或探索效果更好”为完成标准，还必须满足区块生成在流式加载下可预算、可切片、可缓存。

Reasoning:
- 当前 `_build_chunk_on_main_thread()` 已经把区块生成、结构叠加和树木放置串在同一主线程路径上；继续无约束地加复杂逻辑，会直接转化为移动卡顿。
- 性能约束如果不在 proposal 阶段写清楚，后续实现很容易把“先做对效果”放在“先保证加载稳定”前面，最后被迫回头返工。

Alternatives considered:
- 先忽略性能，等实现完成再优化。对原型可行，但对本 change 不合适，因为主线程区块生成本来就是当前世界体验的敏感点。

### Decision: Optimize the full hot-path algorithm stack, not just scheduling
这个 change 的性能优化对象不是单一模块，而是所有落在地图加载关键路径上的底层算法层。

Hot-path families to consider explicitly:
- world-plan and region lookup
- surface height and relief sampling
- biome, underground-theme, and strata classification
- cave carve and reachability heuristics
- mineral, tree, and feature distribution
- structure overlay and post-processing
- chunk metadata prepass and cache fill
- chunk request scheduling and stale-work discard

Reasoning:
- 如果只优化调度，不优化每格循环里的高频判定，卡顿仍会发生，只是换一种位置出现。
- 如果只优化局部噪声采样，不优化结构叠加和后处理，复杂区块仍可能在边界加载时形成峰值。

### Decision: Push high-level queries out of inner loops whenever possible
只要某个判断在 chunk、sub-region 或 surface arc 级别上可复用，就不应继续在每个 tile 上重复求值。

Reasoning:
- 当前 `generate_chunk_cells()` 的双重循环已经很容易成为热点；新增 relief/archetype 后，如果继续在里面做 world-plan、theme、budget 类查询，单区块成本会成倍放大。
- 这类查询多半 deterministic 且空间上连续，适合预解算后复用。

### Decision: Budget optional passes aggressively
所有非 traversal-critical 的底层算法都应被看作可预算对象，而不是默认与关键几何同权。

Examples:
- secondary decorator placement
- localized accent decisions
- non-critical backdrop refinement
- optional archetype flourish passes

Reasoning:
- 确保“先可玩、再精致”的顺序对抗加载抖动最有效。

### Decision: Split traversal-critical generation from deferrable enrichment
区块生成内容应拆分为至少两类：

- traversal-critical work: 地表实体碰撞轮廓、基础洞穴可达性、关键入口开口、必须存在的背景/支撑元数据
- deferrable enrichment: 非关键装饰簇、次级 accent、可后置的细节润色、对首帧可走性无影响的附加标记

Reasoning:
- 玩家最先感知的是“我能不能走、会不会掉坑、这里有没有入口”，不是每个装饰簇是否同一帧到位。
- 先把关键几何和可达性做对，再给细节留出分帧或延迟预算，是控制加载卡顿最直接的办法。

### Decision: Cache deterministic world metadata before per-cell shaping expands
随着 relief、strata、archetype 和 route-role 元数据增加，生成器不应在每个 tile 上重复做高层 world-plan 和区域判定。应优先引入 chunk-local 或 region-local 可复用结果。

Reasoning:
- 现在 `generate_chunk_cells()` 已经会在双重循环里多次调用 biome/深度相关逻辑；如果再把更多高层判定直接叠进去，单区块成本会迅速膨胀。
- 这些元数据大多是 deterministic 的，天然适合缓存或预解算。

### Decision: Prefer bounded scheduling over burst loading
即使首版仍在主线程最终落地，区块生成也需要明确的调度预算和优先级策略，避免玩家快速移动时把多个重区块串成连续卡顿。

Reasoning:
- 当前 `_process()` 每帧取一个待处理区块是一个很朴素的节流，但它并没有限制“单个区块能有多重”。
- 本 change 需要把复杂度控制和调度策略一起考虑，而不是默认“一帧一个区块”就足够安全。

### Decision: Eliminate periodic visual artifacts as a first-class quality target
本 change 不能只追求“看起来更丰富”，还必须显式消除可见的周期性伪影，包括固定间距入口重复、条带状连接笔画、以及近似单列硬切的地下边界。

Reasoning:
- 一旦玩家能读到生成器节拍，探索沉浸会先于内容丰富度失效。
- 目前入口、连接和主干都仍保留固定 spacing 驱动成分，如果不把“去周期可见性”写成独立目标，回归时很容易重新出现同类坏相。

Implementation direction:
- 对入口、连接、主干 anchor 使用 deterministic 的多尺度非周期锚点策略（如分层 jitter/蓝噪声风格分布/区域相位扰动）。
- 对 biome/strata 边界引入最小过渡宽度和局部破碎规则，避免单列硬切。
- 增加轻量后处理清扫（孤立小块、条带噪声、非支撑浮块），并保持 deterministic 与 chunk seam 连续性。

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

### 6. Streaming and Generation Budget
建议把生成路径拆成更明确的成本层：

- chunk metadata prepass: 本区块 relief profile、strata band、archetype candidates、入口预算、route-role 候选
- critical geometry pass: 地表轮廓、关键洞穴主干、可达入口、必要背景/实心层
- secondary enrichment pass: 次级装饰、局部 accent、延后无害的细节变化

Key expectation:
- 玩家靠近未加载区块时，首先拿到的是可通行、可解释的地形，不是被重装饰逻辑阻塞后的整块卡顿。
- 非关键细节应允许被调度、切片或降级，而不是与关键几何捆绑同一成本路径。

Suggested hotspot checklist for implementation planning:
- avoid repeated world-plan lookups per tile when a per-chunk answer suffices
- avoid re-running biome/theme selection multiple times for the same column or sub-region
- keep cave reachability heuristics bounded and deterministic rather than recursive or burst-heavy
- keep structure and tree overlay passes from duplicating already-known terrain decisions
- keep delta application and post-load finishing cheap relative to core chunk shaping

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

- 如果把更多 region/archetype 判定直接塞进每格生成循环，移动加载时会出现更明显的帧时峰值。
  Mitigation: 将高层元数据预解算或缓存，并把关键几何与可延后细节拆分到不同预算层。

- 如果只做内容复杂化、不做调度分层，代表性 seed 可能在大跨度移动时持续出现加载抖动。
  Mitigation: 在设计层明确区块构建预算、关键路径优先级和可延后 enrichment 范围，并把它们纳入验证。

- 如果某些底层算法未被纳入热点审计，它们会在看似“已经优化过”的加载路径里继续制造隐性峰值。
  Mitigation: 对关键路径算法簇逐项建账，并在任务层分别落到缓存、预算或降级策略，而不是只做笼统的性能目标。

## Recommended Rollout Order
这次改造不应该从“把所有地形系统一起推翻重写”开始，而应该按玩家最容易感知、同时又最不容易把 streaming 直接做坏的顺序推进。

### Wave 1: 先修正最明显的视觉骨架问题
目标是尽快消除当前地图最容易被一眼看穿的两件事：过平的地表和过明显的单波形洞穴主干。

- 先把 surface height 从单一轮廓提升为宏观 relief profile 加局部 breakup 的两层结构。
- 同时把 `_get_cave_lane_y()` 一类单一主干替换成更不显眼的 anchor 或 backbone 模型，但先不急着把所有地下 archetype 一次做满。
- 这一波结束后，玩家应该先感知到“地表不再是一条长平台”“地下不再像一条公式曲线”。

Concrete implementation slice:
- 在 [src/systems/world/world_generator.gd](src/systems/world/world_generator.gd) 中把当前 `get_surface_height_at()` 的职责拆为：macro relief profile 选择、profile shaping、local breakup 三层，而不是继续只做 `continental noise * biome amp`。
- 第一版 macro relief profile 只要求支持四类：starter-flat、rolling、ridge、basin；不在这一波引入更多 profile 名称。
- 在同一文件中，用 anchor-driven route 或等价 deterministic backbone 替换 `_get_cave_lane_y()` 的单条正弦线，但保留现有 region tag 输出接口，避免同时冲击下游 encounter/spawn 消费方。
- 第一波不引入完整 strata、完整 entrance family 和大规模新瓦片，只允许为了 debug/验证补充最小查询字段和必要可视化钩子。

Reasoning:
- 这是当前截图里最显眼、最伤第一印象的问题。
- 这两点主要改的是几何骨架，资产依赖低，回报最高。

### Wave 2: 再补地表到地下的探索邀请
当地表 silhouette 和地下主骨架不再出戏后，第二优先级是让玩家自然地进入地下，而不是总靠原地向下挖。

- 加入 entrance family、入口预算和 spawn-safe early descent。
- 让 surface feature/landmark pass 感知 relief 与 entrance 结果，而不是继续假设地表近似平坦。
- 这一步的成功标准不是入口数量更多，而是玩家巡游时会稳定遇到“值得进去”的入口类型。

Concrete implementation slice:
- 第一版 entrance family 只要求三类：gentle mouth、ravine-cut、pit/funnel，不在这一波扩成更多造型目录。
- 入口预算先绑定到 relief profile 和 spawn-safe distance，不先绑定完整地下 sub-biome 体系。
- 入口 carving 必须先被归类为 traversal-critical pass；入口附近的装饰、背景 accent 和非关键润色默认后置。

Reasoning:
- 入口系统能直接改变探索行为，比先做大量地下子生态更快形成 Terraria 式体验。
- 它还能复用 Wave 1 已经得到的 relief profile，避免重复返工。

### Wave 3: 建立地下层带与 archetype 身份
当地表节奏和入口都成立后，再去解决“地下看起来到处一样”的问题。

- 引入 ordered strata、macro-region override 和 shaped archetype family。
- 优先用背景、空腔形状、openness、矿物密度和少量 accent tiles 建立层带身份。
- 长程 route family 可以和 archetype 一起接入，但仍应先保证几何可读性，再追求内容密度。

Concrete implementation slice:
- strata 第一版只要求 shallow、upper-cavern、mid-cavern、deep 四层，不把 terminal/core 变体也塞进首轮。
- archetype family 第一版只要求 gallery、open-cavern、cluster、rift 四类，先保证玩家可分辨，再考虑额外变体。
- 地下身份建立优先顺序必须是 geometry > background > material weighting > accent tile，而不是反过来依赖素材数量。

Reasoning:
- 这一步会显著增加 metadata 和查询复杂度，放在前两波之后更安全。
- 只有当地表和入口已经提供稳定下探路径时，地下层带差异才更容易被玩家持续体验到。

### Wave 4: 清除周期伪影与硬切边界
当地表节奏、入口和地下层带可读性基本成立后，需要单独做一波“去生成器节拍”的几何体检。

- 识别并消除固定 spacing 在入口、连接、主干上的可见重复节拍。
- 为地表/地下区域切换建立过渡宽度与局部破碎规则，避免单列或极窄带硬切。
- 增加低成本 deterministic 清扫，抑制孤立错误图块、条带伪影和不合理浮块。

Concrete implementation slice:
- 对入口/连接 anchor 从“单一固定间距 + 轻抖动”升级到“多尺度锚点 + 局部相位扰动”的 deterministic 分布。
- 在 biome 与 strata 切换处增加过渡窗，允许 material 与空腔形态混合而不是一步切换。
- 增加图块合理性体检钩子：孤立块阈值、条带检测、过薄边界检测，作为调参与回归依据。

Reasoning:
- 这一步不新增大系统，但对“看起来像天然地形”有高杠杆收益。
- 不先做这一波，后续再加内容密度只会把伪影一起放大。

### Wave 5: 最后处理 streaming 预算、缓存和降级策略
性能工作不是最后才想起，但完整调度和降级策略应在主要生成语言已经稳定后定型。

- 把 relief、entrance、strata、archetype 的高层判定前移到 chunk-local prepass 或缓存层。
- 明确 traversal-critical pass 和 deferrable enrichment pass 的边界。
- 针对代表性移动路径做 budget 调整，避免 richer worldgen 重新放大加载卡顿。

Concrete implementation slice:
- 先缓存按 column、sub-region 或 chunk 复用的高层决策，不先做全局复杂求解器。
- 任何需要邻域大搜索或递归拼接的算法，都必须先给出 bounded work 方案，否则不能进入 critical path。
- 若 richer pass 无法在预算内稳定完成，默认删减装饰和次级 accent，而不是删减核心可走性与入口可读性。

Reasoning:
- 如果太早锁死 budget 模型，后面生成语言一改，缓存层和调度策略还得重做。
- 但如果完全不做前置性能审计，又会在后期集成时一次性爆出太多热点，所以这一步是“定型”，不是“第一次想到性能”。

## Quality Gates
这次 change 需要的不只是“实现了任务项”，而是每一波都必须通过固定观察法下的视觉和可玩性门槛。

### Gate A: Baseline Artifact Lock
- 在实现前固定一组代表性 seed 和观察视图，至少包括：出生区地表宽视图、非出生区地表宽视图、浅层地下、中层地下、长距离横向地下路线。
- 后续每一波都必须回到同一组 seed 和视图比较，避免只凭主观印象判断“是不是变好了”。

### Gate B: Wave 1 Exit
- 宽视图里不再主要读到长平台地表。
- 长距离地下观察中不再主要读到单一正弦或等价重复波形主干。
- 出生区附近仍保持可通行，不因 relief 强化直接劣化成新手障碍带。

### Gate C: Wave 2 Exit
- 代表性 surface travel 中稳定出现可辨认入口。
- 入口不止一种 silhouette，且不会把地表打成满屏孔洞。
- spawn-safe corridor 周边至少存在一条温和 early descent。

### Gate D: Wave 3 Exit
- 浅层到中层地下能被稳定读成不同层带或 archetype，而不是同一种 pale stone mass 的轻微变种。
- archetype 差异主要靠空间形态成立，而不是靠“只有看贴图才知道不同”。

### Gate E: Wave 4 Exit
- 代表性视图中不再稳定出现固定间距重复入口、条带化连接笔画、单列硬切边界或等价周期伪影。
- 去伪影策略不引入新的 chunk seam 断裂或 determinism 回退。

### Gate F: Wave 5 Exit
- richer worldgen 不会在代表性移动路径上稳定制造新的重复加载卡顿。
- determinism、chunk seam 连续性、spawn-safe corridor 和 delta persistence 均不回退。

## Migration Plan
1. 先盘点当前 atlas 耦合点、主线程区块生成热点和所有关键底层算法簇，明确哪些视觉差异可以不增加新瓦片、哪些计算可以不落在关键路径上。
2. 明确 surface relief category、underground strata、entrance metadata 与 route-role 的契约，并区分 traversal-critical 与 deferrable 生成内容。
3. 先把可复用的高层 region metadata、column-level 判断与 chunk-local 预算提取出来，避免所有新增规则直接压进每格循环。
4. 用新 relief stack 替换单层 surface height 逻辑，同时保留 spawn-safe smoothing，并避免把所有新判定塞回每格循环。
5. 以兼容方式替换 _get_cave_lane_y 主干模型，先保证查询结果和 reachability 不回退。
6. 加入 shaped subterranean archetype families，并将其绑定到 strata 与 macro region。
7. 接入自然入口层与长程路线层，并调校与 surface relief profile 的关系。
8. 针对入口、连接与边界切换做去周期处理，加入非周期锚点策略、边界过渡窗与轻量图块清扫钩子。
9. 为区块构建引入可缓存元数据、算法预算与可分层调度，确保关键地形先于次级润色到达。
10. 仅在结构和装饰仍不足以表达差异的点位，补最小规模 accent/transition tiles。
11. 最后让 surface features、structures、spawn queries 和验证脚本消费新的 metadata，并对代表性加载路径做性能回归。

## Validation Strategy
- 对多个代表性 seed 验证：地表必须同时出现明显平缓区、丘陵/山地区和低地/谷地过渡，而不是全图同一振幅。
- 对多个代表性 seed 验证：地下层带随深度变化可读，且 surface macro region 会改变局部地下表现。
- 对多个代表性 seed 验证：洞穴网络不再暴露单一连续正弦式骨架，并存在多种可发现的自然入口家族。
- 对多个代表性 seed 验证：至少部分地下区域呈现稳定可识别的成形 archetype，而不是统一噪声空腔。
- 对多个代表性 seed 验证：玩家可以沿至少一类长程路线连续穿越多个地下区域，而不必频繁回到竖井搜索。
- 对代表性 seed 验证：即使只使用现有基础材质家族和少量新增 accent tiles，地貌与地下 archetype 的可读性仍然成立。
- 对代表性宽视图截图验证：不应再频繁出现“长平台地表 + 单一浅色地下基底 + 带状/交叉洞穴笔画 + 生硬区域切换”这一组当前地图已经暴露出来的坏相。
- 对代表性截图验证：不应再稳定出现固定间距重复图块、入口节拍重复、条带伪影或接近单列硬切的区域边界。
- 对代表性移动路径验证：新增地貌逻辑不会把区块加载放大成明显连续卡顿，关键地形与入口优先于次级润色到位。
- 继续验证 determinism、chunk reload 一致性、spawn-safe corridor、chunk seam 连续性和现有 cave region 查询兼容性。

## Open Questions
- 首轮实现是否要把 entrance family 做成纯 tile carve，还是需要少量 entity/scene 辅助来增强视觉辨识度。
- 是否需要在 minimap 或 debug overlay 中暴露 entrance/relief/strata 元数据，帮助调参和回归验证。
- 首轮允许新增多少 accent/transition tiles 才不会重新滑向“先补整套 tileset”的高成本路径。
- 首轮是否先采用严格主线程预算与分层调度，还是同时恢复部分 worker-thread 风格预计算来降低复杂地貌区块的峰值成本。