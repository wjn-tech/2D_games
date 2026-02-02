# Capability: ecological-predation

## ADDED Requirements

### Requirement: 动物捕食行为模拟
生态系统中的肉食动物应当 (SHALL) 具备捕食草食动物的 AI。

#### Scenario: 狼捕食羊
- **Given** 场景中有一只狼和一只羊。
- **When** 羊进入狼的检测范围。
- **Then** 狼切换到“捕食”状态，开始追逐并尝试攻击羊。
