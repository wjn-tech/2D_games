## ADDED Requirements

### Requirement: Multi-Channel Zoom Controls Must Coexist
小地图缩放交互 MUST 同时支持点击展开、滚轮缩放与按钮缩放，并 SHALL 共享同一缩放状态与边界规则。

#### Scenario: 三种缩放入口在同一局内切换使用
- **WHEN** 玩家先点击展开小地图，再使用滚轮与按钮调整缩放
- **THEN** 小地图缩放值连续生效且不重置为冲突状态
- **AND** 三种交互不会互相禁用

### Requirement: Player-Defined Custom Pins Only
小地图标记系统 MUST 支持玩家自定义标记点，并 SHALL 限定为玩家手动添加/删除，不自动生成 NPC 或资源标记。

#### Scenario: 玩家手动添加与删除标记
- **WHEN** 玩家在小地图上添加一个自定义标记并随后删除
- **THEN** 标记能在地图上正确显示与移除
- **AND** 系统不会自动出现 NPC、资源或任务标记

### Requirement: Minimap Card Shows Time and Weather Only
小地图下方信息卡 MUST 展示时间与天气，并 SHALL 不混入与本提案无关的信息字段。

#### Scenario: 时间或天气变化时卡片刷新
- **WHEN** Chronometer 时间推进或 WeatherManager 天气切换
- **THEN** 小地图信息卡更新对应时间与天气显示
- **AND** 卡片仅包含这两类信息

### Requirement: Responsive Minimap Layout Across Target Ratios
小地图组件 MUST 在 16:9、16:10、21:9 下保持可读与可操作，并 SHALL 避免遮挡关键 HUD 区域。

#### Scenario: 超宽屏分辨率下小地图交互
- **WHEN** 分辨率为 21:9 且玩家展开小地图进行标记操作
- **THEN** 小地图、按钮和信息卡全部可见且可点击
- **AND** 不遮挡核心状态区与主要操作区
