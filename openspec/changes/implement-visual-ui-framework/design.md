# Design: 全可视化交互框架 (Visual UI Framework)

## 1. 架构目标
- **解耦**：UI 逻辑与系统逻辑分离。UI 仅通过 `EventBus` 或直接观察 `Manager` 的数据变化来更新。
- **响应式**：数据变化时，UI 自动刷新（例如：背包物品变动，UI 自动重绘网格）。
- **层级管理**：支持 HUD（常驻）、Window（可关闭窗口）、Modal（模态弹窗）与 Tooltip（悬浮提示）。

## 2. 核心组件
### 2.1 UIManager (Autoload)
- 负责管理所有 UI 窗口的打开/关闭。
- 处理 UI 状态下的输入拦截（例如：打开背包时禁用玩家移动）。
- 提供通用的“弹出/消失”动画接口。

### 2.2 数据绑定模式 (Data Binding)
- UI 脚本通过 `@export` 引用对应的 `Manager` 或 `Resource`。
- 监听 `Manager` 的信号（如 `inventory_changed`）。
- 使用 `update_view()` 方法统一刷新界面。

### 2.3 交互反馈
- **Hover 效果**：所有可交互元素在鼠标悬停时有视觉反馈。
- **Sound Effects**：点击、打开、关闭、合成成功等音效触发点。
- **Drag & Drop**：基于 Godot 内置的 `_get_drag_data` 和 `_can_drop_data` 实现。

## 3. 关键系统 UI 设计
- **背包 (Inventory)**：
    - 使用 `GridContainer` 自动排列。
    - 每个格子是一个独立的 `SlotUI` 场景。
- **建造 (Building)**：
    - 底部快捷栏或弹出式轮盘。
    - 选中后进入“预览模式”（已在 `building_manager.gd` 中实现逻辑，需 UI 触发）。
- **NPC 交互 (NPC Interaction)**：
    - 动态生成的对话选项。
    - 交易界面采用“左右对比”布局（玩家背包 vs NPC 库存）。

## 4. 性能考虑
- 避免在 `_process` 中每帧刷新 UI。
- 仅在数据信号触发或界面打开时刷新。
- 对于大型列表（如 100+ 配方），考虑使用 `ScrollContainer` 的可见性优化。
