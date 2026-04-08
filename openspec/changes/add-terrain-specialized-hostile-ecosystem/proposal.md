# Change: Add Terrain-Specialized Hostile Ecosystem

## Why
当前游戏已具备严格地形匹配刷怪框架（map_biome/depth_band/cave_region/underworld_region），但怪物池规模和生态位仍偏小，无法支撑“31类地形的探索差异化体验”。

用户已提供一套高质量的15种专属怪物概念，需要将其转化为可验证、可分阶段交付、可平衡的正式需求与实施计划。

## What Changes
- 新增“地形专属敌对生态”能力：将31类地形（地表、地下、洞穴、地下世界子区域）映射到专属怪物家族与刷新权重。
- 引入15种怪物家族的标准化生成定义，区分“泛用基础种”与“环境特化种”。
- 扩展生成表规范，支持跨地形优先级、稀有全域怪（拟态集群）与热点倍率规则。
- 为15种家族定义签名战斗模组（攻击、状态、交互、反制窗口），保证“同地形不同对策”。
- 增加验证要求：地形覆盖率、刷新公平性、性能预算、种子一致性。

## Scope and Sequencing
- 阶段A（数据与规则）：完成地形-怪物映射、权重策略、校验器。
- 阶段B（内容与行为）：按优先级实现怪物家族与签名攻击。
- 阶段C（平衡与验收）：完成分层难度和压力测试。

## Confirmed Decisions
1. 地形口径：采用已确认的31地形清单作为本变更权威地形分类。
2. 上线方式：分批交付（阶段化实现，不做一次性全量落地）。
3. 资源策略：占位资源先行，功能完整优先。
4. 稀有全域怪（拟态集群）概率：基础有效刷新概率 0.12%，在口袋洞、连通道、实心岩层倍率 x2。
5. 非范围项：理智、口渴、装备耐久腐蚀、QTE 挣脱不纳入本次变更。
6. 高风险机制：默认开启（允许后续通过平衡参数微调强度，不作为默认关闭项）。
7. 地下世界区域：route、floor、cliff、island、cavity、hard_floor 均允许刷怪。
8. 覆盖约束：每个地形至少2个候选敌对家族。

## Impact
- Affected specs:
  - hostile-terrain-spawning
  - hostile-signature-behaviors
- Affected code:
  - src/systems/npc/npc_spawner.gd
  - data/npcs/hostile_spawn_table.json
  - scenes/npc/*.tscn
  - src/systems/npc/*.gd
  - src/systems/world/world_generator.gd
- Affected docs:
  - docs/hostile_spawn_table.md
