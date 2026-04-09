## ADDED Requirements

### Requirement: HUD Damage Feedback Must Be Clear and Lightweight
HUD 受击反馈 MUST 在玩家受到伤害时可感知，并 SHALL 保持轻量、短时、可恢复，不遮挡关键状态读数。

#### Scenario: 玩家连续受击
- **WHEN** 玩家在短时间内多次受到伤害
- **THEN** HUD 显示可识别的受击反馈
- **AND** 反馈按节流策略合并，不出现高频噪声闪烁

### Requirement: HUD Hit Confirmation Feedback
HUD 命中反馈 MUST 在玩家攻击命中时触发，并 SHALL 使用轻微缩放或颜色脉冲提示命中确认。

#### Scenario: 玩家攻击命中目标
- **WHEN** 攻击命中事件被确认
- **THEN** HUD 触发轻量命中反馈
- **AND** 命中反馈不会阻塞输入或遮挡核心状态条

### Requirement: Persistent Shortcut Hint Strip
HUD MUST 提供常驻快捷键提示条，并 SHALL 持续显示核心操作按键提示。

#### Scenario: 常规游玩时查看快捷提示
- **WHEN** 玩家处于正常游玩状态
- **THEN** HUD 可持续看到核心快捷按键提示
- **AND** 提示条不依赖悬停或额外开关才能出现

### Requirement: Responsive and Non-Overlapping Feedback Layout
HUD 反馈层与快捷提示条 MUST 在 16:9、16:10、21:9 下保持可读，并 SHALL 避免遮挡主要操作区域与关键 UI。

#### Scenario: 超宽屏下反馈与提示并存
- **WHEN** 分辨率切换为 21:9 且发生受击与命中反馈
- **THEN** 反馈层与常驻提示条同时可见且不互相重叠
- **AND** 状态区、热键区与小地图区域保持可交互
