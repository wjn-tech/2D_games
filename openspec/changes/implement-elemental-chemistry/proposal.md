# Change: Stage Liquid Simulation and Elemental Interactions

## Why
当前项目几乎还没有真正的液体系统。代码里只有少量与 water 或 lava 相关的注释和邻近条件判断，但不存在可持续的世界液体模拟、地形液体生成、液体与方块/实体/物品的系统性交互，也没有把液体作为一个明确的可流动世界层来管理。

如果只把需求写成“液体下落并铺平”，最后大概率会得到一个能演示但不适合沙盒世界的玩具系统：

- 对 chunk streaming 和持久化不友好，不能稳定地在大世界里运行。
- 无法表达 Terraria 那种“液体类型不同，所以探索和建造决策也不同”的玩法身份。
- 也无法吸收附件里的 Godot fluid demo 所擅长的那部分价值，因为那个 demo 适合做局部高保真表现，不适合作为整张地图的权威液体模拟。

这次 proposal 的目标不是机械照搬 Noita 或 Terraria，而是提炼一个适合本项目的分层方案：

- 用 chunk-friendly、可持久化的液体模拟作为玩法权威层。
- 用 Terraria 式的液体类型差异、生成/沉降、混合反应、视觉型 liquidfall 分层来定义规则边界。
- 用附件项目里“刚体粒子 + 着色器融合”的思路作为可选表现增强，而不是世界真相。

## What Changes
- 将原本过于抽象的“元素化学”提案收束为以液体为核心的分阶段系统：先建立 Water/Lava 的基础世界液体能力，再为 Honey 和特殊转化液体预留扩展位。
- 定义权威液体数据模型：液体类型、填充量、活动标记、来源/沉降状态、与 tile openness 的关系。
- 定义运行时模拟边界：仅对活跃 chunk、活跃前沿和世界生成后的沉降阶段进行更新，而不是在全图做高成本逐粒子模拟。
- 定义世界生成液体家族：地表积水、浅层水袋、洞穴湖、深层熔岩池，以及与特定 biome/structure 绑定的特殊液体口袋。
- 定义液体类型差异：至少支持水更快、熔岩更慢且危险、蜂蜜更黏且带增益、特殊转化液体拥有独特交互而不是普通伤害逻辑。
- 定义液体与地形/实体/元素的交互：方块开口度、半格/斜坡/格栅类通道、混合固化、灭火/点燃、移动减速、窒息或灼烧等效果。
- 明确把真实液体体积与视觉型 liquidfall、drip、splash 分开；视觉瀑流可以存在，但不要求它们一定消耗真实液体源。
- 把附件 fluid demo 的参考地位写清楚：可借鉴为局部液面、飞溅、黏连轮廓和 shader 表现，但不作为世界液体主模拟方案。

## Detailed Scope
- 本 change 首要解决的是 liquid simulation、liquid worldgen、liquid interaction 与 liquid presentation 四个层次；不承诺一次性完成全量 Noita 式元素矩阵。
- 第一阶段以 Water 和 Lava 为必做基础液体；Honey 作为第二阶段的慢速增益液体；Shimmer-like 特殊转化液体仅要求在架构上留出独立规则通道，不强制首版完整落地。
- proposal 要求液体采用 tile 或 sub-tile 填充模型，而不是把世界液体建成全局刚体粒子群。填充精度可以是离散台阶，也可以是固定精度分数，但必须能表达“半格以上”“薄层会消散”之类规则。
- 运行时必须与 chunk streaming、deterministic generation 和 delta persistence 兼容；液体不能因为玩家离开区域就丢失状态，也不能因为重新载入而明显改写先前结果。
- 世界生成必须包含“生成后沉降/整理”步骤或等价机制，避免玩家首次进入时看到大量明显未稳定的液体悬挂态。
- 需要显式区分功能性液体体积与表现性液体瀑流/滴落。后者可以用更便宜或更华丽的视觉方案，但不能要求它们参与同等级的体积守恒。
- 需要为 bucket、pump、放液/吸液工具或等价交互预留接口，即便首版只先打通最基础的玩家放置/回收能力。
- 火焰系统不再作为本 change 的唯一中心；它保留为液体反应表的一部分，例如水灭火、熔岩点燃、特定材料受热变化，但不要求首版完成完整火生态。
- 附件项目中的刚体液滴方案仅作为局部表现增强参考，例如角色附近的飞溅、瀑流边缘、池面黏连轮廓或高质量过场镜头；proposal 明确不把它用作整图液体真相。

## Current Baseline
- 当前代码库没有独立的 ChemistryManager 或 LiquidManager，也没有权威的液体网格/场。
- 世界生成目前聚焦地表、矿物、洞穴和 biome，没有成体系的液体口袋生成、沉降整理或液体元数据查询。
- 现有代码能找到的相关痕迹很少，典型例子是挖掘/掉落逻辑中把 Water/Lava 视为通常“不掉落或靠 bucket 处理”的注释，但 bucket 本身并未形成真实系统。
- 建造配方里已有“附近需要水”这类前提，说明世界 eventually 需要可靠的液体存在性判断，而不是纯视觉贴图。
- 附件 Godot fluid demo 采用的是 PhysicsServer2D 刚体粒子 + screen-space shader 的方案，视觉上适合做高保真水体，但并不解决大世界 chunk、存档、混合反应和玩法查询问题。

## Reference Synthesis
- Terraria 的液体之所以好用，不只是因为“会往下流”，而是因为它把液体拆成了几个不同层次：部分填充、沉降整理、不同液体的流速/黏度差异、与半砖/格栅/泡泡类方块的交互、功能性液体与纯视觉 liquidfall 的分离，以及混合生成固体的玩法反应。
- Terraria 还证明了液体不需要一开始就做成统一的“万能元素沙盒”。先让 Water/Lava/Honey/Shimmer 各自拥有明确身份，再通过小而硬的规则表建立反应，玩家体验会比抽象的大而全 chemistry 更可靠。
- 附件 demo 则提供了另一个关键启发：高质量液体外观可以独立于主模拟存在。世界模拟保持简单、稳定、可持久化，近景表现再用 shader 或粒子去补，是更适合本项目阶段的路线。

## Impact
- Affected specs: ca-simulation, liquid-worldgen, liquid-interactions, liquid-presentation
- Affected code: src/systems/world/world_generator.gd, src/systems/world/infinite_chunk_manager.gd, src/systems/world/digging_manager.gd, future liquid/chemistry manager modules, item/tool systems that will own bucket or pump behavior, rendering code for liquid surfaces and liquidfalls
- Affected data: TileSet or tile metadata for openness/flammability/heat resistance, world chunk persistence payloads, biome or structure liquid spawn rules, liquid reaction tables, item definitions for liquid placement and collection tools
- Relationship to external references: Terraria 提供玩法规则和生成分层的参考；附件 fluid-water-physics demo 只作为可选表现层灵感，不作为权威模拟实现

## Acceptance Direction
- [ ] 世界中的功能性液体能够以可持久化的填充模型在活跃区域流动、堆积和稳定。
- [ ] Water 与 Lava 至少表现出明显不同的流速、危险性和反应身份，而不是仅换颜色。
- [ ] 世界生成能放置并沉降至少两类功能性液体储层，而不是只支持运行时手工倒水。
- [ ] 液体与方块/实体/火焰的基础交互可被规则化查询，而不是散落在多个硬编码判断中。
- [ ] 视觉型 liquidfall 或 splash 可独立于权威体积存在，不会迫使主模拟走向全局刚体粒子方案。
