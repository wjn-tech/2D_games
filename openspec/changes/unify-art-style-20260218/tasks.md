1. 资产审计（艺术/技术） — 列出 UI、背景贴图、shader、主要角色贴图与面板样式。
   - 验证清单：`assets/ui/*`、`ui/shaders/menu_bg.shader`、`scenes/ui/MainMenu.tscn`、`scenes/player.tscn`。
   - 验证完成后产出 `audit_report.md`。

2. 定义共享色板与调色规则（3 色轴）：主场景蓝（Scene Blue）、UI 主色紫（UI Purple, 可弱化）、强调色（Accent Warm）。
   - 产出 `colorscheme.json` 与 `assets/ui/palette.tres`（Godot 资源）。

3. UI 主题调整（浅色/透明度策略）：修改 `assets/ui/main_theme.tres`，将面板改为半透明或更中性，减少全屏染色。

4. Shader 参数对齐：在 `ui/shaders/menu_bg.shader` 中新增共享 uniform 与 day/night presets，以供在菜单与场景之间使用统一参数集。

5. 轻量美术任务：替换或调整 2-3 个关键纹理（例如 `magic_circle`、按钮角装饰）以匹配统一色板。

6. 集成与回归：在 `MainMenu` 启动流程中撤除临时回退（`HardFallbackSky`）并验证 shader 正常显示，做 3 次视觉回归截图并记录对比。

7. QA 与 微调：美术/设计评审、玩家感受验证（小范围 A/B 测试），根据反馈迭代 1-2 次。

每一项都应包含验收标准（视觉截图、差异阈值、PR 列表）。
