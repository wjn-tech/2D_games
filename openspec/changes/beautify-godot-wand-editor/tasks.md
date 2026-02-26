## 1. 布局重构准备
- [x] 备份当前的 `wand_editor.tscn` 和 `wand_editor.gd`。
- [x] 在 `wand_editor.tscn` 中创建新的三列基础布局结构（使用两个嵌套的 `HSplitContainer` 包含 LeftSidebar, CenterWorkspace, RightSidebar，允许拖拽调整宽度）。

## 2. 迁移 UI 节点
- [x] 将 `StatsPanel` 移动到 RightSidebar，并确保其始终可见。
- [x] 在 LeftSidebar 顶部添加模式切换按钮（使用 `ButtonGroup` 实现分段控制器效果，包含“外观设计”和“逻辑编程”）。
- [x] 将 `LibraryPanel`（外观模块库）和 `LibraryContainer`（逻辑节点库）移动到 LeftSidebar 的内容区。
- [x] 将 `VisualGrid` 和 `LogicBoard` 移动到 CenterWorkspace。
- [x] 移除旧的 `TabContainer` 及其残留的布局节点。

## 3. 重构属性面板 (StatsPanel)
- [x] 在 `StatsPanel` 中移除旧的 `RichTextLabel`。
- [x] 创建结构化的 UI 节点（如 `VBoxContainer` 包含多个 `HBoxContainer`，每个代表一项属性，包含图标、标签和数值）。
- [x] 修改 `wand_editor.gd` 中的 `_update_stats_display` 方法，使其更新这些结构化节点而不是拼接字符串。

## 4. 更新脚本引用与逻辑
- [x] 更新 `wand_editor.gd` 中的 `@onready` 路径，使其指向新布局中的节点。
- [x] 在 `wand_editor.gd` 中实现模式切换逻辑：点击左侧分段控制器按钮时，切换 LeftSidebar 中显示的库以及 CenterWorkspace 中显示的工作区。
- [x] 确保 `_setup_preview_ui` 和 `_setup_stats_ui` 等动态创建 UI 的代码能正确挂载到新布局的节点上。

## 5. 视觉美化与打磨
- [x] 调整各面板的 `split_offset`，设置合理的初始宽度。
- [x] 为面板添加背景色（`PanelContainer` 或 `ColorRect`），保留现有的科技风（Sci-Fi Blue，使用 `COLOR_BG_MAIN` 等常量）。
- [x] 调整边距（`MarginContainer`）和间距（`theme_override_constants/separation`），提升呼吸感。

## 6. 验证与测试
- [x] 运行游戏，打开魔杖编辑器，验证右侧属性栏是否始终可见。
- [x] 验证拖拽 `HSplitContainer` 是否能正常调整侧边栏宽度。
- [x] 验证点击左侧模式切换按钮是否能正确切换库和工作区，且按钮有选中高亮效果。
- [x] 验证拖拽模块、连线逻辑、保存和测试法术等核心功能是否正常工作。
