## Context
当前 `LiquidManager` 运行时路径以 `_simulate_active_cell` 为核心，但历史上为压制空泡问题引入过多个后置补丁函数。随着 `_process` 回滚禁用这些 pass，代码出现“行为来源与实现位置脱节”的维护问题：
- 运行时行为由主路径决定；
- 许多补丁函数仍存在并被测试直接调用，形成虚假的行为合同。

## Goals / Non-Goals
- Goals:
  - 在不做大规模重构的前提下，完成空泡修复逻辑的主路径化（移植性补全）。
  - 明确并执行“禁止上插液”规则。
  - 明确并执行“同格液体沉底”规则。
  - 清理无效补丁与无效约束，降低后续维护复杂度。
- Non-Goals:
  - 不改造跨 chunk 边界协议与持久化模型。
  - 不引入新调度器架构或新数据模型。
  - 不重做液体渲染系统，只做合同对齐。

## Decisions
- Decision: 将空泡收敛责任限定在主模拟路径。
  - Rationale: 减少“主逻辑 + 离线补丁”双轨行为，避免回归路径分裂。
- Decision: 禁止向上方插液（包括补丁式候选写入）。
  - Rationale: 上插液会引入反直觉质量迁移，容易制造“反重力”观感和不可解释案例。
- Decision: 以可验证合同定义“同格沉底”。
  - Rationale: 沉底是玩家可见行为，不应只依赖隐式渲染细节。
- Decision: 删除或隔离失活补丁函数与测试。
  - Rationale: 清理死路径可降低认知负担，并避免未来误恢复。

## Risks / Trade-offs
- Risk: 去除补丁后，少量历史场景短期内可能出现收敛变慢。
  - Mitigation: 通过主路径参数与回归场景定向调节，不回退到上插液策略。
- Risk: 测试重写期间可能短暂降低覆盖率。
  - Mitigation: 先迁移核心验收场景（空泡、上插液禁用、沉底一致性），再移除旧断言。

## Migration Plan
1. 先加主路径行为断言与新回归，再删除上插液相关代码分支。
2. 移除或隔离失活补丁函数、常量和对应测试入口。
3. 更新文档并回跑液体核心回归，确认无行为回退。

## Implementation Notes (2026-03-30)
- `src/systems/world/liquid_manager.gd`
  - 移除失活后置补丁函数：`_fast_local_relax_pass`、`_local_pressure_equalization_pass`、`_static_hole_fill_pass`、`_collapse_supported_bubbles_pass`、`_probe_vertical_seam_endpoint`。
  - 移除与上述函数绑定的常量组（pressure/hole/bubble/seam/fast-relax）。
  - 新增 `LiquidOverlay._bottom_anchored_fill_metrics()` 与 `debug_bottom_anchor_metrics()`，并在 `_draw()` 中加入底部锚定断言，确保同格沉底合同。
- `tests/test_worldgen_bedrock_and_liquid.gd`
  - 删除直接调用失活补丁函数的旧测试。
  - 新增主路径回归：`_test_liquid_core_path_bubble_convergence`、`_test_liquid_no_upward_insertion_path`、`_test_liquid_bottom_anchor_contract`。
- `docs/worldgen_staged_pipeline.md`
  - 补充“去上插液 + 主路径空泡收敛 + 沉底渲染合同”与实现位置的映射记录。

## Open Questions
- 是否保留部分补丁函数作为仅测试辅助工具（默认不参与 runtime）？
- “同格沉底”是否需要提供独立调试可视化开关用于 CI 截图比对？
