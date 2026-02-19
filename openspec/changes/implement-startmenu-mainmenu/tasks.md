任务列表 (实现阶段 — `implement-startmenu-mainmenu`)

1. 收集与映射（审查 & 准备资源） — not-started
   - 从 `startmenu` web 代码提取颜色、渐变与动效时间线。
   - 列出需要的外部资源（字体、SVG 图标、纹理），并优先选择开源替代品。
   - 验证 `res://assets/fonts/ui_font.ttf` 是否可用；如不可用，准备替代字体来源链接。

2. 主题与样式（theme） — not-started
   - 在 `res://ui/theme/theme_startmenu.tres` 中添加颜色常量、按钮样式与 Label 字体样式。
   - 添加必要的 StyleBoxFlat/StyleBoxTexture 资源样式。

3. 主界面布局（MainMenu） — not-started
   - 在 `res://scenes/ui/main_menu.gd` 中实现魔法圆、渐变背景层、深度粒子与浮动符文节点。
   - 用 `ColorRect` + 自定义 Shader 或粒子实现昼夜与时间驱动渐变变化。

4. 控件与交互（components） — not-started
   - 创建/完善 `res://ui/controls/magic_button.tscn` 与 `magic_button.gd`，实现 hover/press/tap 效果与微粒子。
   - 确保按钮兼容 Keyboard/Controller 与鼠标输入。

5. 资源导入与授权说明 — not-started
   - 将开源 SVG/PNG/字体导入 `res://assets/ui/startmenu/`，并在 `design.md` 中记录来源与许可。

6. 视觉回归与验证 — not-started
   - 在实现后截取对比截图，确保与参考示例在配色、动画与层次上保持一致。
   - 在低性能配置下验证帧率并提供降级参数（粒子开关、分辨率缩放）。

验收条件在 `proposal.md` 中已列出。每项完成后提交小补丁并运行场景进行视觉检查。
