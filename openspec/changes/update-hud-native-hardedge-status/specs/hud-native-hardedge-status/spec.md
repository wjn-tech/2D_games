## ADDED Requirements

### Requirement: Native Hard-Edge Status Panel
游戏主 HUD 状态区 MUST 保持 Godot 原生 UI 渲染路径，并 SHALL 以统一的硬边科幻面板展示 HP、Mana 与 Age。

#### Scenario: 状态区在游戏内统一展示
- **WHEN** 玩家进入 PLAYING 状态并显示 HUD
- **THEN** 左上角状态区显示一体化面板，包含 HP、Mana、Age 三条状态条
- **AND** 状态区不创建或依赖任何 WebView/HTML 壳

### Requirement: Age Bar Uses Consumed Age Semantics
Age 状态条 MUST 表示已消耗年龄值，并 SHALL 显示 current_age 与 max_life_span 的对应关系。

#### Scenario: 年龄值变化时读数语义正确
- **WHEN** 角色年龄增长并触发状态刷新
- **THEN** Age 条填充方向和文本含义对应“已消耗年龄”
- **AND** 文本展示格式为 current/max，不以剩余寿命替代

### Requirement: Subtle Value Feedback Animation
状态数值变化反馈 MUST 采用轻微缩放与颜色闪烁，并 SHALL 在短时内恢复常态以避免视觉噪音。

#### Scenario: 生命值下降时出现轻量反馈
- **WHEN** 玩家受到伤害导致 HP 数值下降
- **THEN** 对应状态数值产生低幅度缩放与短时颜色闪烁
- **AND** 动画结束后恢复原始样式，不遮挡关键数字

### Requirement: Full Aspect-Ratio Adaptation for Status Zone
状态区布局 MUST 在 16:9、16:10、21:9 下保持可读性，并 SHALL 避免与其他关键 HUD 区域发生遮挡。

#### Scenario: 超宽屏下状态区仍稳定
- **WHEN** 分辨率切换到 21:9
- **THEN** 状态区与小地图、Boss 血条、Hotbar 保持安全间距
- **AND** 关键数值在默认 UI 缩放下可直接读取
