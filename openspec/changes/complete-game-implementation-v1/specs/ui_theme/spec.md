# Capability: UI Theme & Visual Polish

## ADDED Requirements

### Requirement: 统一视觉风格 (Unified Visual Style)
所有 UI 控件必须 (MUST) 使用全局 `Theme` 资源，确保颜色、字体和边框一致。

#### Scenario: 打开新窗口
- **Given** 玩家按下快捷键打开背包。
- **When** 窗口实例化。
- **Then** 窗口背景、按钮和文字自动应用 `main_theme.tres` 中的样式。

### Requirement: 窗口过渡动画 (Window Transitions)
UI 窗口在打开和关闭时必须 (MUST) 有平滑的视觉过渡。

#### Scenario: 关闭设置菜单
- **Given** 设置菜单处于打开状态。
- **When** 玩家点击关闭或按下 ESC。
- **Then** 窗口通过 Tween 执行缩小或淡出动画，动画结束后销毁节点。
