# Change: Refactor Liquid System Architecture

## Why
当前液体系统在高活跃场景下仍会反复出现两类核心问题：
- 中空泡长期残留（局部压差无法在主路径内稳定收敛）
- 反重力观感的浮空水滴（垂向受限时出现不符合直觉的侧向漂移）

同时，运行时存在明显的性能与维护风险：
- 主循环与渲染刷新路径开销偏高，重负载下帧时间抖动明显
- 多轮修补后规则耦合变重，继续叠加补丁的回归成本高

该问题已超过参数微调范围，需要执行一次完整架构级重构，建立“正确性优先、性能可预算、表现可解释”的液体系统。

## What Changes
- 引入新的权威液体运行时能力：
  - 以格子质量守恒为核心合同（含跨区块交接、卸载、保存）
  - 以垂向优先和有界均压为核心收敛路径，移除对后置修复 pass 的功能性依赖
  - 以公平调度与多速率预算为核心性能策略，避免局部饥饿与队列抖动
- 引入新的跨区块连续流动合同：
  - 定义边界交接与恢复语义，禁止向不可写边界“丢液”
  - 明确 chunk 生命周期与液体状态的一致性责任
- 引入新的渲染一致性合同：
  - 物理阈值与可视阈值对齐，降低“逻辑连通但视觉断裂”的浮空错觉
  - 渲染仅消费经过预算化的增量脏区，不再做全量复制刷新
- 建立分阶段迁移路径与回滚阀：
  - 先并行验证新旧解算一致性与性能，再切换默认路径
  - 预留开关用于灰度和快速回退

## External Evidence (Authoritative + Practical)
- Tom Forsyth, Cellular Automata for Physical Modelling (Game Programming Gems): 提供可压缩近似、双缓冲、防振荡、动态更新率与稀疏处理的工程原则。
- W-Shadow / J. Gallant CA 液体实现: 提供稳定状态分配、上下左右局部规则和可玩的2D网格液体样例。
- Noita GDC 公开材料: 证明“基于栅格的物理模拟 + 大世界扩展”在游戏中的可行性与收益。

## Example Implementations/References
- https://github.com/jongallant/LiquidSimulator
- https://w-shadow.com/blog/2009/09/01/simple-fluid-simulation/
- https://tomforsyth1000.github.io/papers/cellular_automata_for_physical_modelling.html
- https://www.gdcvault.com/play/1025695/Exploring-the-Tech-and-Design

## Impact
- Affected specs:
  - liquid-authoritative-runtime
- Affected code (planned):
  - src/systems/world/liquid_manager.gd
  - src/systems/world/infinite_chunk_manager.gd
  - src/systems/world/world_chunk.gd
  - tests/test_worldgen_bedrock_and_liquid.gd
  - docs/worldgen_staged_pipeline.md
- User-visible impact:
  - 反重力悬滴显著减少或消失
  - 大水体内部空泡在可预期时间内收敛
  - 大场景液体演化更连续，帧时间更稳定
