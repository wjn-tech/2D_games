# Capability: digging-mechanics

## ADDED Requirements

### Requirement: 基于稿力的挖掘校验
玩家必须 (MUST) 拥有足够“稿力”的工具才能挖掘特定强度的方块。

#### Scenario: 尝试挖掘高强度方块
- **Given** 玩家持有一把稿力为 10 的木稿。
- **When** 玩家尝试挖掘一个 `required_power` 为 20 的石块。
- **Then** 挖掘失败，系统提示“稿力不足”，方块不被销毁。

### Requirement: 资源自动再生
被挖掘的方块应当 (SHALL) 在一定时间后自动恢复。

#### Scenario: 矿石再生
- **Given** 玩家挖掘了一个金矿方块。
- **When** 经过了设定的再生时间（如 300 秒）。
- **Then** 金矿方块在原位置重新生成。
