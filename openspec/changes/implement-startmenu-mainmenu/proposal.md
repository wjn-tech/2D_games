# Change: Implement Start Menu — `implement-startmenu-mainmenu`

目标: 将 web 示例的 startmenu 视觉与交互（参考项目中的 startmenu 页面与示意图）移植到 Godot 项目 `MainMenu` 场景，严格模仿视觉效果并适配本工程美术风格。不可使用 `logo.svg`，如需 SVG 图标应从开源库检索并注明来源。

范围 (高层):
- 提取并映射网页素材的色板、渐变、粒子与排版样式。
- 在 `res://ui/theme/theme_startmenu.tres` 中扩展/补全主题，使用项目字体或引入开源字体到 `res://assets/fonts/`。
- 在 `res://scenes/ui/main_menu.gd` 中实现动画、粒子、魔法圆、浮动符文、时间驱动背景变换、按键样式与交互反馈（hover/press）。
- 替换或增强现有按钮为 `MagicButton` PackedScene，使其支持发光、阴影、粒子和按键动画。

非功能性要求:
- 运行时性能需平滑（60fps 为目标，低端设备降级粒子数）。
- 资源应尽量使用小文件与 AtlasTexture 管理，避免运行时大量磁盘 IO。
- 不修改现有游戏逻辑与路径结构（仅新增/修改 UI 相关文件）。

约束与禁用项:
- 不使用 `logo.svg` 文件；若需要图标，从开源授权（MIT/CC0/Apache）库抓取，并把原始来源列在 `openspec/changes/.../design.md`。

验收标准（高层）:
- 视觉：主画面标题、魔法圆、深邃渐变背景、三行主按钮与微交互效果与示例接近（参考项目截图）。
- 交互：鼠标悬停/按下有明确视觉反馈；背景呈缓慢呼吸/色相移动，并随系统时间产生明显日夜差异。
- 兼容性：在缺失外部资源（字体、svg）时能优雅回退不致崩溃。

下一步: 若同意提案，我将按 `tasks.md` 顺序逐项实现并提交代码补丁。实现阶段会包含小步提交与视觉对比截图。
