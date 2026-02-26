# Design: Wand Editor UI Beautification

## 架构决策

### 1. 布局结构 (Layout Structure)
为了实现“左侧切换模式+库，中间编辑，右侧常驻属性”的目标，我们将放弃 Godot 原生的 `TabContainer`，改用自定义的容器组合（使用 `HSplitContainer` 允许玩家拖拽调整宽度）：
```text
WandEditor (Control)
└── VBoxContainer (Main)
    ├── Header (HBoxContainer: Title, Buttons)
    └── Body (HSplitContainer, split_offset = 250)
        ├── LeftSidebar (VBoxContainer)
        │   ├── ModeSwitcher (HBoxContainer: VisualBtn, LogicBtn, ButtonGroup)
        │   └── LibraryArea (MarginContainer)
        │       ├── VisualLibrary (ScrollContainer)
        │       └── LogicLibrary (ScrollContainer)
        └── RightSplit (HSplitContainer, split_offset = -250)
            ├── CenterWorkspace (MarginContainer)
            │   ├── VisualWorkspace (Control)
            │   └── LogicWorkspace (GraphEdit)
            └── RightSidebar (VBoxContainer)
                └── StatsPanel (VBoxContainer: Structured Nodes)
```

### 2. 状态管理 (State Management)
- **模式切换**：在 `wand_editor.gd` 中维护一个 `current_mode` 变量（枚举或字符串）。当点击左侧的模式切换按钮（分段控制器）时，更新该变量，并根据变量值设置 `VisualLibrary`、`LogicLibrary`、`VisualWorkspace`、`LogicWorkspace` 的 `visible` 属性。
- **属性更新**：由于 `StatsPanel` 现在常驻右侧，无论处于哪种编辑模式，只要魔杖数据发生变化（外观改变或逻辑节点改变），都会触发 `_update_stats_display()`。该方法将被重构，不再拼接字符串，而是更新结构化节点（如 `Label` 的 `text` 属性）。

### 3. 视觉风格 (Visual Style)
- 保留现有的科技风（Sci-Fi Blue），使用 `COLOR_BG_MAIN`（深蓝/青色科技风）、`COLOR_ACCENT` 等常量。
- 使用 `StyleBoxFlat` 为面板添加圆角（`corner_radius`）和微妙的边框（`border_width`，颜色如 `COLOR_ACCENT_DIM`）。
- 模式切换器（分段控制器）使用 `ButtonGroup`，通过自定义 `StyleBox` 实现选中项高亮、未选中项暗淡的效果。
