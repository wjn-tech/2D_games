# Change: Refine Terrain Relief and Cave Topology

## Why
当前探索世界已经有基础 biome、洞穴、地标和行星环绕拓扑，但 terrain generator 依然暴露出三个明显短板：

- 地表高度主要来自单层低频噪声，整体轮廓偏平、重复度高，缺少山脉、盆地、丘陵群和可读的地貌节奏。
- 地下区域虽然已经有可达性与区域标签，但大多数深度带仍然表现为“石头底板 + 少量空腔”，缺少像 Terraria 那样随深度和地表宏观区域变化的地下层带与过渡感。
- 当前矿洞可达性严重依赖一条显性的正弦式主通道，玩家能感知到生成骨架本身，而且可自然进入的洞口太少，导致探索体验更像向下硬挖而不是“看到洞口就进去看看”。

这些问题已经不再是“再加一点装饰物”能解决的，而是 terrain relief、地下分层与 cave topology 模型本身需要升级。现有 change expand-exploration-terrain-and-hostiles 解决的是探索内容与敌对生态的广义丰富化，但没有把这三个生成缺陷细化成更硬的地形质量要求，因此需要一个后续 change 专门收紧生成契约。

最近一轮实际地图回传把这些缺陷暴露得更具体了：地表在宽视野里仍然主要表现为接近平直的平台，只夹杂少量短促凸起；地下大面积区域被同一种浅色基底主导，只点缀稀疏矿点和少量灰色团块，层带身份很弱；洞穴网络则频繁呈现横向带状通道、重复的斜向交叉和孤立竖井，玩家很容易读到“生成骨架”而不是“自然地形”。这些现象与 Terraria 那种依靠地表 silhouette、地下层带、自然入口和成形洞穴家族来建立探索语言的效果还有明显差距。

这次新增回传还暴露出更紧急的稳定性问题：在若干视图里出现了沿固定间距重复的错误图块或形态重复，典型表现为接近等间隔的入口切口、重复深度带上的连接笔画、以及接近单列切换的地下材质边界。这类“周期性伪影”会直接破坏探索沉浸，因为玩家会先看到生成器节拍，再看到地形本身。

这次 proposal 的外部参考结论也很一致：Terraria 之所以不会显得像“一张统一噪声贴图”，并不是因为它的单条高度曲线更复杂，而是因为它把世界拆成多阶段地貌塑形、显式地表入口结构、成形的地下子区域，以及可长期跟随的地下路线家族。这个 change 要吸收的是这些生成策略，而不是表面素材本身。

另外，本次更新如果按“每种新地貌都配一整套新瓦片”来做，成本会明显失控。当前 world_generator、digging_manager、building 预览与掉落判断都仍然强依赖少量 atlas 坐标，贸然扩张 tileset 会把实现风险从 worldgen 本身扩散到一批下游系统。因此这个 change 还需要明确一条资产策略：优先用地形结构、已有材质家族复用、背景/装饰层和少量强调瓦片来建立地貌身份，而不是默认重做完整主图块集。

还有一个同样需要前置收紧的约束是生成性能。当前 InfiniteChunkManager 会在主线程逐帧取出待加载区块，再直接调用 generate_chunk_cells、结构叠加与树木生成；这意味着只要单区块生成复杂度继续上涨，玩家在移动加载边界时就更容易遇到明显卡顿。terrain/cave proposal 如果不把性能预算写成硬边界，就很容易在“地貌更丰富”的同时把加载体验做坏。

这次更新还需要把“所有底层算法”落到明确范围内：这里指的是当前地图生成与加载关键路径中的底层算法，而不是整个项目所有脚本。至少包括地表高度采样、biome 判定、深度带/region 判定、洞穴 carve、入口选择、矿物与树木分布、结构叠加、chunk metadata 预解算、delta 应用与 chunk 调度。proposal 需要明确这些环节都必须纳入性能审视与优化边界，不能只优化队列调度而放任热循环继续膨胀。

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
- 增加一条明确的生成性能约束：新的 relief、入口、archetype 与长路线不能无上限堆高单区块主线程生成成本，必须支持分阶段、可预算、可缓存的区块构建策略。
- 将地图生成与加载关键路径中的底层算法都纳入性能优化范围，要求对高频采样、区域判定、carve/feature 叠加、结构拼装和流式调度分别给出成本控制策略，而不是只做单点微调。
- 保留 deterministic generation、chunk streaming、delta persistence、spawn-safe corridor 和 cave reachability 等已有硬约束，不允许以“更随机”为代价破坏可玩性和存档稳定性。

## Delivery Strategy
- 预备阶段先做截图驱动的差距固化：把本游戏截图和 Terraria 参考图在同一观察维度下做形态标注，至少固化地表轮廓节奏、入口可见性、洞穴体量、层带身份、过渡自然度、周期伪影六个维度的基线证据。
- 第一阶段只解决两类最伤观感的骨架问题：地表过平和地下单波形主干过于明显。对应到现有实现，就是优先替换 [src/systems/world/world_generator.gd](src/systems/world/world_generator.gd) 中以 `get_surface_height_at()` 为核心的单层地表轮廓，以及以 `_get_cave_lane_y()` 为核心的显性主干路径。
- 第二阶段再接 surface-to-underground 入口 family、入口预算和出生区早期下探路径，让玩家被地貌引导进入地下，而不是主要靠原地向下挖。
- 第三阶段再建立 strata、macro-region override 与 shaped archetype family，解决“地下各处读起来都差不多”的问题。
- 第四阶段专门清除周期性伪影与硬切边界：处理固定 spacing 带来的入口/连接重复感、处理地下材质或空腔的硬切分界，并引入低成本的后处理清扫以去除孤立错误图块。
- 第五阶段统一定型缓存、预算、降级与调度策略，把 richer worldgen 控制在当前 streaming 现实可接受的成本范围内。
- 每一阶段都必须先通过代表性 seed 和截图审查，再进入下一阶段；不允许在上一阶段的坏相仍然明显存在时继续叠加复杂度。

## Effect Gates
- 必须先建立固定的代表性 seed 集和固定观察视角，至少覆盖：出生区宽视图、非出生区地表宽视图、浅层地下、中层地下、长距离横向地下路线。
- 第一阶段的退出条件是：宽视图下不再稳定出现“长平台地表 + 一眼可见的单波形洞穴主干”这组坏相。
- 第二阶段的退出条件是：出生区外的代表性地表巡游里，玩家能周期性遇到清晰可辨的自然入口，而且入口形态不止一种重复模板。
- 第三阶段的退出条件是：浅层到中层地下在形态、背景或材质家族组合上已经能被玩家稳定区分，而不是只剩“浅色基底 + 少量矿点”的弱差异。
- 第四阶段的退出条件是：代表性视图中不再稳定出现固定间距重复图块、重复节拍入口、条带状连接笔画或一列式硬切边界等周期性伪影。
- 第五阶段的退出条件是：代表性移动路径中 richer worldgen 不会稳定制造新的重复加载卡顿，同时 determinism、chunk seam 和 delta persistence 不回退。

## Screenshot-Driven Gap Analysis
- 地表轮廓：当前图更接近长平台加局部切口；Terraria 参考图在同屏中常同时出现缓坡、坎台、洼地与水域边界，轮廓节奏层次更明显。
- 入口引导：当前入口多为少数模板化切口，且可见性和分布节拍偏机械；Terraria 入口往往与地貌局部形态联动，玩家在横向移动中更容易被自然引导下探。
- 地下空间体量：当前地下大面积接近统一块体，空腔更像笔画 carve；Terraria 的空腔具有更明显的“体积感”，存在更自然的天花、侧壁、台阶与连通变化。
- 区域过渡：当前地下常见近乎垂直切边；Terraria 中常见“宏观分区明确但局部轮廓渐变”的过渡方式，硬切可感知度更低。
- 周期伪影：当前回传可见固定间隔重复的结构痕迹；Terraria 虽然 deterministic，但重复节拍更难被玩家直接读出。

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
- proposal 必须与当前 infinite chunk loading 现实兼容；即便首版仍保留主线程最终落地，也要把 traversal-critical generation、可延后装饰、元数据缓存和分帧预算明确分层。
- 本 proposal 不要求先完成完整线程化重写，但会要求把“区块生成不会因新地貌逻辑而放大加载卡顿”纳入验收标准。
- proposal 必须覆盖关键热路径上的所有底层算法类型，而不仅是 chunk queue 调度本身；任何新 worldgen 规则都需要先回答“它落在哪个成本层、是否可缓存、是否在每格循环中重复执行”。
- proposal 必须显式覆盖周期伪影控制：任何入口/连接/层带算法都要避免固定间距直接映射到可见重复图块，并提供 deterministic 的非周期扰动策略。
- proposal 必须显式覆盖硬切边界控制：地表与地下区域切换需要有可配置过渡宽度，避免单列或极窄带状突变。
- 本 proposal 不锁死具体噪声算法或是否使用 spline/domain warp，但会锁定玩家可感知结果与验证标准。

## Current Baseline
- 地表高度当前主要由 get_surface_height_at() 中的 continental noise 与 biome amplitude 决定，出生区外的整体轮廓变化仍然有限。
- 地下洞穴分类已存在 Tunnel、Chamber、OpenCavern、Pocket、Connector、Solid 等 region tag，但可达性骨架仍依赖 _get_cave_lane_y() 生成的一条正弦式主通道与周期性竖向连接器。
- 地表 feature tag 目前只有少量小体量装饰，如 StoneOutcrop、DesertSpire、FrostSpire、MudMound、GrassKnoll，无法承担山地或谷地级别的 relief 身份。
- 当前没有显式的入口 family 规划，也没有地表 cues 与地下大型区域一一对应的稳定关系，导致“看见某种地貌就知道下面大概有什么”的探索阅读性较弱。
- 当前也缺少能够串联较大地下区域的长程通行骨架，玩家更容易感知到局部洞而不是成体系的地下路线。
- 当前 terrain 材质消费方对 atlas 坐标耦合较重，尤其是 world_generator 与 digging_manager 中的材质、掉落和硬度判断仍绑定少量现有瓦片；这意味着“多加很多新瓦片”不是纯美术问题，也会放大实现与回归成本。
- 当前区块请求在 InfiniteChunkManager 的主线程流程里逐个出队并直接执行 generate_chunk_cells、结构叠加和树木生成；新地貌逻辑如果继续把更多工作塞进单次构建路径，会直接增加移动时的加载抖动风险。
- 当前 generate_chunk_cells 已经承担 surface_base 计算、洞穴 carve、biome/material 判定、矿物替换与背景墙生成；结构叠加与树木生成又在 chunk manager 的后续路径里继续串行执行，这些都是需要被分别优化的底层算法层，而不是一个单一“worldgen”黑盒。
- 当前代表性截图还显示：地表天际线缺少连续的平原-丘陵-山体-谷地节奏，地下主材质与背景对比不足，洞穴经常读起来像重复的带状走廊加交叉笔画，而不是一组形态不同的腔室、裂隙和连接路径。
- 当前 biome 或 region 的空间阅读也偏弱，至少在当前回传视图里还能看到接近硬切的区域切换，缺少 Terraria 常见的“宏观分区明确、局部轮廓仍然自然塑形”的效果。
- 当前还出现了周期性伪影风险：入口和连接结构在固定间距附近重复出现，且若干视图里存在接近条带化或重复节拍的错误图块分布。
- expand-exploration-terrain-and-hostiles 已经要求“地下有 distinct traversal archetypes”和“地表更丰富”，但尚未把 relief 轮廓质量、地下层带过渡和自然洞口密度具体化。

## Impact
- Affected specs: exploration-terrain-richness, exploration-underground-generation, world-generation-streaming-performance
- Affected code: src/systems/world/world_generator.gd, src/systems/world/infinite_chunk_manager.gd, src/systems/world/world_topology.gd, src/systems/npc/npc_spawner.gd, and any profiling/debug tooling that validates chunk-generation cost, cave reachability, or terrain readability
- Affected data: world-plan surface region metadata, cave region metadata, surface feature placement rules, underground biome/strata selection rules, terrain material family mappings, and any limited accent-tile or transition-tile definitions introduced to support readability
- Relationship to existing changes: 这是 expand-exploration-terrain-and-hostiles 的后续深化，专门把玩家已经感知到的 terrain/cave 生成缺陷收紧为可验证要求；它同时建立在 shift-worldgen-to-planetary-wraparound 已提供的 world-plan 和环绕拓扑基础之上