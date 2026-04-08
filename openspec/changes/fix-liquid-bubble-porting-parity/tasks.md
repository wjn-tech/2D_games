## 1. Runtime Logic Completion
- [x] 1.1 在 `LiquidManager` 主路径中固化空泡收敛责任，禁止依赖失活后置补丁实现正确性。
- [x] 1.2 删除或停用所有“向上方插液/向上候选补洞”相关路径，确保运行时仅由重力与受限侧向驱动。
- [x] 1.3 明确同格液体沉底合同（单元占据与渲染表达一致），补齐必要断言。

## 2. Invalid Patch Cleanup
- [x] 2.1 清理未在 `_process` 中生效且无验收价值的补丁函数与常量。
- [x] 2.2 清理与无效补丁绑定的测试入口，避免测试继续约束失活逻辑。
- [x] 2.3 保留必要兼容垫片时，补充注释说明其非行为路径属性和移除计划。

## 3. Regression Coverage
- [x] 3.1 新增/改造回归：封闭与半封闭空泡在主路径内可收敛。
- [x] 3.2 新增/改造回归：不存在向上方新增液体的行为路径。
- [x] 3.3 新增/改造回归：同一格液体在可视化中始终贴底，不出现悬浮层错觉。

## 4. Docs and Verification
- [x] 4.1 更新 `docs/worldgen_staged_pipeline.md`，记录“去上插液 + 主路径空泡收敛”实现关系。
- [x] 4.2 执行 `openspec validate fix-liquid-bubble-porting-parity --strict` 并修复全部问题。
