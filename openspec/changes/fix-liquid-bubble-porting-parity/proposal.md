# Change: Fix Liquid Bubble Porting Parity

## Why
当前液体运行时已回退为核心主路径（重力优先 + 侧向扩散 + 冷却调度），但历史补丁函数仍残留在代码与测试中，且包含“向上方候选插液”的逻辑路径。该状态带来三个问题：
- 空泡问题缺少可维护的主路径收敛合同，修复责任分散在失活补丁逻辑中。
- 代码存在无效补丁与无效参数，增加维护和排障成本。
- “同一格液体沉底”只在渲染层隐式表现，缺少明确的运行时与验收约束。

本提案聚焦移植性修复与逻辑补全，不做大幅架构重写。

## What Changes
- 以小范围方式补全液体主路径合同：
  - 空泡收敛依赖主模拟链路，不依赖后置补丁函数。
  - 明确禁止向上方插入液体的运行时路径与补丁路径。
  - 明确同一格液体始终以底部占据方式表达（物理与渲染一致）。
- 清理无效补丁面：
  - 移除或停用未在 `_process` 生效、且与目标行为冲突的历史补丁实现与对应无效测试断言。
  - 清理与失活补丁绑定的常量与调用痕迹，避免继续误导调参。
- 完善回归覆盖：
  - 新增主路径空泡收敛、禁止上插液、同格沉底显示一致性的回归场景。

## External Evidence (Authoritative + Practical)
- Tom Forsyth, Cellular Automata for Physical Modelling:
  - 强调质量守恒、局部规则稳定性、动态更新率与预算约束。
- W-Shadow Simple Fluid Simulation:
  - 给出网格液体示例代码，强调重力优先、局部均衡、双缓冲/中间态避免更新顺序伪影。

## Example Implementations/References
- https://tomforsyth1000.github.io/papers/cellular_automata_for_physical_modelling.html
- https://w-shadow.com/blog/2009/09/01/simple-fluid-simulation/

## Scope Guardrails
- 本变更不引入新的液体架构层、不重写跨系统边界协议。
- 本变更不改变世界生成液体种子策略。
- 本变更仅处理：空泡移植修复、去上插液、同格沉底合同、无效补丁清理。

## Impact
- Affected specs:
  - liquid-authoritative-runtime
- Affected code (planned):
  - src/systems/world/liquid_manager.gd
  - tests/test_worldgen_bedrock_and_liquid.gd
  - docs/worldgen_staged_pipeline.md
- User-visible impact:
  - 大水体内部空泡残留概率下降
  - 浮空水滴/反重力观感进一步收敛
  - 液体行为解释路径更单一，后续维护成本降低
