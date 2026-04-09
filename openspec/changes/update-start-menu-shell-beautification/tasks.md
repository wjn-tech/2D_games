## 1. Discovery and Baseline
- [x] 1.1 盘点 `MainMenu.tscn` 与 `main_menu.gd` 的视觉职责边界。
- [x] 1.2 盘点 `assets/ui/start_menu_shell/` 可复用内容与缺口。

## 2. Visual Contract Definition
- [x] 2.1 定义开始菜单壳层结构合同（Header/Body/Footer）。
- [x] 2.2 定义主次按钮层级与状态反馈合同（hover/focus/pressed/disabled）。
- [x] 2.3 定义与加载浮层的视觉语义一致性规则。

## 3. Token Contract Definition
- [x] 3.1 定义主菜单最小 token 集（颜色、尺寸、动效）。
- [x] 3.2 定义 token 映射表（token -> 节点属性）。
- [x] 3.3 定义 token 缺失/非法时的降级规则。

## 4. Integration Plan
- [x] 4.1 规划场景侧样式注入点（优先 `MainMenu.tscn`）。
- [x] 4.2 规划脚本侧状态反馈注入点（`main_menu.gd` 轻动效与文案）。
- [x] 4.3 规划与 `MenuEffects.tscn` 的性能上限与开关策略。

## 5. Validation Plan
- [ ] 5.1 验证开始菜单基础流程：开始/加载/设置/退出均可触发。
- [ ] 5.2 验证键盘导航与焦点可见性。
- [ ] 5.3 验证 token 缺失路径：自动回退且不中断。
- [ ] 5.4 验证视觉一致性：与加载浮层壳层语言一致。

## 6. Documentation
- [x] 6.1 在 change 文档中记录壳层结构与 token 约束。
- [x] 6.2 补充维护说明：后续主菜单视觉资源统一放在 `assets/ui/start_menu_shell/`。

## Parallelization Notes
- 2.x 与 3.x 可并行推进。
- 4.x 依赖 2.x/3.x 定稿。
- 6.x 在 5.x 验证后收敛。