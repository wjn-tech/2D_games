# Capability: ui-core-framework

## ADDED Requirements

### Requirement: 全局 UI 管理与层级控制
UIManager 必须能够管理不同类型的 UI 窗口，并确保正确的显示顺序（HUD 在最底层，弹窗在中间，提示在最顶层）。

#### Scenario: 打开背包窗口
- **Given** 玩家按下 'B' 键或点击 HUD 背包图标。
- **When** UIManager 接收到打开请求。
- **Then** 背包窗口被实例化并添加到 Window 层，同时暂停玩家的非 UI 输入（如移动）。

### Requirement: 统一的交互反馈
所有 UI 按钮和可点击元素必须提供视觉反馈（Hover/Click）。

#### Scenario: 鼠标悬停在物品格子上
- **Given** 鼠标移动到 `ItemSlot` 上。
- **When** 触发 `mouse_entered` 信号。
- **Then** 格子背景高亮，并显示该物品的详细信息 Tooltip。
