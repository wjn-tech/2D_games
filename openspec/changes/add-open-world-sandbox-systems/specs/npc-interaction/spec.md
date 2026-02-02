## ADDED Requirements

### Requirement: NPC 敌对/中立与交互
系统 SHALL 支持在大世界中遇到不同类型的 NPC，并能与其交互；NPC 至少包含“敌对”和“中立”两类。

#### Scenario: 与中立 NPC 交互
- **WHEN** 玩家在交互范围内触发与中立 NPC 的交互
- **THEN** 系统进入交互流程（例如对话/交易/任务入口之一）

#### Scenario: 遇到敌对 NPC
- **WHEN** 玩家进入敌对 NPC 的警戒范围
- **THEN** 系统触发敌对行为（例如进入战斗状态或遭受攻击）
