# Change: Beautify Start Game Loading Progress Bar

## Why
当前“开始游戏/读取存档”阶段的加载浮层由 `src/ui/ui_manager.gd` 运行时动态创建，功能完整但视觉层次较弱：
- 进度条样式偏基础，缺少品牌化与氛围表达。
- 阶段信息、状态文本、失败反馈虽存在，但可读性与视觉引导仍有提升空间。
- `assets/ui/start_menu_shell/` 已作为开始菜单壳层资源目录存在，尚未形成可复用的加载美术约束。

本提案聚焦“开始游戏加载进度条美化”，在不改动加载语义与状态机的前提下，提升视觉质感、信息可读性与反馈一致性。

## What Changes
- 新增 `start-game-loading-progress-ui` 能力增量：
  - 为开始游戏加载浮层定义统一视觉规范（背景层、面板层、进度条层、状态层）。
  - 进度条升级为主题化样式（颜色梯度、边框、动效节奏、百分比布局）。
  - 阶段文案与状态文案分层显示，强化“正在做什么/当前做到哪一步”的可读性。
  - 失败态（`show_loading_failure`）改为高对比可感知反馈并保持回退提示一致。
- 引入目录约束：
  - 参考并绑定 `assets/ui/start_menu_shell/` 作为加载壳层视觉资源目录。
  - 若目录资源缺失，系统必须自动回退到 Godot 原生主题样式，不阻塞加载流程。
- 保持逻辑不变：
  - 不修改 `GameManager` 启动阶段权重与进度计算语义。
  - 不改写场景切换、预加载、输入禁用/恢复等现有流程。

## Scope
- In scope:
  - `show_loading_overlay / update_loading_overlay / show_loading_failure` 的视觉表现升级。
  - 开始游戏与读档入口下的加载进度条 UI 美化。
  - 资源目录存在/缺失两种情况下的渲染一致性与降级规则。
- Out of scope:
  - 世界预加载算法、阶段权重、性能调度策略重写。
  - 主菜单按钮布局重构。
  - 背包/HUD 等其他进度条控件的全量换肤。

## Impact
- Affected specs:
  - `start-game-loading-progress-ui` (new)
- Related changes:
  - `redesign-start-menu`
  - `integrate-html-ui-beautification-bridge`
- Affected code (apply stage):
  - `src/ui/ui_manager.gd`
  - `src/core/game_manager.gd`（仅当阶段文案映射需补充）
  - `assets/ui/start_menu_shell/`（加载壳层视觉资源）
  - `assets/ui/startmenu/icons/`（可复用图标资源）

## Defaults for Ambiguous Inputs
1. 进度显示默认保持单调不回退（monotonic），避免视觉抖动。
2. 百分比默认显示整数值，保留现有 0-100 范围。
3. 动效默认轻量（低时长 tween），不得阻塞主线程。
4. 当 `assets/ui/start_menu_shell/` 无可用资源时，默认回退当前 Godot 原生构建样式。
5. 失败态默认保留“正在返回主菜单...”语义，并增加高对比颜色提示。

## Open Questions
- 当前无阻塞性未决问题，可进入评审。
