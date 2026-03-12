# Change: Refactor Wand Execution To Recursive Branch Semantics

## Why
当前法杖系统采用 root deck 线性抽牌与 child tier 分支调度混合执行模型。该模型在 modifier 作用域、分支扣蓝、延迟结算、触发器 payload 继承以及并行支路顺序影响结果等方面存在语义不一致，导致复杂法术图难以预测和验证。

## What Changes
- 用递归支路函数替代 root deck 与 child tier 的混合执行语义。
- 将每个分支节点、投射物节点和触发器节点统一建模为接收执行上下文的编译步骤。
- 新增统一的 `load`、`enabled`、`delay_enable`、法力消耗和充能时间结算规则。
- 将所有 root source 合并为同一轮施法的多个入口，并统一汇总为一张发射表。
- 将触发器本体视为投射物，并在触发时释放其预编译 payload，方向继承触发器飞行方向。
- 将嵌套触发器统一建模为递归 continuation，禁止运行时对 payload 做二次编译。
- 将施法前编译结果统一为“投射物发射表”，每轮施法先编译，再按表发射，再进入充能循环。
- **BREAKING**：修改 modifier 的生命周期、分支蓝耗结算点、delay 结算点和 trigger payload 的继承语义。

## Impact
- Affected specs: `execution_engine`
- Affected code: [src/systems/magic/compiler/wand_compiler.gd](src/systems/magic/compiler/wand_compiler.gd), [src/systems/magic/spell_processor.gd](src/systems/magic/spell_processor.gd), [src/systems/magic/projectiles/spell_trigger_base.gd](src/systems/magic/projectiles/spell_trigger_base.gd), [src/systems/magic/wand_data.gd](src/systems/magic/wand_data.gd)
