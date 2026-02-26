# Change: Beautify Godot Wand Editor UI

## Why
当前 Godot 项目中的魔杖编辑器（`wand_editor.tscn`）使用了基础的 `TabContainer` 布局，导致“外观设计”和“逻辑编程”完全隔离，且“构造详情”（魔杖属性）只能在外观设计页面看到。为了提升用户体验，参考 Next.js 版本的 `wand_editor` 示例，我们需要一个更现代、更直观的布局：左侧边栏切换编辑模式并显示对应的组件库，中间为编辑区，右侧边栏始终显示魔杖的实时属性。

## What Changes
- **重构 `wand_editor.tscn` 布局**：
  - 移除顶层的 `TabContainer`。
  - 采用三列式布局（使用 `HSplitContainer` 嵌套，允许玩家拖拽调整侧边栏宽度）：
    - **左侧边栏**：包含模式切换按钮（使用 `ButtonGroup` 实现分段控制器效果）和对应的组件库（`ModulePalette` 或 `PaletteGrid`）。
    - **中间工作区**：根据当前模式动态显示 `VisualGrid` 或 `LogicBoard`。
    - **右侧边栏**：始终显示 `StatsPanel`（构造详情/魔杖属性）。
- **重构属性面板 (StatsPanel)**：
  - 将原本的 `RichTextLabel` 替换为结构化的 UI 节点组合（图标 + 标签 + 数值），以达到 Next.js 版本的精美效果。
  - 轻微修改 `wand_editor.gd` 中的 `_update_stats_display` 逻辑，以填充这些结构化节点。
- **更新 `wand_editor.gd` 引用**：
  - 更新 `@onready` 节点路径以匹配新布局。
  - 添加模式切换逻辑（隐藏/显示对应的库和工作区）。
- **美化视觉风格**：
  - 保留现有的科技风（Sci-Fi Blue，使用 `COLOR_BG_MAIN`、`COLOR_ACCENT` 等常量）。
  - 调整背景颜色、边框、间距，使其更符合现代 UI 设计。
- **保留核心逻辑**：
  - 绝对不修改魔杖的编译、保存、测试运行（`SimulationBox`）等核心业务逻辑。

## Impact
- Affected specs: `wand-editor-ui`
- Affected code: 
  - `res://src/ui/wand_editor/wand_editor.tscn`
  - `res://src/ui/wand_editor/wand_editor.gd`
