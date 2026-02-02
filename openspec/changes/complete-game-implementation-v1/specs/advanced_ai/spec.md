# Capability: Advanced NPC & Ecology AI

## ADDED Requirements

### Requirement: 捕食者与猎物逻辑 (Predator-Prey Logic)
动物 NPC 必须 (MUST) 能够识别并追逐特定类型的猎物。

#### Scenario: 狼发现羊
- **Given** 一个“狼”实体的检测范围内出现了一个“羊”实体。
- **When** 狼处于“饥饿”或“游荡”状态。
- **Then** 狼切换到“追逐”状态，向羊移动并尝试攻击。

### Requirement: 昼夜/天气行为 (Diurnal & Weather Behavior)
NPC 的行为必须 (MUST) 受时间和天气影响。

#### Scenario: 下雨时 NPC 避雨
- **Given** 当前天气切换为“大雨”。
- **When** NPC 处于室外。
- **Then** NPC 尝试寻找最近的“房屋”或“遮蔽处”节点并移动过去。
