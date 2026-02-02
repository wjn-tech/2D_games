# Capability: formation-types

## ADDED Requirements

### Requirement: 动态与静态阵法区分
系统必须 (MUST) 支持随玩家移动的动态阵法和固定位置的静态阵法。

#### Scenario: 激活动态聚灵阵
- **Given** 玩家激活了“动态聚灵阵”。
- **When** 玩家在地图上移动。
- **Then** 阵法效果区域始终跟随玩家，范围内友军获得回蓝加成。
