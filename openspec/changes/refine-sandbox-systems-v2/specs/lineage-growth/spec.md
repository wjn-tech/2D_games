# Capability: lineage-growth

## ADDED Requirements

### Requirement: 后代成长期限制
新生成的后代必须 (MUST) 经过成长期才能参与转生。

#### Scenario: 尝试转生到幼年子嗣
- **Given** 玩家角色死亡，进入转生界面。
- **When** 玩家尝试选择一个处于“幼年期”的子嗣。
- **Then** 选择被拒绝，系统提示“该子嗣尚未成年，无法承载灵魂”。

### Requirement: NPC 固定性格影响
NPC 的性格应当 (SHALL) 影响其社交行为。

#### Scenario: 向勇敢性格的 NPC 求婚
- **Given** 玩家向一个性格为“勇敢”的 NPC 求婚。
- **When** 玩家的好感度达到阈值。
- **Then** NPC 接受求婚的概率获得额外加成。
