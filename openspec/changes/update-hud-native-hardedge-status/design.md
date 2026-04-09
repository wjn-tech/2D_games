## Context
- 当前状态区已具备基础功能，但面板分块与数字密度仍偏原型化。
- 项目已确认本轮不使用 HTML 壳，需保持原生 Godot UI 渲染路径。
- 状态数据更新频繁，设计必须兼顾可读性与性能稳定性。

## Goals / Non-Goals
- Goals:
- 将 HP/Mana/Age 合并为统一的硬边科幻状态面板。
- 统一 Age 语义为已消耗年龄值。
- 引入轻量状态反馈动画，提升读数变化感知。
- 在 16:9、16:10、21:9 下保持可读与不遮挡核心视野。
- Non-Goals:
- 不引入 WebView/HTML。
- 不新增技能系统、冷却系统。
- 不改地形与天气的世界渲染表现。

## Decisions
- Decision: 保留现有数据通道（GameState.player_data + EventBus 信号），仅调整展示层。
- Decision: 动画强度固定为低扰动（轻微 scale + 颜色闪烁），避免战斗中视觉噪音。
- Decision: 继续使用 HUDStyles 作为统一样式入口，避免散落式 StyleBox 逻辑。

## Risks / Trade-offs
- 风险: 多分辨率下状态面板尺寸与文本可能出现冲突。
- Mitigation: 提前定义布局断点与最小可读字体，做三种比例基线测试。
- 风险: 反馈动画触发过频导致疲劳感。
- Mitigation: 对动画触发做节流与同帧合并，限制最小触发间隔。

## Migration Plan
1. 先重排状态面板结构与样式。
2. 再接入 Age 语义与文本格式统一。
3. 最后加轻量反馈与响应式适配。

## Open Questions
- 无（已由本轮澄清确认）。
