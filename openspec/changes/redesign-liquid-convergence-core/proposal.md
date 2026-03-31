# Change: Redesign Liquid Core Convergence

## Why
当前液体运行时仍会反复出现中空泡与反重力观感，说明主求解逻辑对部分状态不具备天然收敛性。现状依赖阈值调参与阶段性补丁函数才能缓解表现问题，但这些手段无法从机制上保证“有通路就会持续下泄、局部压差会自然衰减、跨区块不会悬挂”。

如果继续在现有规则上叠加补丁，会持续提高维护成本，并放大阈值耦合带来的回归风险。需要一次面向收敛性的核心重设计，将“无空泡、无悬滴”作为主逻辑结果，而不是后处理结果。

## What Changes
- 建立以收敛不变量为中心的液体核心规则合同：
  - 下行可达单调性（有可达下行路径时，液体势能持续下降）
  - 质量守恒（含跨区块、卸载、飞行中转移）
  - 有界均压（局部压差随 tick 衰减，避免永久空泡）
  - 调度公平性（高负载下无永久饥饿）
- 将“空泡修复”从必需路径降级为可选保险丝；核心正确性不依赖修复 pass。
- 明确跨区块边界的连续流动语义，避免“下方区块未就绪导致悬挂”。
- 定义渲染阈值与物理阈值的一致性合同，减少视觉浮空错觉。
- 增加验证基线：收敛性、守恒性、调度公平、边界连续性和可视一致性的自动化场景。

## Impact
- Affected specs:
  - liquid-core-convergence
- Affected code (planned):
  - src/systems/world/liquid_manager.gd
  - src/systems/world/infinite_chunk_manager.gd
  - src/systems/world/world_chunk.gd
  - tests/test_worldgen_bedrock_and_liquid.gd
  - docs/worldgen_staged_pipeline.md
- User-visible impact:
  - 地形开孔后液体应自然持续下泄，不再长期出现悬空滴。
  - 大水体内部不再长期保留可见空泡。
  - 高负载场景中液体更新更稳定，减少“局部冻结后突然跳变”。
