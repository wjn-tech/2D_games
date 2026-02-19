## Design: 主菜单视觉增强 — 技术与架构说明

### Context
本设计面向 `MainMenu` 层级的视觉与交互增强，目标是在不改变菜单行为或场景结构的前提下，通过可配置的 shader 与主题样式实现参考级的视觉效果，同时保证在低端设备上的可降级能力。

### Goals
- 提供可调整、可校验的视觉参数（shader 参数化）。
- 确保按钮与图标是按钮节点的子节点，并在按钮区域内裁剪，避免遮挡问题。
- 使用最小侵入的方式（脚本/资源改动），便于回滚。

### Non-Goals
- 在本次设计中不改变菜单逻辑、输入映射或全局 UI 架构。

### Key Decisions
1. Shader 参数化
   - 在 `DynamicBackground`（或新增 `MenuBackground` 控制节点）上使用 `@export` 变量绑定 shader 参数，便于从 Inspector 调整或从 UI 控制面板动态修改。优先使用简单类型（float/int/bool），避免高复杂度数据结构。

2. 运行时回退策略
   - 检测 shader 是否可用或帧时间超过阈值后自动切换到低质量预设（移除噪声、降低星点密度、只渲染静态渐变）。

3. 按钮视觉层次
   - 按钮将包含（从后到前）: Glow ColorRect（z=-2）, StyleBox (按钮主体), InnerHighlight ColorRect（shader）, Icon TextureRect, Label（文本）. 所有子节点应为按钮的子节点并受 `clip_contents` 管控，避免漂浮。

4. 动画与可访问性
   - 悬停/按下使用 `create_tween()`，并统一 easing 与时长配置（hover 0.18–0.28s，press 0.08–0.12s），同时确保键盘焦点时也能触发可视化焦点样式。

5. 遵守 Godot 4 API
   - 避免已弃用的 API 或常量（例如 `Button.ICON_LEFT`），统一使用 `TextureRect` 子节点与 `custom_minimum_size` 等新属性。

### Alternatives Considered
- 把所有 shader 参数放在全局单例：弊端是降低局部调整的灵活性与可移植性；因此选择把参数绑定到背景节点并提供全局预设接口。
- 使用图集 + ninepatch 替代复杂 StyleBox：但 ninepatch 不适合动态 glow/inner shader 效果；仍保留 StyleBoxFlat 为基础，并在其上叠加 ColorRect/shader 层次。

### Risks
- Shader 在不同 GPU 平台表现不一致 → 提供运行时回退与预设
- 过度更改 UI 资源可能导致本地场景文件差异增多 → 保持更改最小化并集中在指定文件

### Migration / Rollback
- 所有代码改动需在单独分支，且在合并前保持 `openspec` 中变更状态；若验收失败，回滚分支并将 change 标记为 `needs rework`。

### Open Questions
- 是否需要把视觉预设暴露给最终玩家的设置界面？（若需要，应在 tasks 中添加 UI 实现）
- 是否需要追加自动化图像回归（CI 截图比对）？
