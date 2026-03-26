# Change: Refine Terrain Relief and Cave Topology

## Why
当前探索世界已经有基础 biome、洞穴、地标和行星环绕拓扑，但 terrain generator 依然暴露出三个明显短板：

- 地表高度主要来自单层低频噪声，整体轮廓偏平、重复度高，缺少山脉、盆地、丘陵群和可读的地貌节奏。
- 地下区域虽然已经有可达性与区域标签，但大多数深度带仍然表现为“石头底板 + 少量空腔”，缺少像 Terraria 那样随深度和地表宏观区域变化的地下层带与过渡感。
- 当前矿洞可达性严重依赖一条显性的正弦式主通道，玩家能感知到生成骨架本身，而且可自然进入的洞口太少，导致探索体验更像向下硬挖而不是“看到洞口就进去看看”。

这些问题已经不再是“再加一点装饰物”能解决的，而是 terrain relief、地下分层与 cave topology 模型本身需要升级。现有 change expand-exploration-terrain-and-hostiles 解决的是探索内容与敌对生态的广义丰富化，但没有把这三个生成缺陷细化成更硬的地形质量要求，因此需要一个后续 change 专门收紧生成契约。

这次 proposal 的外部参考结论也很一致：Terraria 之所以不会显得像“一张统一噪声贴图”，并不是因为它的单条高度曲线更复杂，而是因为它把世界拆成多阶段地貌塑形、显式地表入口结构、成形的地下子区域，以及可长期跟随的地下路线家族。这个 change 要吸收的是这些生成策略，而不是表面素材本身。

另外，本次更新如果按“每种新地貌都配一整套新瓦片”来做，成本会明显失控。当前 world_generator、digging_manager、building 预览与掉落判断都仍然强依赖少量 atlas 坐标，贸然扩张 tileset 会把实现风险从 worldgen 本身扩散到一批下游系统。因此这个 change 还需要明确一条资产策略：优先用地形结构、已有材质家族复用、背景/装饰层和少量强调瓦片来建立地貌身份，而不是默认重做完整主图块集。

## What Changes
- 将地表高度模型从单一噪声起伏升级为分层 relief 模型，显式支持平缓带、丘陵带、山脊/山群、盆地/谷地和 biome 过渡地貌。
- 将地表生成组织为更接近 pass stack 的流程：先建立宏观 landform profile，再叠加 biome 修饰、局部破碎和入口/地标塑形，而不是继续由单个高度函数承担全部职责。
- 为 major surface biome 增加可读的地形轮廓身份，要求 biome 差异不仅来自表层材质和装饰，也来自行走时能感知到的高差、坡度和天际线变化。
- 为地下引入更明确的 strata/region 语言，让浅层、洞穴层、中深层和终局层在空间形态、矿物、空腔密度与局部 biome 上都表现出连续但可区分的变化。
- 为地下增加具有明确几何轮廓的 sub-biome/archetype family，例如横向长廊型、开阔洞厅型、蜂巢/分舱型、裂谷下沉型或等价结构，避免所有区域都只是在同类洞穴噪声上换材质。
- 替换当前过于显性的单一正弦式 cave backbone，改为更自然的主干-支洞-腔室网络或等价模型，避免玩家一眼看出规则波形。
- 显式要求 near-surface cave mouths、裂隙、塌陷口、悬崖切口、漏斗坑道或等价自然入口家族，让玩家能在地表发现值得进入的地下路线，而不是主要依赖垂直下挖。
- 为地下保留至少一类长程可跟随路线或连接性骨架，用来把较大的洞穴系统串联起来，减少“每次都要重新竖挖找路”的体验。
- 增加一条明确的资产收敛策略：第一阶段的 relief、入口与地下 archetype 必须主要通过几何形状、已有主材质复用、背景变化、装饰层和少量 accent tiles 实现，而不是要求每个区域先拥有一整套全新基础瓦片。
- 保留 deterministic generation、chunk streaming、delta persistence、spawn-safe corridor 和 cave reachability 等已有硬约束，不允许以“更随机”为代价破坏可玩性和存档稳定性。

## Detailed Scope
- 该 change 主要细化 exploration-terrain-richness 与 exploration-underground-generation 两个 capability，不扩展 hostile roster，也不引入新的战斗系统需求。
- 地表 relief 必须与当前 planetary_v1 world plan 兼容；当存在宏观 biome arc 和 landmark slot 时，地貌变化应服从这些全局约束，而不是重新引入纯局部随机拼接。
- proposal 要求 surface relief、入口结构和局部 landmark 至少形成一个清晰的生成顺序或分层责任划分，避免“全部塞回 get_surface_height_at() 一条函数”式实现回潮。
- 地下 region 模型可以扩展现有 cave region metadata，但不得无计划地打破现有 spawn 查询契约；如需新增元数据，应优先采用增量字段而不是直接移除现有 region tag。
- 地下需要至少定义一组有几何身份的 sub-biome/archetype family，供不同 macro region 与 strata 组合调用，而不是只在 region tag 上增加更多名称。
- 新的 cave topology 必须继续保证 chunk 边界连续性、代表性 seed 的可达性，以及出生区附近的教程安全与基础下探体验。
- 入口生成必须采用 family/budget 思路，而不是只要求“偶尔能打到地表”；不同 relief profile 和 biome 应能偏向不同入口类型。
- proposal 至少要求一种长程连接性机制把多个洞穴区连接起来，形式可以是矿道、根系通路、石拱长廊或其他等价结构，不强制是可乘坐轨道。
- proposal 首阶段必须与当前 minimalist palette 和现有 atlas 坐标消费方兼容；允许增加少量新图块，但不把“完整重绘所有 terrain family”作为前置条件。
- 新地貌 identity 应优先通过 silhouette、层次、背景、装饰和 tile metadata 建立；只有当某个 archetype 缺少关键可读性时，才为它补小规模专用 accent tiles 或 transition tiles。
- 本 proposal 不锁死具体噪声算法或是否使用 spline/domain warp，但会锁定玩家可感知结果与验证标准。

## Current Baseline
- 地表高度当前主要由 get_surface_height_at() 中的 continental noise 与 biome amplitude 决定，出生区外的整体轮廓变化仍然有限。
- 地下洞穴分类已存在 Tunnel、Chamber、OpenCavern、Pocket、Connector、Solid 等 region tag，但可达性骨架仍依赖 _get_cave_lane_y() 生成的一条正弦式主通道与周期性竖向连接器。
- 地表 feature tag 目前只有少量小体量装饰，如 StoneOutcrop、DesertSpire、FrostSpire、MudMound、GrassKnoll，无法承担山地或谷地级别的 relief 身份。
- 当前没有显式的入口 family 规划，也没有地表 cues 与地下大型区域一一对应的稳定关系，导致“看见某种地貌就知道下面大概有什么”的探索阅读性较弱。
- 当前也缺少能够串联较大地下区域的长程通行骨架，玩家更容易感知到局部洞而不是成体系的地下路线。
- 当前 terrain 材质消费方对 atlas 坐标耦合较重，尤其是 world_generator 与 digging_manager 中的材质、掉落和硬度判断仍绑定少量现有瓦片；这意味着“多加很多新瓦片”不是纯美术问题，也会放大实现与回归成本。
- expand-exploration-terrain-and-hostiles 已经要求“地下有 distinct traversal archetypes”和“地表更丰富”，但尚未把 relief 轮廓质量、地下层带过渡和自然洞口密度具体化。

## Impact
- Affected specs: exploration-terrain-richness, exploration-underground-generation
- Affected code: src/systems/world/world_generator.gd, src/systems/world/infinite_chunk_manager.gd, src/systems/world/world_topology.gd, src/systems/npc/npc_spawner.gd, any debug tooling that validates cave reachability or terrain readability
- Affected data: world-plan surface region metadata, cave region metadata, surface feature placement rules, underground biome/strata selection rules, terrain material family mappings, and any limited accent-tile or transition-tile definitions introduced to support readability
- Relationship to existing changes: 这是 expand-exploration-terrain-and-hostiles 的后续深化，专门把玩家已经感知到的 terrain/cave 生成缺陷收紧为可验证要求；它同时建立在 shift-worldgen-to-planetary-wraparound 已提供的 world-plan 和环绕拓扑基础之上