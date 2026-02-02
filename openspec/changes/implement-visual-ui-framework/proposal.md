# Change: 实现全可视化游戏交互界面框架 (Visual UI Framework)

## Why
用户明确要求所有游戏功能（背包、建造、交易、合成、属性、社交等）必须通过游戏内的可视化控件（UI）完成，而非控制台或脚本调试。为了确保 14 个核心系统都能以直观、一致的方式呈现给玩家，需要建立一套统一的 UI 框架与交互规范。

## What Changes
- **UI 框架基础**：建立全局 UI 管理器（UIManager），负责窗口层级、焦点管理、输入拦截与通用动效。
- **核心系统可视化**：
    - **背包/仓库**：网格化布局，支持拖拽、拆分、使用与丢弃。
    - **建造/蓝图**：可视化选择轮盘或菜单，显示资源消耗与预览。
    - **合成/炼药**：配方列表展示，一键合成与进度条。
    - **NPC 交互**：对话框、交易窗口、关系/家谱树视图。
    - **战斗/状态**：血条、层级指示器、技能/阵法快捷栏。
    - **工业/电路**：可视化连线与逻辑配置界面。
- **交互规范**：定义“鼠标点击”、“键盘快捷键”与“手柄适配”的统一逻辑。

## Collaboration Model
- **我（脚本/逻辑）**：编写 UI 控制逻辑（如 `inventory_ui.gd`）、数据绑定（Data Binding）与信号处理。
- **你（编辑器/视觉）**：在 Godot 编辑器中搭建 UI 场景（`.tscn`），设置 `Control` 节点的布局（Anchors/Margins）、样式（Themes/Styles）与动画（AnimationPlayer）。
- **对接方式**：我提供 UI 节点结构建议与导出变量需求，你负责视觉实现并绑定脚本。

## Impact
- **Affected specs**:
    - `ui-core-framework` (New)
    - `ui-inventory-visuals` (New)
    - `ui-building-interface` (New)
    - `ui-npc-dialogue-trade` (New)
    - `ui-character-lineage-stats` (New)
    - `ui-crafting-interface` (New)
- **Affected code**: `res://src/ui/` (New directory), `res://scenes/ui/` (User created)
