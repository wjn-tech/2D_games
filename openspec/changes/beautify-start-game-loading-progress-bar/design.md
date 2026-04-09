# Design: Start Game Loading Progress Bar Beautification

## Context
- 现有加载浮层由 `UIManager._ensure_loading_overlay()` 运行时构建，包含标题、阶段、状态、`ProgressBar` 与错误文案。
- `GameManager._report_startup_progress()` 已提供阶段化进度与状态文本，是现成的数据输入通道。
- `assets/ui/start_menu_shell/` 已存在但当前无落地资源，适合作为加载壳层视觉资源目录。

## Goals / Non-Goals
- Goals:
  - 在不改变加载逻辑的前提下提升进度条视觉质量与信息可读性。
  - 统一开始游戏与读档流程的加载反馈风格。
  - 建立“资源存在即增强、资源缺失可降级”的稳健策略。
- Non-Goals:
  - 不修改预加载调度与阶段权重。
  - 不引入重型渲染依赖。
  - 不在本提案中重做主菜单整体布局。

## Decisions
- Decision 1: 逻辑与样式解耦
  - 进度数值、阶段文案仍由 `GameManager` 提供。
  - 视觉样式集中在 `UIManager` 的加载浮层构建与主题覆盖。

- Decision 2: 目录约束 + 回退优先
  - 优先读取 `assets/ui/start_menu_shell/` 中的壳层资源（色板、背景、装饰）。
  - 资源缺失时自动使用原生 `StyleBoxFlat` 与默认控件，保证流程不中断。

- Decision 3: 轻动效策略
  - 继续使用短时 tween 平滑进度条更新。
  - 动效仅用于可读性增强，不添加高开销粒子/复杂着色链作为硬依赖。

## Architecture
1. Data Flow
- `GameManager._report_startup_progress()` 负责发送进度、阶段、状态。
- `UIManager.show_loading_overlay()` 与 `update_loading_overlay()` 负责展示层渲染。

2. Visual Layers
- 背景遮罩层：保持输入阻断与聚焦。
- 面板容器层：主题化边框、圆角、内边距。
- 进度条层：填充样式、百分比文本、阶段辅助信息。
- 错误提示层：高对比失败态文本与回退提示。

3. Fallback Contract
- 若 `assets/ui/start_menu_shell/` 中资源不可用：
  - UI MUST 使用内建样式继续渲染。
  - 进度更新和状态文案 MUST 正常显示。

## Risks / Trade-offs
- 风险：样式资源缺失导致视觉不一致。
  - 缓解：严格降级合同与默认样式兜底。
- 风险：动效过多影响加载体感。
  - 缓解：限制 tween 时长与并行动画数量。
- 风险：失败态信息被视觉弱化。
  - 缓解：错误态采用高对比配色并保留明确回退文案。

## Validation Strategy
- 功能验证：开始游戏、读档、失败回退三条路径均可见加载进度与状态。
- 可读性验证：阶段文案、状态文案、百分比在 1080p 与较低分辨率下可辨识。
- 稳定性验证：资源缺失时自动降级，不出现空引用或加载中断。
- 一致性验证：进度显示单调不回退，结束后正确隐藏浮层。

## Implementation Details (Apply)
- `src/ui/ui_manager.gd` 已将加载面板升级为“终端窗体”结构：
  - 顶部 `HeaderBar`：窗口控制点 + `LOADING` 标题。
  - 中部 `Content`：主标题、英文副标题、阶段文案、状态文案、细条进度条。
  - 分段进度区 `SegmentFrame/SegmentRow`：按 `segment_count` 生成固定格数并随进度点亮。
  - 百分比徽标 `PercentBadge/PercentLabel`：独立显示进度数字。
  - 底部 `FooterBar`：`READY` 与 `ESC: CANCEL` 状态提示。
- `update_loading_overlay()` 继续保持单调进度（`max(current, target)`），并行执行：
  - `ProgressBar.value` tween；
  - `_sync_loading_progress_visuals()` tween（同步百分比文本 + 分段点亮）。
- 失败态 `show_loading_failure()` 已覆盖：
  - 阶段/状态/错误提示统一切换高对比错误色；
  - 百分比徽标切换为 `ERR`。
- `assets/ui/start_menu_shell/loading_theme.json` 已扩展 token：
  - 新增 `header_*`、`chrome_accent`、`segment_*`、`percent_box_*`、`footer_*`。
  - 新增 `panel_width/panel_height/segment_count` 控制结构尺度与分段数。
