## 1. Discovery and Baseline
- [x] 1.1 盘点当前加载浮层结构（标题/阶段/状态/进度/失败态）与调用链。
- [x] 1.2 确认 `assets/ui/start_menu_shell/` 与 `assets/ui/startmenu/icons/` 可复用资源边界。

## 2. Visual Contract Definition
- [x] 2.1 定义开始游戏加载进度条视觉规范（配色、边框、圆角、文本层级）。
- [x] 2.2 定义失败态视觉规范（高对比提示与回退文案一致性）。
- [x] 2.3 定义资源缺失时的降级渲染规则。

## 3. UI Integration Plan
- [x] 3.1 规划 `UIManager` 加载浮层样式注入点（不改动加载语义）。
- [x] 3.2 规划阶段文案与状态文案的排版与更新节奏。
- [x] 3.3 规划进度条平滑动效参数并设置性能上限。

## 4. Validation Plan
- [x] 4.1 验证开始新游戏路径：进度条可视、文案更新、结束自动隐藏。
- [x] 4.2 验证读档路径：样式一致且不影响场景切换流程。
- [x] 4.3 验证失败路径：错误态可见并保留返回主菜单提示。
- [x] 4.4 验证缺失资源路径：自动降级且无运行时错误。

## 5. Documentation
- [x] 5.1 在 change 文档中记录视觉规范与降级规则。
- [x] 5.2 补充维护说明：后续新增壳层资源应放置于 `assets/ui/start_menu_shell/`。

## Parallelization Notes
- 2.x 可与 3.x 并行，4.x 依赖 2.x/3.x 定稿。
- 5.x 在 4.x 验证后收敛。
