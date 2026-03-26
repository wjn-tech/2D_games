# Change: Update Worldgen to Terraria-Core Sequencing, Bedrock Floor, Tile Set Expansion, and Liquid Integration

## Why
已加载区域基本流畅，而进入未加载新区块仍会出现卡顿，说明核心问题在新块生成链路。现有 worldgen 虽有 `critical/enrichment`，但还缺少“阶段职责更明确、冲突覆盖规则更一致、深度边界可终止”的完整生成框架。

同时，当前项目的纯色瓦片资源量不足以支撑更高多样性的世界地貌，液体系统也尚未正式接入主项目。用户要求在保持项目风格前提下：
- 生成逻辑核心尽量贴近泰拉瑞亚（以阶段顺序和覆盖关系为主）；
- 增加同风格纯色瓦片集以承载多样化地形；
- 引入液体系统并参考提供的 Godot 液体工程实现思路；
- 在地底加入基岩封底，避免无限向下加载。

## Confirmed Decisions (Locked)
以下为用户已确认决策，提案按此执行：
- `1.B`：封底深度按 `WorldTopology` 的 world-size preset 配置化。
- `2.B`：采用“封底过渡带 + 硬下界”两段式。
- `3.A`：硬下界以下 chunk 请求直接拒绝（不进入正常加载队列）。
- `4.A`：允许岩浆湖停留在封底上方；封底区内不继续向下扩散。
- `5.A`：深度边界规则仅对新世界强制启用；旧存档默认不迁移此行为。
- `6.B`：作为上位约束整合已有 cave/entrance 提案能力。
- `7.A`：阶段冲突采用“后阶段默认覆盖前阶段 + 显式避让白名单”。

## What Changes
- 引入 Terraria-core 风格的阶段生成序列（按核心逻辑分组映射，不做无意义逐函数照抄）。
- 明确阶段覆盖优先级、阶段白名单避让、以及 `critical/enrichment` 的职责归属。
- 增加基岩封底系统：过渡带 + 硬下界 + 下界请求拒绝策略。
- 新增同风格纯色瓦片集扩展能力，满足多样化地貌与微生态表现需求。
- 新增液体系统接入能力（参考 `d:\godot\fluid-water-physics-2d-simulator-for-godot-4+` 的算法/架构思路，采用项目兼容实现）。

## Impact
- Affected specs:
  - `worldgen-terraria-core-sequencing`
  - `worldgen-staged-pipeline`
  - `world-depth-boundary-control`
  - `world-tileset-style-expansion`
  - `world-liquid-system-integration`
- Affected code (expected):
  - `src/systems/world/world_generator.gd`
  - `src/systems/world/world_topology.gd`
  - `src/systems/world/infinite_chunk_manager.gd`
  - `src/systems/world/*liquid*.gd`（new）
  - 资源目录 `assets/` 与 `res/assets/` 下相关瓦片资源
- Related existing changes:
  - `enhance-natural-cave-entrances-and-deep-caverns`（被本提案上位约束整合）
  - `diagnose-world-streaming-stutter-root-causes`
  - `shift-worldgen-to-planetary-wraparound`

## Non-Goals
- 不追求泰拉瑞亚 107 步在数据结构和实现细节上的逐行复刻。
- 不在本提案中扩展新战斗系统、NPC系统或 UI 视觉系统。
- 不要求一次性替换全部历史地图数据。

## Resolved Clarifications
1. 验收边界采用双指标：
  - `核心阶段覆盖率` + `步骤条目覆盖率` 同时作为验收指标。
2. 液体首期范围确认：
  - 首期实现水与岩浆。
  - 同时预留蜂蜜/特殊液体扩展接口。
3. 纯色瓦片集交付策略确认：
  - 先交付最小可用集（地表/地下/深层/封底/液体接触边）。
  - 后续按阶段分批扩容到微型群落与装饰需求。
