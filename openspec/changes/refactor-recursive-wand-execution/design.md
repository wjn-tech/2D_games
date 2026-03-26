## Context
当前法杖执行器由两套语义叠加构成：root deck 线性抽牌和 child tier 分支调度。它们对 modifier 作用域、负延迟继承、蓝耗扣除、触发器 payload 和 load 清空时机采用了不同规则，因此复杂法术图的行为依赖实现细节，而不是依赖稳定规范。

## Goals / Non-Goals
- Goals:
  - 用统一的递归解释模型覆盖单路、分支、触发器和 payload。
  - 将 mana、delay、recharge 的结算点与 load 生命周期绑定到明确事件上。
  - 让一次施法先产出完整的发射计划，再按照计划发射与充能。
- Non-Goals:
  - 不在本变更中设计新的 UI 节点类型。
  - 不改变现有法术资源格式以外的编辑器交互。
  - 不在本变更中重做视觉特效系统。

## Decisions
- Decision: 使用递归“支路函数”作为执行模型的核心抽象。
  - 每个节点接收 `ExecutionContext`，并返回零个或多个 `EmissionRecord` 与可选的 `TriggerContinuation`。
- Decision: 区分 inherited load 与 newly written load。
  - inherited load 只是上下文传递，不重复结算 mana、delay、recharge。
  - 当前节点新写入的 modifier 才会触发本支路的资源结算。
- Decision: 将 projectile 和 trigger 都视为 materialization point。
  - 到达 materialization point 时，将当前 load 完整附着到该实体，结算该实体的 mana 与 delay，并清空当前支路 load。
- Decision: trigger payload 不继承 trigger 之后继续累计的 delay。
  - trigger 本体 materialize 后，向 payload continuation 传入 `delay_enable = false`。
- Decision: recharge 以整轮施法为单位结算。
  - 一轮施法的所有 root-cycle emission 按 delay 表发射完成后，法杖立刻进入 recharge。
  - recharge 时间等于 wand base recharge 加上本轮所有已编译启用通路中新写入 load 的 recharge 总和。
  - trigger continuation 的 recharge 在本轮编译时即被承诺，不等待 trigger 条件是否真的在运行时满足。
- Decision: 多个 root source 合并为同一轮施法的多个入口。
  - 每个 root source 以独立的空 `local_load`、`enabled = true`、`delay_enable = true` 开始递归解释。
  - 多个 root source 共享同一个 wand cast cycle、同一张 emission table 和同一次 recharge，但彼此不共享 branch-local 写入。
  - root source 只为稳定编译结果而排序，排序本身不得改变并行语义。
- Decision: 触发器在条件满足时立即失效并同步释放 payload。
  - payload 的位置取 trigger 当前位置，方向取 trigger 当前飞行方向。
- Decision: 嵌套触发器递归复用同一 continuation 模型。
  - 若 trigger payload 中再次遇到 trigger，编译阶段必须直接为该嵌套 trigger 生成 continuation，而不是在运行时重新解释或二次编译 payload 子树。
  - 运行时只负责消费 continuation、绑定当前位置和当前飞行方向，不重新计算图结构、modifier 作用域或资源结算。
  - 该规则保证“先编译、后发射”的语义在任意深度的 trigger 嵌套中保持成立。

## Data Model
- `ExecutionContext`
  - `inherited_load`: 从父支路继承的 modifier 集
  - `local_load`: 当前支路新增的 modifier 集
  - `enabled`: 当前支路是否继续解释
  - `delay_enable`: 当前支路是否继续累加 delay
  - `mana_delta`: 当前支路资源变化
  - `delay_delta`: 当前支路新增 delay
  - `recharge_delta`: 当前支路新增 recharge
- `EmissionRecord`
  - `instruction`
  - `applied_modifiers`
  - `fire_delay`
  - `spawn_position_mode`
  - `spawn_direction_mode`
  - `trigger_continuation`
- `TriggerContinuation`
  - `condition`
  - `compiled_payload`
  - `captured_modifiers`
  - `delay_enable`
  - `nested_continuations`

## Risks / Trade-offs
- 风险：这是执行模型重写，不是局部 bug fix，和现有图的一些表现会不兼容。
  - Mitigation：先通过 spec 固定新语义，再逐步实现并做回归场景验证。
- 风险：负 mana、负 delay、负 recharge 会放大顺序与边界问题。
  - Mitigation：所有负值行为都在 spec 中写明，并加入专门验证场景。
- 风险：触发器 payload 从“再次解释子树”改为“执行预编译 continuation”，会影响少数依赖旧 bug 的法术图。
  - Mitigation：将 trigger runtime 行为作为明确 breaking change 写入 proposal 和 spec。

## Migration Plan
1. 引入新的递归编译产物与执行上下文结构。
2. 在保留旧执行器入口的前提下，将 `cast_spell` 内部切到新 planner。
3. 将 trigger 运行时改为消费 continuation，而不是直接重新遍历旧 child tier。
4. 完成回归验证后，删除旧 root deck / child tier 专用分支语义。

## Open Questions
