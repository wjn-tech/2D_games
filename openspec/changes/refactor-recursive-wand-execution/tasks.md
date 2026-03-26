## 1. Design
- [x] 1.1 定义递归执行上下文的数据结构，包括 `load`、`enabled`、`delay_enable`、累计法力、累计延迟、累计充能和触发 continuation。
- [x] 1.2 定义“投射物发射表”的结构，覆盖普通投射物、触发器本体和触发器 payload。
- [x] 1.3 明确 inherited load 与 newly written load 的区分规则，避免重复计费。
- [x] 1.4 明确 root source 合并规则与稳定排序规则，确保多入口不会共享本地 load。

## 2. Compiler
- [x] 2.1 将图编译为递归分支函数可消费的结构，而不是 root deck + child tier 混合语义。
- [x] 2.2 为分支节点建立稳定的输出顺序，但保证输出顺序不改变并行语义。
- [x] 2.3 为触发器节点编译 continuation/payload 结构，支持运行时条件触发。

## 3. Execution
- [x] 3.1 实现统一的递归解释入口，从源节点开始编译整轮施法的发射表。
- [x] 3.2 在 modifier 写入当前支路 load 时结算该 modifier 的法力、delay 和 recharge。
- [x] 3.3 在投射物或触发器本体 materialize 时结算其法力与 delay，并清空当前支路 load。
- [x] 3.4 在 trigger materialize 后，将 `delay_enable = false` 传给其 payload continuation。
- [x] 3.5 按编译出的发射表发射所有 root-cycle 投射物，并在完成后立刻进入 recharge。
- [x] 3.6 支持 trigger continuation 的递归嵌套，确保 trigger payload 中的 trigger 继续复用预编译 continuation。

## 4. Trigger Runtime
- [x] 4.1 触发器满足条件时立刻失效。
- [x] 4.2 在触发器当前位置立即释放 payload，方向继承触发器当前飞行方向。
- [x] 4.3 payload 使用触发器捕获的编译结果与修饰，不重新解释旧支路。
- [x] 4.4 嵌套 trigger 在运行时只消费其携带的 continuation，不进行运行时二次编译。

## 5. Validation
- [x] 5.1 为单路 modifier -> projectile 编写回归验证。
- [x] 5.2 为多路并行分支共享 inherited load 编写回归验证。
- [x] 5.3 为 trigger 本体与 payload 的 delay/recharge 规则编写回归验证。
- [x] 5.4 为负 delay、负 recharge、负 mana_cost 的边界行为编写回归验证。
- [x] 5.5 为多 root source 同轮施法的合并与 recharge 汇总编写回归验证。
- [x] 5.6 为 trigger payload 中再次遇到 trigger 的递归 continuation 行为编写回归验证。
