## Design: UI Beautify Theme (concise)

### Context
目标是在不大幅改动现有代码逻辑的前提下，提升游戏内工具与面板的视觉质量，使编辑器与主要交互界面更现代、易用。优先采用 Godot 原生 `Theme`、`StyleBoxFlat`、`DynamicFont` 与 `Tween`。

### Goals
- 视觉一致性：提供一套可复用的全局颜色与控件样式。
- 低风险改造：不改业务逻辑，仅变更控件样式/资源。
- 可扩展：后续可把颜色变量暴露到设置面板。

### Decisions
- 使用 `StyleBoxFlat` 作为主面板样式（圆角、边框、阴影模拟）。
- 导入单个高质量字体（如开源 Inter / Noto）作为默认 DynamicFont。
- 优先只在 `WandEditor` 应用并验证效果，再逐步扩大到其它 UI。

### Alternatives Considered
- 使用 NinePatch 图像：更精美但需要美术资源/切图，成本更高。
- 嵌入 HTML UI：视觉能力强但需外部插件与复杂集成，风险高。

### Risks & Mitigations
- 字体授权问题 → 仅使用明确开源许可字体或项目自带像素字体。
- 布局回归（控件错位） → 按模块逐步替换 theme，并在每步添加回归截图验证。

### Migration
- 先在 `WandEditor` 根节点设置 `theme`，若确认通过，则把 theme 引用放到项目主 UI 根节点（如 `Main` 或 `UIRoot`）。

### Open Questions
- 是否有品牌/美术规范（主色/徽标）需要遵守？
- 是否允许添加外部字体资源到仓库？
